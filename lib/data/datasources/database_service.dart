import 'dart:io';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  static Database? _database;

  factory DatabaseService() => _instance;

  DatabaseService._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    // Database factory is initialized in main.dart for Desktop

    final Directory appDocDir = await getApplicationDocumentsDirectory();
    final String dbPath = join(appDocDir.path, 'audit2fund.db');

    // Ensure the directory exists
    await Directory(dirname(dbPath)).create(recursive: true);

    return await openDatabase(dbPath, version: 1, onCreate: _onCreate);
  }

  Future<void> _onCreate(Database db, int version) async {
    // Loan Files Table
    await db.execute('''
      CREATE TABLE loan_files (
        id TEXT PRIMARY KEY,
        clientName TEXT NOT NULL,
        fileId TEXT,
        approvedAmount REAL NOT NULL,
        requestedAmount REAL,
        notes TEXT,
        createdDate TEXT NOT NULL,
        updatedDate TEXT NOT NULL,
        status INTEGER NOT NULL,
        followUpConfig TEXT NOT NULL
      )
    ''');

    // Audit Events Table
    await db.execute('''
      CREATE TABLE audit_events (
        id TEXT PRIMARY KEY,
        loanId TEXT NOT NULL,
        timestamp TEXT NOT NULL,
        oldStatus INTEGER NOT NULL,
        newStatus INTEGER NOT NULL,
        action TEXT NOT NULL,
        description TEXT NOT NULL,
        FOREIGN KEY (loanId) REFERENCES loan_files (id) ON DELETE CASCADE
      )
    ''');

    // Settings Table (Key-Value)
    await db.execute('''
      CREATE TABLE settings (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');
  }

  // Helper to close db (rarely needed for app, but good practice)
  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }
}
