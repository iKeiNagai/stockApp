import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:yahoo_finance_data_reader/yahoo_finance_data_reader.dart';
import 'firebase_service.dart';

class WatchlistPage extends StatefulWidget {
  @override
  _WatchlistPageState createState() => _WatchlistPageState();
}

class _WatchlistPageState extends State<WatchlistPage> {
  final FirebaseService _firebaseService = FirebaseService();
  static const backgroundColor = Color(0xFF282A36);
  static const surfaceColor = Color(0xFF44475A);
  static const primaryColor = Color(0xFF50FA7B);
  static const accentColor = Color(0xFFFF79C6);
  static const textColor = Colors.white;
  static const secondaryTextColor = Colors.white54;

  void _showAddTickerDialog() {
    final TextEditingController tickerController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: surfaceColor,
        title:
            Text('Add Stock to Watchlist', style: TextStyle(color: textColor)),
        content: TextField(
          controller: tickerController,
          style: TextStyle(color: textColor),
          decoration: InputDecoration(
            labelText: 'Ticker Symbol',
            labelStyle: TextStyle(color: secondaryTextColor),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: primaryColor),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: secondaryTextColor)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
            ),
            onPressed: () {
              if (tickerController.text.isNotEmpty) {
                _firebaseService
                    .addToWatchlist(tickerController.text.toUpperCase());
                Navigator.pop(context);
              }
            },
            child: Text('Add', style: TextStyle(color: backgroundColor)),
          ),
        ],
      ),
    );
  }

  Widget _buildStockListItem(String ticker) {
    return FutureBuilder<YahooFinanceResponse>(
      future: YahooFinanceDailyReader().getDailyDTOs(ticker),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Card(
            color: surfaceColor,
            child: ListTile(
              title: Text(ticker, style: TextStyle(color: textColor)),
              subtitle: Text('Error loading data',
                  style: TextStyle(color: accentColor)),
              trailing: IconButton(
                icon: Icon(Icons.delete, color: accentColor),
                onPressed: () => _firebaseService.removeFromWatchlist(ticker),
              ),
            ),
          );
        }

        if (!snapshot.hasData) {
          return Card(
            color: surfaceColor,
            child: ListTile(
              title: Text(ticker, style: TextStyle(color: textColor)),
              subtitle: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
              ),
            ),
          );
        }

        final currentPrice = snapshot.data!.candlesData.last.close;
        final previousClose = snapshot
            .data!.candlesData[snapshot.data!.candlesData.length - 2].close;
        final percentChange =
            ((currentPrice - previousClose) / previousClose) * 100;

        return Card(
          color: surfaceColor,
          margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: ListTile(
            title: Text(ticker,
                style:
                    TextStyle(color: textColor, fontWeight: FontWeight.bold)),
            subtitle: Text('\$${currentPrice.toStringAsFixed(2)}',
                style: TextStyle(color: secondaryTextColor)),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${percentChange >= 0 ? '+' : ''}${percentChange.toStringAsFixed(2)}%',
                  style: TextStyle(
                    color: percentChange >= 0 ? primaryColor : accentColor,
                  ),
                ),
                SizedBox(width: 8),
                IconButton(
                  icon: Icon(Icons.delete, color: secondaryTextColor),
                  onPressed: () => _firebaseService.removeFromWatchlist(ticker),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Watchlist', style: TextStyle(color: textColor)),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firebaseService.getWatchlistStream(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}',
                  style: TextStyle(color: accentColor)),
            );
          }

          if (!snapshot.hasData) {
            return Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
              ),
            );
          }

          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final ticker = snapshot.data!.docs[index]['ticker'];
              return _buildStockListItem(ticker);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: primaryColor,
        onPressed: _showAddTickerDialog,
        child: Icon(Icons.add, color: backgroundColor),
      ),
    );
  }
}
