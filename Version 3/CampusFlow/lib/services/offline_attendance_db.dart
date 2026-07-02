import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

class OfflineAttendanceDB {
  static final OfflineAttendanceDB _instance = OfflineAttendanceDB._internal();
  factory OfflineAttendanceDB() => _instance;
  OfflineAttendanceDB._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final directory = await getApplicationDocumentsDirectory();
    final path = join(directory.path, 'campusflow_attendance.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE offline_attendance(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        studentId TEXT,
        studentName TEXT,
        regNumber TEXT,
        unitCode TEXT,
        unitName TEXT,
        sessionId TEXT,
        lecturerId TEXT,
        week INTEGER,
        date TEXT,
        timestamp TEXT,
        status TEXT,
        qrData TEXT,
        isSynced INTEGER DEFAULT 0,
        createdAt TEXT
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Handle migrations if needed
  }

  // ✅ Save attendance offline
  Future<int> saveAttendance(Map<String, dynamic> data) async {
    final db = await database;
    return await db.insert('offline_attendance', {
      'studentId': data['studentId'],
      'studentName': data['studentName'] ?? 'Student',
      'regNumber': data['regNumber'] ?? 'STU001',
      'unitCode': data['unitCode'],
      'unitName': data['unitName'] ?? '',
      'sessionId': data['sessionId'] ?? '',
      'lecturerId': data['lecturerId'] ?? '',
      'week': data['week'] ?? 1,
      'date': DateTime.now().toIso8601String(),
      'timestamp': DateTime.now().millisecondsSinceEpoch.toString(),
      'status': 'present',
      'qrData': data['qrData'] ?? '',
      'isSynced': 0,
      'createdAt': DateTime.now().toIso8601String(),
    });
  }

  // ✅ Get unsynced attendance
  Future<List<Map<String, dynamic>>> getUnsyncedAttendance() async {
    final db = await database;
    return await db.query(
      'offline_attendance',
      where: 'isSynced = ?',
      whereArgs: [0],
      orderBy: 'createdAt ASC',
    );
  }

  // ✅ Get count of unsynced records
  Future<int> getUnsyncedCount() async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM offline_attendance WHERE isSynced = 0',
    );
    return result.first['count'] as int? ?? 0;
  }

  // ✅ Get all offline attendance
  Future<List<Map<String, dynamic>>> getAllOfflineAttendance() async {
    final db = await database;
    return await db.query(
      'offline_attendance',
      orderBy: 'createdAt DESC',
    );
  }

  // ✅ Mark as synced
  Future<void> markAsSynced(int id) async {
    final db = await database;
    await db.update(
      'offline_attendance',
      {'isSynced': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ✅ Delete all synced records
  Future<void> deleteSyncedRecords() async {
    final db = await database;
    await db.delete(
      'offline_attendance',
      where: 'isSynced = ?',
      whereArgs: [1],
    );
  }

  // ✅ Clear all records (for testing)
  Future<void> clearAll() async {
    final db = await database;
    await db.delete('offline_attendance');
  }
}
