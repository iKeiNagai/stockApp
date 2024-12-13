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
        _savedArticles = snapshot.docs.map((doc) => doc['title'] as String).toSet();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Top Financial News'),
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _newsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('No news found'));
          } else {
            final news = snapshot.data!;
            return ListView.builder(
              itemCount: news.length,
              itemBuilder: (context, index) {
                final article = news[index]['content'];
                final title = article['title'] ?? 'No Title';
                final isSaved = _savedArticles.contains(title);
                return ListTile(
                  title: Text(article['title'] ?? 'No Title'),
                  subtitle: Text(article['pubDate'] ?? 'Unknown Date'),
                  trailing: IconButton(
                    onPressed: (){
                      _toggleSaveArticle(article);
                    }, 
                    icon: Icon(isSaved ? Icons.star : Icons.star_border),
                    color: isSaved ? Colors.yellow : Colors.grey,),
                  onTap: () {
                    _showArticleDetails(context, article);
                  },
                );
              },
            );
          }
        },
      ),
    );
  }

  void _showArticleDetails(BuildContext context, dynamic article) {
    String url = article['clickThroughUrl'] != null ? article['clickThroughUrl']['url'] : 'No URL available';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(article['title'] ?? 'No Title'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Published Date: ${article['pubDate'] ?? 'Unknown Date'}'),
            SizedBox(height: 10),
            SelectableText('URL: $url'),  // Make URL selectable
            SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: url));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('URL copied to clipboard')),
                );
              },
              icon: Icon(Icons.copy),
              label: Text('Copy URL'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }
}
