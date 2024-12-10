import 'package:flutter/material.dart';
import 'yahoo_finance_service.dart'; 

class NewsPage extends StatefulWidget {
  @override
  _NewsPageState createState() => _NewsPageState();
}

class _NewsPageState extends State<NewsPage> {
  late Future<List<dynamic>> _newsFuture;
  final YahooFinanceService _yahooFinanceService = YahooFinanceService();

  @override
  void initState() {
    super.initState();
    _newsFuture = _yahooFinanceService.fetchTopNews();
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
                return ListTile(
                  title: Text(article['title'] ?? 'No Title'),
                  subtitle: Text(article['pubDate'] ?? 'Unknown Date'),
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
            Text('URL: $url'),
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
