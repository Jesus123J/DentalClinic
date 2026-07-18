import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../constants/app_constants.dart';

/// Acceso a la base de datos local SQLite (via FFI para escritorio).
class DatabaseHelper {
  DatabaseHelper._();
  static final DatabaseHelper instance = DatabaseHelper._();

  Database? _db;

  /// Debe llamarse una vez al iniciar la app (antes de runApp).
  static void initFfi() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  Future<Database> get database async {
    _db ??= await _open();
    return _db!;
  }

  Future<Database> _open() async {
    final dbPath = await databaseFactory.getDatabasesPath();
    final path = join(dbPath, AppConstants.dbName);
    return databaseFactory.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: AppConstants.dbVersion,
        onCreate: _onCreate,
      ),
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE patients (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        first_name TEXT NOT NULL,
        last_name TEXT NOT NULL,
        document_id TEXT,
        phone TEXT,
        email TEXT,
        birth_date TEXT,
        allergies TEXT,
        notes TEXT,
        created_at TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE appointments (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        patient_id INTEGER NOT NULL REFERENCES patients(id),
        date_time TEXT NOT NULL,
        duration_minutes INTEGER NOT NULL DEFAULT 30,
        reason TEXT,
        status TEXT NOT NULL DEFAULT 'pendiente',
        created_at TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE treatments (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        patient_id INTEGER NOT NULL REFERENCES patients(id),
        name TEXT NOT NULL,
        tooth TEXT,
        description TEXT,
        cost REAL NOT NULL DEFAULT 0,
        status TEXT NOT NULL DEFAULT 'en_progreso',
        started_at TEXT,
        finished_at TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE invoices (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        patient_id INTEGER NOT NULL REFERENCES patients(id),
        treatment_id INTEGER REFERENCES treatments(id),
        total REAL NOT NULL,
        paid REAL NOT NULL DEFAULT 0,
        status TEXT NOT NULL DEFAULT 'pendiente',
        issued_at TEXT NOT NULL
      )
    ''');
  }
}
