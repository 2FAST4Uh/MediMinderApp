import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/medicine.dart';
import '../models/history_record.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'mediminder.db');
    return await openDatabase(
      path,
      version: 4, // Upgraded version for history table
      onCreate: (db, version) async {
        await db.execute(
          'CREATE TABLE medicines(id TEXT PRIMARY KEY, name TEXT, dosage TEXT, hour INTEGER, minute INTEGER, isTaken INTEGER, notificationIds TEXT, frequency TEXT, mealInstruction TEXT, stock INTEGER, notes TEXT, duration TEXT, alertType TEXT, isReminderActive INTEGER)',
        );
        await db.execute(
          'CREATE TABLE history(id TEXT PRIMARY KEY, medicineName TEXT, dosage TEXT, takenDateTime TEXT)',
        );
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute("ALTER TABLE medicines ADD COLUMN frequency TEXT DEFAULT 'Once daily'");
          await db.execute("ALTER TABLE medicines ADD COLUMN mealInstruction TEXT DEFAULT 'Before'");
          await db.execute("ALTER TABLE medicines ADD COLUMN stock INTEGER DEFAULT 15");
          await db.execute("ALTER TABLE medicines ADD COLUMN notes TEXT DEFAULT 'Take with water. Avoid alcohol.'");
        }
        if (oldVersion < 3) {
          await db.execute("ALTER TABLE medicines ADD COLUMN duration TEXT DEFAULT 'Ongoing'");
          await db.execute("ALTER TABLE medicines ADD COLUMN alertType TEXT DEFAULT 'Notification'");
          await db.execute("ALTER TABLE medicines ADD COLUMN isReminderActive INTEGER DEFAULT 1");
        }
        if (oldVersion < 4) {
          await db.execute(
            'CREATE TABLE history(id TEXT PRIMARY KEY, medicineName TEXT, dosage TEXT, takenDateTime TEXT)',
          );
        }
      },
    );
  }

  // --- Medicine Methods ---
  Future<void> insertMedicine(Medicine medicine) async {
    final db = await database;
    await db.insert('medicines', medicine.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Medicine>> getMedicines() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('medicines');
    return List.generate(maps.length, (i) => Medicine.fromMap(maps[i]));
  }

  Future<void> updateMedicine(Medicine medicine) async {
    final db = await database;
    await db.update('medicines', medicine.toMap(), where: 'id = ?', whereArgs: [medicine.id]);
  }

  Future<void> deleteMedicine(String id) async {
    final db = await database;
    await db.delete('medicines', where: 'id = ?', whereArgs: [id]);
  }

  // --- History Methods ---
  Future<void> insertHistory(HistoryRecord record) async {
    final db = await database;
    await db.insert('history', record.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<HistoryRecord>> getHistory() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('history', orderBy: 'takenDateTime DESC');
    return List.generate(maps.length, (i) => HistoryRecord.fromMap(maps[i]));
  }

  Future<void> clearHistory() async {
    final db = await database;
    await db.delete('history');
  }
}
