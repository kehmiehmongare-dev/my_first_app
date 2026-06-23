import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;

class SQLiteHelper {
  static final SQLiteHelper _instance = SQLiteHelper._internal();
  factory SQLiteHelper() => _instance;
  SQLiteHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (kIsWeb) {
      throw Exception('SQLite is not supported on web. Use Firebase instead.');
    }
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, 'campus_flow.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Students Table
    await db.execute('''
      CREATE TABLE students(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        regNumber TEXT UNIQUE NOT NULL,
        name TEXT NOT NULL,
        email TEXT NOT NULL,
        phone TEXT NOT NULL,
        course TEXT NOT NULL,
        semester INTEGER NOT NULL,
        createdAt TEXT NOT NULL
      )
    ''');

    // Attendance Table
    await db.execute('''
      CREATE TABLE attendance(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        studentId INTEGER NOT NULL,
        studentName TEXT NOT NULL,
        courseId TEXT NOT NULL,
        courseCode TEXT NOT NULL,
        date TEXT NOT NULL,
        status TEXT NOT NULL,
        checkInTime TEXT,
        FOREIGN KEY(studentId) REFERENCES students(id) ON DELETE CASCADE
      )
    ''');
  }

  // ==================== STUDENT METHODS ====================

  Future<int> insertStudent(Map<String, dynamic> student) async {
    Database db = await database;
    student['createdAt'] = DateTime.now().toIso8601String();
    return await db.insert('students', student);
  }

  Future<List<Map<String, dynamic>>> getAllStudents() async {
    Database db = await database;
    return await db.query('students', orderBy: 'name ASC');
  }

  // ==================== ATTENDANCE METHODS ====================

  // ✅ ADD THIS METHOD
  Future<List<Map<String, dynamic>>> getStudentAttendance(
      String studentId) async {
    Database db = await database;
    return await db.query(
      'attendance',
      where: 'studentId = ?',
      whereArgs: [studentId],
      orderBy: 'date DESC',
    );
  }

  // ✅ ADD THIS METHOD
  Future<void> markAttendanceManual({
    required String studentId,
    required String studentName,
    required String courseId,
    required String courseCode,
    required String date,
    required String status,
  }) async {
    Database db = await database;
    await db.insert('attendance', {
      'studentId': studentId,
      'studentName': studentName,
      'courseId': courseId,
      'courseCode': courseCode,
      'date': date,
      'status': status,
      'checkInTime': DateTime.now().toIso8601String(),
    });
  }
}
