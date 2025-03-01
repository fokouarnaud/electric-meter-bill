import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static const _databaseName = "electric_meter.db";
  static const _databaseVersion = 2;

  // Singleton instance
  DatabaseHelper._();
  static final DatabaseHelper instance = DatabaseHelper._();

  Database? _database;

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }

  Future<Database> _initDatabase() async {
    final path = join(await getDatabasesPath(), _databaseName);
    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Meters table
    await db.execute('''
      CREATE TABLE meters (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        location TEXT NOT NULL,
        client_name TEXT NOT NULL,
        price_per_kwh REAL NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        contact_phone TEXT,
        contact_email TEXT,
        contact_name TEXT
      )
    ''');

    // Meter readings table
    await db.execute('''
      CREATE TABLE meter_readings (
        id TEXT PRIMARY KEY,
        meter_id TEXT NOT NULL,
        value REAL NOT NULL,
        image_url TEXT NOT NULL,
        reading_date TEXT NOT NULL,
        is_verified INTEGER NOT NULL,
        notes TEXT,
        consumption REAL,
        created_at TEXT NOT NULL,
        FOREIGN KEY (meter_id) REFERENCES meters (id) ON DELETE CASCADE
      )
    ''');

    // Bills table
    await db.execute('''
      CREATE TABLE bills (
        id TEXT PRIMARY KEY,
        meter_id TEXT NOT NULL,
        client_name TEXT NOT NULL,
        previous_reading REAL NOT NULL,
        current_reading REAL NOT NULL,
        consumption REAL NOT NULL,
        amount REAL NOT NULL,
        start_date TEXT NOT NULL,
        end_date TEXT NOT NULL,
        generated_date TEXT NOT NULL,
        date TEXT NOT NULL,
        due_date TEXT NOT NULL,
        notes TEXT,
        is_paid INTEGER NOT NULL,
        created_at TEXT NOT NULL,
        FOREIGN KEY (meter_id) REFERENCES meters (id) ON DELETE CASCADE
      )
    ''');

    // Create indexes
    await db.execute(
      'CREATE INDEX idx_meter_readings_meter_id ON meter_readings(meter_id)',
    );
    await db.execute(
      'CREATE INDEX idx_bills_meter_id ON bills(meter_id)',
    );
    await db.execute(
      'CREATE INDEX idx_meter_readings_date ON meter_readings(reading_date)',
    );
    await db.execute(
      'CREATE INDEX idx_bills_date ON bills(date)',
    );
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Add contact fields to meters table
      await db.execute('''
        ALTER TABLE meters ADD COLUMN contact_phone TEXT;
      ''');
      await db.execute('''
        ALTER TABLE meters ADD COLUMN contact_email TEXT;
      ''');
      await db.execute('''
        ALTER TABLE meters ADD COLUMN contact_name TEXT;
      ''');
    }
  }

  // Helper methods for transactions
  Future<T> transaction<T>(Future<T> Function(Transaction txn) action) async {
    final db = await database;
    return await db.transaction(action);
  }

  // Helper method to get the current timestamp
  String get currentTimestamp => DateTime.now().toIso8601String();
}
