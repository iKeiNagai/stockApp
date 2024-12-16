import 'dart:convert';
import 'package:http/http.dart' as http;

class YahooFinanceService {
  final String apiKey = "d8b2197abcmsh1263b2081d40092p122a5djsn14eb1ec8b064";

  Future<List<dynamic>> fetchTopNews() async {
    try {
      final url = Uri.parse(
          'https://yahoo-finance166.p.rapidapi.com/api/news/list-by-symbol?s=AAPL%2CGOOGL%2CTSLA&region=US&snippetCount=500');

      final response = await http.get(
        url,
        headers: {
          'X-RapidAPI-Key': apiKey,
          'X-RapidAPI-Host': 'yahoo-finance166.p.rapidapi.com',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['data'] != null && data['data']['main'] != null) {
          return data['data']['main']['stream'];
        }
      }
      throw Exception('Failed to load news');
    } catch (e) {
      print('Error fetching news: $e');
      throw Exception('Failed to load news');
    }
  }
}
