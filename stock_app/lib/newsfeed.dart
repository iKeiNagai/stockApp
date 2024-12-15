import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'yahoo_finance_service.dart';
import 'package:flutter/services.dart';

class NewsPage extends StatefulWidget {
  @override
  _NewsPageState createState() => _NewsPageState();
}

class _NewsPageState extends State<NewsPage> {
  late Future<List<dynamic>> _newsFuture;
  final YahooFinanceService _yahooFinanceService = YahooFinanceService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final User? _user = FirebaseAuth.instance.currentUser;

  // Dracula theme colors
  static const backgroundColor = Color(0xFF282A36);
  static const surfaceColor = Color(0xFF44475A);
  static const primaryColor = Color(0xFF50FA7B);
  static const accentColor = Color(0xFFFF79C6);
  static const textColor = Colors.white;
  static const secondaryTextColor = Colors.white54;

  Set<String> _savedArticles = {};

  @override
  void initState() {
    super.initState();
    _newsFuture = _yahooFinanceService.fetchTopNews();
    _fetchSavedArticles();
  }

  Future<void> _toggleSaveArticle(dynamic article) async {
    final title = article['title'] ?? 'No Title';

    if (_user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please log in to save articles.')),
      );
      return;
    }

    setState(() {
      if (_savedArticles.contains(title)) {
        _savedArticles.remove(title);
      } else {
        _savedArticles.add(title);
      }
    });

    if (_savedArticles.contains(title)) {
      await _firestore
          .collection('users')
          .doc(_user!.uid)
          .collection('savedArticles')
          .add({
        'title': title,
        'url': article['clickThroughUrl'] != null
            ? article['clickThroughUrl']['url']
            : 'No URL',
        'pubDate': article['pubDate'] ?? 'Unknown Date',
        'timestamp': FieldValue.serverTimestamp(),
      });
    } else {
      final snapshot = await _firestore
          .collection('users')
          .doc(_user!.uid)
          .collection('savedArticles')
          .where('title', isEqualTo: title)
          .get();

      for (var doc in snapshot.docs) {
        await doc.reference.delete();
      }
    }
  }

  Future<void> _fetchSavedArticles() async {
    if (_user != null) {
      final snapshot = await _firestore
          .collection('users')
          .doc(_user!.uid)
          .collection('savedArticles')
          .get();

      setState(() {
        _savedArticles =
            snapshot.docs.map((doc) => doc['title'] as String).toSet();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: surfaceColor,
        title: Text('Top Financial News', style: TextStyle(color: textColor)),
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _newsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
                child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
            ));
          } else if (snapshot.hasError) {
            return Center(
                child: Text('Error: ${snapshot.error}',
                    style: TextStyle(color: accentColor)));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
                child:
                    Text('No news found', style: TextStyle(color: textColor)));
          } else {
            final news = snapshot.data!;
            return ListView.builder(
              itemCount: news.length,
              itemBuilder: (context, index) {
                final article = news[index]['content'];
                final title = article['title'] ?? 'No Title';
                final isSaved = _savedArticles.contains(title);
                return Card(
                  color: surfaceColor,
                  margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                  child: ListTile(
                    title: Text(article['title'] ?? 'No Title',
                        style: TextStyle(color: textColor)),
                    subtitle: Text(article['pubDate'] ?? 'Unknown Date',
                        style: TextStyle(color: secondaryTextColor)),
                    trailing: IconButton(
                      onPressed: () {
                        _toggleSaveArticle(article);
                      },
                      icon: Icon(
                        isSaved ? Icons.star : Icons.star_border,
                        color: isSaved ? primaryColor : secondaryTextColor,
                      ),
                    ),
                    onTap: () {
                      _showArticleDetails(context, article);
                    },
                  ),
                );
              },
            );
          }
        },
      ),
    );
  }

  void _showArticleDetails(BuildContext context, dynamic article) {
    String url = article['clickThroughUrl'] != null
        ? article['clickThroughUrl']['url']
        : 'No URL available';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: surfaceColor,
        title: Text(article['title'] ?? 'No Title',
            style: TextStyle(color: textColor)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Published Date: ${article['pubDate'] ?? 'Unknown Date'}',
                style: TextStyle(color: textColor)),
            SizedBox(height: 10),
            SelectableText('URL: $url', style: TextStyle(color: textColor)),
            SizedBox(height: 10),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
              ),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: url));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('URL copied to clipboard'),
                    backgroundColor: surfaceColor,
                  ),
                );
              },
              icon: Icon(Icons.copy, color: backgroundColor),
              label: Text('Copy URL', style: TextStyle(color: backgroundColor)),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close', style: TextStyle(color: primaryColor)),
          ),
        ],
      ),
    );
  }
}
