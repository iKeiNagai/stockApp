import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:yahoo_finance_data_reader/yahoo_finance_data_reader.dart';
import 'firebase_service.dart';
import 'portfolio_graph.dart';
import 'watchlist.dart';
import 'newsfeed.dart';
import 'profile.dart';
import 'package:intl/intl.dart';

class Home extends StatefulWidget {
  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final FirebaseService _firebaseService = FirebaseService();
  static const backgroundColor = Color(0xFF282A36);
  static const surfaceColor = Color(0xFF44475A);
  static const primaryColor = Color(0xFF50FA7B);
  static const accentColor = Color(0xFFFF79C6);
  static const textColor = Colors.white;
  static const secondaryTextColor = Colors.white54;

  Widget _buildPositionCard(DocumentSnapshot position) {
    return FutureBuilder<YahooFinanceResponse>(
      future: YahooFinanceDailyReader().getDailyDTOs(position['ticker']),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Card(
            color: surfaceColor,
            child: ListTile(
              title:
                  Text(position['ticker'], style: TextStyle(color: textColor)),
              subtitle: Text('Error loading data',
                  style: TextStyle(color: accentColor)),
            ),
          );
        }

        if (!snapshot.hasData) {
          return Card(
            color: surfaceColor,
            child: ListTile(
              title:
                  Text(position['ticker'], style: TextStyle(color: textColor)),
              subtitle: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
              ),
            ),
          );
        }

        final currentPrice = snapshot.data!.candlesData.last.close;
        final purchasePrice = position['purchasePrice'];
        final quantity = position['quantity'];
        final profitLoss = (currentPrice - purchasePrice) * quantity;
        final percentChange =
            ((currentPrice - purchasePrice) / purchasePrice) * 100;

        return Card(
          color: surfaceColor,
          margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      position['ticker'],
                      style: TextStyle(
                        color: textColor,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${quantity.toStringAsFixed(2)} shares',
                      style: TextStyle(color: secondaryTextColor),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Current: \$${currentPrice.toStringAsFixed(2)}',
                          style: TextStyle(color: textColor),
                        ),
                        Text(
                          'Bought: \$${purchasePrice.toStringAsFixed(2)}',
                          style: TextStyle(color: secondaryTextColor),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '\$${profitLoss.toStringAsFixed(2)}',
                          style: TextStyle(
                            color: profitLoss >= 0 ? primaryColor : accentColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${percentChange >= 0 ? '+' : ''}${percentChange.toStringAsFixed(2)}%',
                          style: TextStyle(
                            color:
                                percentChange >= 0 ? primaryColor : accentColor,
                          ),
                        ),
                      ],
                    ),
                  ],
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
        backgroundColor: surfaceColor,
        title: Text('Portfolio', style: TextStyle(color: textColor)),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: Padding(
        padding: EdgeInsets.only(bottom: 67),
        child: FloatingActionButton(
          backgroundColor: primaryColor,
          onPressed: () => _showAddPositionDialog(),
          child: Icon(Icons.add, color: backgroundColor),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firebaseService.getPortfolioStream(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData) {
            return Center(
                child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
            ));
          }

          // Calculate total portfolio value
          return FutureBuilder<double>(
            future: _calculateTotalPortfolioValue(snapshot.data!.docs),
            builder: (context, totalValueSnapshot) {
              return Column(
                children: [
                  // Portfolio Value Card
                  Container(
                    width: double.infinity,
                    margin: EdgeInsets.all(16),
                    padding: EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: surfaceColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Portfolio Value',
                          style: TextStyle(
                            color: secondaryTextColor,
                            fontSize: 16,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          '\$${totalValueSnapshot.data?.toStringAsFixed(2) ?? '0.00'}',
                          style: TextStyle(
                            color: textColor,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Positions List
                  Expanded(
                    child: ListView.builder(
                      padding: EdgeInsets.all(8),
                      itemCount: snapshot.data!.docs.length,
                      itemBuilder: (context, index) {
                        return _buildPositionCard(snapshot.data!.docs[index]);
                      },
                    ),
                  ),

                  // Navigation Buttons
                  Container(
                    padding: EdgeInsets.all(16),
                    color: surfaceColor,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildNavButton(
                          icon: Icons.list,
                          label: 'Watchlist',
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => WatchlistPage()),
                          ),
                        ),
                        _buildNavButton(
                          icon: Icons.newspaper,
                          label: 'News',
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => NewsPage()),
                          ),
                        ),
                        _buildNavButton(
                          icon: Icons.person,
                          label: 'Profile',
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => ProfileScreen()),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildNavButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: primaryColor),
          SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(color: textColor),
          ),
        ],
      ),
    );
  }

  Future<double> _calculateTotalPortfolioValue(
      List<DocumentSnapshot> positions) async {
    double totalValue = 0;
    for (var position in positions) {
      try {
        final data = position.data() as Map<String, dynamic>;
        final response =
            await YahooFinanceDailyReader().getDailyDTOs(data['ticker']);
        final currentPrice = response.candlesData.last.close;
        final quantity = data['quantity'];
        totalValue += currentPrice * quantity;
      } catch (e) {
        print('Error calculating value for position: $e');
      }
    }
    return totalValue;
  }

  void _showAddPositionDialog() {
    final TextEditingController tickerController = TextEditingController();
    final TextEditingController quantityController = TextEditingController();
    final TextEditingController priceController = TextEditingController();
    DateTime selectedDate = DateTime.now();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: surfaceColor,
        title: Text('Add Position', style: TextStyle(color: textColor)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: tickerController,
              decoration: InputDecoration(
                labelText: 'Ticker',
                labelStyle: TextStyle(color: secondaryTextColor),
              ),
              style: TextStyle(color: textColor),
            ),
            TextField(
              controller: quantityController,
              decoration: InputDecoration(
                labelText: 'Quantity',
                labelStyle: TextStyle(color: secondaryTextColor),
              ),
              keyboardType: TextInputType.number,
              style: TextStyle(color: textColor),
            ),
            TextField(
              controller: priceController,
              decoration: InputDecoration(
                labelText: 'Purchase Price',
                labelStyle: TextStyle(color: secondaryTextColor),
              ),
              keyboardType: TextInputType.number,
              style: TextStyle(color: textColor),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: secondaryTextColor)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
            onPressed: () {
              _firebaseService.addPortfolioPosition(
                tickerController.text.toUpperCase(),
                double.parse(quantityController.text),
                double.parse(priceController.text),
                selectedDate,
              );
              Navigator.pop(context);
            },
            child: Text('Add', style: TextStyle(color: backgroundColor)),
          ),
        ],
      ),
    );
  }
}
