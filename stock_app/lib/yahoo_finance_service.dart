import 'dart:convert';
import 'package:http/http.dart' as http;

class YahooFinanceService {
  final String apiKey = "d8b2197abcmsh1263b2081d40092p122a5djsn14eb1ec8b064";

  Future<Map<String, dynamic>> getStockData(String ticker) async {
    print('Fetching stock data for $ticker');
    try {
      final url = Uri.parse(
          'https://yh-finance.p.rapidapi.com/stock/v2/get-summary?symbol=${ticker.toUpperCase()}&region=US');

      final response = await http.get(
        url,
        headers: {
          'X-RapidAPI-Key': apiKey,
          'X-RapidAPI-Host': 'yh-finance.p.rapidapi.com',
        },
      );

      print('Stock data response: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final price = data['price'];
        if (price != null) {
          final regularMarketPrice = price['regularMarketPrice']?['raw'] ?? 0.0;
          final regularMarketChange =
              price['regularMarketChange']?['raw'] ?? 0.0;
          final regularMarketChangePercent =
              price['regularMarketChangePercent']?['raw'] ?? 0.0;

          return {
            'current_price': regularMarketPrice,
            'price_change': regularMarketChange,
            'percent_change': regularMarketChangePercent,
            'volume': price['regularMarketVolume']?['raw'] ?? 0,
            'high': price['regularMarketDayHigh']?['raw'] ?? 0.0,
            'low': price['regularMarketDayLow']?['raw'] ?? 0.0,
          };
        }
      }
      throw Exception('Failed to load stock data');
    } catch (e) {
      print('Error fetching stock data for $ticker: $e');
      throw Exception('Failed to load stock data');
    }
  }

  Future<List<Map<String, dynamic>>> getHistoricalData(
      String ticker, DateTime startDate, DateTime endDate) async {
    print('Fetching historical data for $ticker');
    try {
      final url = Uri.parse(
          'https://yh-finance.p.rapidapi.com/stock/v3/get-historical-data?symbol=${ticker.toUpperCase()}&region=US');

      final response = await http.get(
        url,
        headers: {
          'X-RapidAPI-Key': apiKey,
          'X-RapidAPI-Host': 'yh-finance.p.rapidapi.com',
        },
      );

      print('Historical data response: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['prices'] != null) {
          List<Map<String, dynamic>> prices = [];
          for (var item in data['prices']) {
            if (item['date'] != null && item['close'] != null) {
              final date =
                  DateTime.fromMillisecondsSinceEpoch(item['date'] * 1000);
              if (date.isAfter(startDate) && date.isBefore(endDate)) {
                prices.add({
                  'date': date,
                  'close': item['close'].toDouble(),
                  'high': item['high']?.toDouble() ?? 0.0,
                  'low': item['low']?.toDouble() ?? 0.0,
                  'open': item['open']?.toDouble() ?? 0.0,
                  'volume': item['volume'] ?? 0,
                });
              }
            }
          }
          return prices;
        }
      }
      throw Exception('Failed to load historical data');
    } catch (e) {
      print('Error fetching historical data for $ticker: $e');
      throw Exception('Failed to load historical data');
    }
  }

  Future<Map<String, dynamic>> fetchStockPrice(String ticker) async {
    try {
      final stockData = await getStockData(ticker);
      return {
        'currentPrice': stockData['current_price'],
        'priceChange': stockData['price_change'],
        'percentChange': stockData['percent_change'],
      };
    } catch (e) {
      print('Error in fetchStockPrice for $ticker: $e');
      throw Exception('Failed to fetch stock price');
    }
  }

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
