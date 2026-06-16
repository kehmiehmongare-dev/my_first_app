import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart';
import 'dart:io';
import 'dart:convert';

class SQLiteHelper {
  static final SQLiteHelper _instance = SQLiteHelper._internal();
  factory SQLiteHelper() => _instance;
  SQLiteHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, 'campus_flow.db');
    return await openDatabase(
      path,
      version: 2,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
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

    // Records Table
    await db.execute('''
      CREATE TABLE records(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        description TEXT,
        category TEXT NOT NULL,
        date TEXT NOT NULL
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE records(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          title TEXT NOT NULL,
          description TEXT,
          category TEXT NOT NULL,
          date TEXT NOT NULL
        )
      ''');
    }
  }

  // ==================== STUDENT CRUD ====================
  Future<int> insertStudent(Map<String, dynamic> student) async {
    Database db = await database;
    student['createdAt'] = DateTime.now().toIso8601String();
    return await db.insert('students', student);
  }

  Future<List<Map<String, dynamic>>> getAllStudents() async {
    Database db = await database;
    return await db.query('students', orderBy: 'name ASC');
  }

  Future<int> updateStudent(int id, Map<String, dynamic> student) async {
    Database db = await database;
    return await db.update('students', student, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteStudent(int id) async {
    Database db = await database;
    return await db.delete('students', where: 'id = ?', whereArgs: [id]);
  }

  // ==================== RECORDS CRUD ====================
  Future<int> insertRecord(Map<String, dynamic> record) async {
    Database db = await database;
    record['date'] = DateTime.now().toIso8601String();
    return await db.insert('records', record);
  }

  Future<List<Map<String, dynamic>>> getAllRecords() async {
    Database db = await database;
    return await db.query('records', orderBy: 'date DESC');
  }

  Future<List<Map<String, dynamic>>> searchRecords(String query) async {
    Database db = await database;
    return await db.query(
      'records',
      where: 'title LIKE ? OR description LIKE ?',
      whereArgs: ['%$query%', '%$query%'],
      orderBy: 'date DESC',
    );
  }

  Future<int> updateRecord(int id, Map<String, dynamic> record) async {
    Database db = await database;
    return await db.update('records', record, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteRecord(int id) async {
    Database db = await database;
    return await db.delete('records', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteAllRecords() async {
    Database db = await database;
    return await db.delete('records');
  }

  // ==================== SYNC ====================
  Future<String> exportToJson() async {
    final students = await getAllStudents();
    final records = await getAllRecords();
    
    final data = {
      'students': students,
      'records': records,
      'exportedAt': DateTime.now().toIso8601String(),
    };
    
    return json.encode(data);
  }

  Future<void> importFromJson(String jsonData) async {
    final data = json.decode(jsonData);
    final db = await database;
    
    await db.transaction((txn) async {
      // Clear existing data
      await txn.delete('students');
      await txn.delete('records');
      
      // Insert students
      for (var student in data['students']) {
        await txn.insert('students', student);
      }
      
      // Insert records
      for (var record in data['records']) {
        await txn.insert('records', record);
      }
    });
  }
}