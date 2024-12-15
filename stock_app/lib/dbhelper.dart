// lib/database_helper.dart
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('stocks.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE stocks (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        ticker TEXT NOT NULL,
        quantity REAL NOT NULL,
        purchase_price REAL NOT NULL
      )
    ''');
  }

  Future<List<Map<String, dynamic>>> queryAllStocks() async {
    final db = await instance.database;
    return db.query('stocks');
  }

  Future<int> insert(
      String ticker, double quantity, double purchasePrice) async {
    final db = await instance.database;
    return await db.insert('stocks', {
      'ticker': ticker,
      'quantity': quantity,
      'purchase_price': purchasePrice,
    });
  }
}
