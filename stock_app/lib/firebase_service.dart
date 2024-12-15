import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:yahoo_finance_data_reader/yahoo_finance_data_reader.dart';

class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final YahooFinanceDailyReader _yahooReader = YahooFinanceDailyReader();

  // Portfolio Methods
  Future<void> addPortfolioPosition(
    String ticker,
    double quantity,
    double purchasePrice,
    DateTime purchaseDate,
  ) async {
    final user = _auth.currentUser;
    if (user != null) {
      try {
        // Get current stock data
        YahooFinanceResponse response = await _yahooReader.getDailyDTOs(ticker);
        final currentPrice = response.candlesData.last.close;

        await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('portfolio')
            .doc(ticker)
            .set({
          'ticker': ticker,
          'quantity': quantity,
          'purchasePrice': purchasePrice,
          'purchaseDate': purchaseDate,
          'currentPrice': currentPrice,
          'totalValue': quantity * currentPrice,
          'profitLoss': (currentPrice - purchasePrice) * quantity,
          'lastUpdated': FieldValue.serverTimestamp(),
        });
      } catch (e) {
        print('Error adding position: $e');
        throw Exception('Failed to add position');
      }
    } else {
      throw Exception('User not authenticated');
    }
  }

  Future<void> updatePortfolioPosition(
    String ticker,
    double quantity,
    double purchasePrice,
  ) async {
    final user = _auth.currentUser;
    if (user != null) {
      try {
        // Get current stock data
        YahooFinanceResponse response = await _yahooReader.getDailyDTOs(ticker);
        final currentPrice = response.candlesData.last.close;

        await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('portfolio')
            .doc(ticker)
            .update({
          'quantity': quantity,
          'purchasePrice': purchasePrice,
          'currentPrice': currentPrice,
          'totalValue': quantity * currentPrice,
          'profitLoss': (currentPrice - purchasePrice) * quantity,
          'lastUpdated': FieldValue.serverTimestamp(),
        });
      } catch (e) {
        print('Error updating position: $e');
        throw Exception('Failed to update position');
      }
    } else {
      throw Exception('User not authenticated');
    }
  }

  Future<void> updateAllPositions() async {
    final user = _auth.currentUser;
    if (user != null) {
      try {
        final positions = await getPortfolioPositions();
        for (var position in positions) {
          final data = position.data() as Map<String, dynamic>;
          final ticker = data['ticker'];
          final quantity = data['quantity'];
          final purchasePrice = data['purchasePrice'];

          final stockData = await _yahooReader.getDailyDTOs(ticker);
          final currentPrice = stockData.candlesData.last.close;

          await position.reference.update({
            'currentPrice': currentPrice,
            'totalValue': quantity * currentPrice,
            'profitLoss': (currentPrice - purchasePrice) * quantity,
            'lastUpdated': FieldValue.serverTimestamp(),
          });
        }
      } catch (e) {
        print('Error updating positions: $e');
        throw Exception('Failed to update positions');
      }
    } else {
      throw Exception('User not authenticated');
    }
  }

  Future<void> removePortfolioPosition(String ticker) async {
    final user = _auth.currentUser;
    if (user != null) {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('portfolio')
          .doc(ticker)
          .delete();
    } else {
      throw Exception('User not authenticated');
    }
  }

  Stream<QuerySnapshot> getPortfolioStream() {
    final user = _auth.currentUser;
    if (user != null) {
      return _firestore
          .collection('users')
          .doc(user.uid)
          .collection('portfolio')
          .snapshots();
    }
    throw Exception('User not authenticated');
  }

  Future<List<DocumentSnapshot>> getPortfolioPositions() async {
    final user = _auth.currentUser;
    if (user != null) {
      final snapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('portfolio')
          .get();
      return snapshot.docs;
    }
    throw Exception('User not authenticated');
  }

  // Method to get total portfolio value
  Future<double> getTotalPortfolioValue() async {
    final positions = await getPortfolioPositions();
    double total = 0;
    for (var position in positions) {
      final data = position.data() as Map<String, dynamic>;
      total += data['totalValue'] ?? 0;
    }
    return total;
  }

  // Watchlist Methods
  Future<void> addToWatchlist(String ticker) async {
    final user = _auth.currentUser;
    if (user != null) {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('watchlist')
          .doc(ticker)
          .set({
        'ticker': ticker,
        'addedAt': FieldValue.serverTimestamp(),
      });
    } else {
      throw Exception('User not authenticated');
    }
  }

  Future<void> removeFromWatchlist(String ticker) async {
    final user = _auth.currentUser;
    if (user != null) {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('watchlist')
          .doc(ticker)
          .delete();
    } else {
      throw Exception('User not authenticated');
    }
  }

  Stream<QuerySnapshot> getWatchlistStream() {
    final user = _auth.currentUser;
    if (user != null) {
      return _firestore
          .collection('users')
          .doc(user.uid)
          .collection('watchlist')
          .snapshots();
    }
    throw Exception('User not authenticated');
  }

  // User Profile Methods
  Future<void> updateUserProfile(Map<String, dynamic> data) async {
    final user = _auth.currentUser;
    if (user != null) {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .set(data, SetOptions(merge: true));
    } else {
      throw Exception('User not authenticated');
    }
  }
}
