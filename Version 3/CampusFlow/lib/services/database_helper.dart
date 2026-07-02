import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import '../models/local_student_model.dart';
import 'package:flutter/foundation.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  // ✅ Get database instance
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  // ✅ Initialize database
  Future<Database> _initDatabase() async {
    final directory = await getApplicationDocumentsDirectory();
    final path = join(directory.path, 'campusflow.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  // ✅ Create tables
  Future<void> _onCreate(Database db, int version) async {
    // Students table
    await db.execute('''
      CREATE TABLE students(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        uid TEXT UNIQUE,
        displayName TEXT,
        regNumber TEXT,
        email TEXT,
        course TEXT,
        department TEXT,
        totalFees REAL,
        paidFees REAL,
        pendingFees REAL,
        temporaryPassword TEXT,
        isSynced INTEGER,
        createdAt TEXT,
        updatedAt TEXT
      )
    ''');

    // Attendance table
    await db.execute('''
      CREATE TABLE attendance(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        studentId TEXT,
        studentName TEXT,
        courseCode TEXT,
        date TEXT,
        status TEXT,
        isSynced INTEGER,
        createdAt TEXT
      )
    ''');

    // Courses table
    await db.execute('''
      CREATE TABLE courses(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        code TEXT UNIQUE,
        name TEXT,
        credits INTEGER,
        isSynced INTEGER,
        createdAt TEXT
      )
    ''');
  }

  // ✅ Handle database upgrade
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Handle migrations if needed
  }

  // ==================== STUDENT CRUD OPERATIONS ====================

  // ✅ Insert student
  Future<int> insertStudent(LocalStudentModel student) async {
    final db = await database;
    return await db.insert(
      'students',
      student.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // ✅ Insert multiple students (batch)
  Future<void> insertStudents(List<LocalStudentModel> students) async {
    final db = await database;
    final batch = db.batch();
    for (var student in students) {
      batch.insert(
        'students',
        student.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit();
  }

  // ✅ Get all students
  Future<List<LocalStudentModel>> getAllStudents() async {
    final db = await database;
    final result = await db.query('students', orderBy: 'displayName');
    return result.map((map) => LocalStudentModel.fromMap(map)).toList();
  }

  // ✅ Get student by UID
  Future<LocalStudentModel?> getStudentByUid(String uid) async {
    final db = await database;
    final result = await db.query(
      'students',
      where: 'uid = ?',
      whereArgs: [uid],
    );
    if (result.isEmpty) return null;
    return LocalStudentModel.fromMap(result.first);
  }

  // ✅ Get student by registration number
  Future<LocalStudentModel?> getStudentByRegNumber(String regNumber) async {
    final db = await database;
    final result = await db.query(
      'students',
      where: 'regNumber = ?',
      whereArgs: [regNumber],
    );
    if (result.isEmpty) return null;
    return LocalStudentModel.fromMap(result.first);
  }

  // ✅ Search students
  Future<List<LocalStudentModel>> searchStudents(String query) async {
    final db = await database;
    final result = await db.query(
      'students',
      where:
          'displayName LIKE ? OR regNumber LIKE ? OR email LIKE ? OR course LIKE ?',
      whereArgs: ['%$query%', '%$query%', '%$query%', '%$query%'],
      orderBy: 'displayName',
    );
    return result.map((map) => LocalStudentModel.fromMap(map)).toList();
  }

  // ✅ Update student
  Future<int> updateStudent(LocalStudentModel student) async {
    final db = await database;
    return await db.update(
      'students',
      student.toMap(),
      where: 'uid = ?',
      whereArgs: [student.uid],
    );
  }

  // ✅ Delete student
  Future<int> deleteStudent(String uid) async {
    final db = await database;
    return await db.delete(
      'students',
      where: 'uid = ?',
      whereArgs: [uid],
    );
  }

  // ✅ Delete all students
  Future<void> deleteAllStudents() async {
    final db = await database;
    await db.delete('students');
  }

  // ✅ Get unsynced students
  Future<List<LocalStudentModel>> getUnsyncedStudents() async {
    final db = await database;
    final result = await db.query(
      'students',
      where: 'isSynced = ?',
      whereArgs: [0],
    );
    return result.map((map) => LocalStudentModel.fromMap(map)).toList();
  }

  // ✅ Mark student as synced
  Future<void> markAsSynced(String uid) async {
    final db = await database;
    await db.update(
      'students',
      {'isSynced': 1},
      where: 'uid = ?',
      whereArgs: [uid],
    );
  }

  // ==================== ATTENDANCE CRUD ====================

  // ✅ Insert attendance
  Future<int> insertAttendance(Map<String, dynamic> attendance) async {
    final db = await database;
    return await db.insert('attendance', attendance);
  }

  // ✅ Get all attendance
  Future<List<Map<String, dynamic>>> getAllAttendance() async {
    final db = await database;
    return await db.query('attendance', orderBy: 'date DESC');
  }

  // ✅ Get attendance by student
  Future<List<Map<String, dynamic>>> getAttendanceByStudent(
      String studentId) async {
    final db = await database;
    return await db.query(
      'attendance',
      where: 'studentId = ?',
      whereArgs: [studentId],
      orderBy: 'date DESC',
    );
  }

  // ✅ Get attendance by date
  Future<List<Map<String, dynamic>>> getAttendanceByDate(String date) async {
    final db = await database;
    return await db.query(
      'attendance',
      where: 'date = ?',
      whereArgs: [date],
    );
  }

  // ==================== COURSE CRUD ====================

  // ✅ Insert course
  Future<int> insertCourse(Map<String, dynamic> course) async {
    final db = await database;
    return await db.insert('courses', course);
  }

  // ✅ Get all courses
  Future<List<Map<String, dynamic>>> getAllCourses() async {
    final db = await database;
    return await db.query('courses', orderBy: 'name');
  }

  // ✅ Get course by code
  Future<Map<String, dynamic>?> getCourseByCode(String code) async {
    final db = await database;
    final result = await db.query(
      'courses',
      where: 'code = ?',
      whereArgs: [code],
    );
    if (result.isEmpty) return null;
    return result.first;
  }

  // ==================== UTILITY METHODS ====================

  // ✅ Get database stats
  Future<Map<String, int>> getStats() async {
    final db = await database;
    final studentCount = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM students'));
    final attendanceCount = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM attendance'));
    final courseCount = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM courses'));

    return {
      'students': studentCount ?? 0,
      'attendance': attendanceCount ?? 0,
      'courses': courseCount ?? 0,
    };
  }

  // Add after your existing utility methods, before the close() method

  // ==================== AUTHENTICATION METHODS ====================

  // ✅ Login user
  Future<Map<String, dynamic>?> loginUser({
    required String username,
    required String password,
    required String userType,
  }) async {
    try {
      final db = await database;

      if (userType == 'student') {
        // Try to find student by regNumber or email
        final result = await db.query(
          'students',
          where: '(regNumber = ? OR email = ?) AND temporaryPassword = ?',
          whereArgs: [username, username, password],
        );
        if (result.isNotEmpty) {
          return {
            'id': result.first['uid'],
            'username': result.first['regNumber'],
            'userType': 'student',
            'displayName': result.first['displayName'],
            'email': result.first['email'],
          };
        }
      } else if (userType == 'lecturer') {
        // For lecturers - check if any student matches (or create lecturers table)
        final result = await db.query(
          'students',
          where: '(regNumber = ? OR email = ?) AND temporaryPassword = ?',
          whereArgs: [username, username, password],
        );
        if (result.isNotEmpty) {
          return {
            'id': result.first['uid'],
            'username': result.first['regNumber'],
            'userType': 'lecturer',
            'displayName': result.first['displayName'],
            'email': result.first['email'],
            'department': result.first['department'] ?? 'Computer Science',
          };
        }
      }
      return null;
    } catch (e) {
      debugPrint('Login error: $e');
      return null;
    }
  }

  // ✅ Get student by user ID (returns Map for compatibility)
  Future<Map<String, dynamic>?> getStudentByUserId(String userId) async {
    try {
      final db = await database;
      final result = await db.query(
        'students',
        where: 'uid = ?',
        whereArgs: [userId],
      );
      if (result.isNotEmpty) {
        return result.first;
      }
      return null;
    } catch (e) {
      debugPrint('Error getting student: $e');
      return null;
    }
  }

  // ✅ Get lecturer by user ID (returns Map for compatibility)
  Future<Map<String, dynamic>?> getLecturerByUserId(String userId) async {
    try {
      final db = await database;
      final result = await db.query(
        'students',
        where: 'uid = ?',
        whereArgs: [userId],
      );
      if (result.isNotEmpty) {
        return {
          'id': result.first['uid'],
          'displayName': result.first['displayName'],
          'email': result.first['email'],
          'department': result.first['department'] ?? 'Computer Science',
          'courses': ['BSc Computer Science', 'BSc Information Technology'],
        };
      }
      return null;
    } catch (e) {
      debugPrint('Error getting lecturer: $e');
      return null;
    }
  }

  // ✅ Get students by course (for lecturer students screen)
  Future<List<LocalStudentModel>> getStudentsByCourse(String course) async {
    try {
      final db = await database;
      final result = await db.query(
        'students',
        where: 'course = ?',
        whereArgs: [course],
        orderBy: 'displayName',
      );
      return result.map((map) => LocalStudentModel.fromMap(map)).toList();
    } catch (e) {
      debugPrint('Error getting students by course: $e');
      return [];
    }
  }

  // ✅ Get distinct courses
  Future<List<String>> getDistinctCourses() async {
    try {
      final db = await database;
      final result = await db.rawQuery(
          'SELECT DISTINCT course FROM students WHERE course IS NOT NULL AND course != ""');
      return result.map((map) => map['course'].toString()).toList();
    } catch (e) {
      debugPrint('Error getting distinct courses: $e');
      return [];
    }
  }

  // ✅ Save credentials (using shared_preferences - you need to add the package)
  Future<void> saveCredentials(String username, String password) async {
    // You'll need to add shared_preferences package
    // For now, we'll skip this
    debugPrint('Saving credentials for $username');
    // When you add shared_preferences:
    // final prefs = await SharedPreferences.getInstance();
    // await prefs.setString('saved_username', username);
    // await prefs.setString('saved_password', password);
  }

  // ✅ Get saved credentials
  Future<Map<String, String>?> getSavedCredentials() async {
    // You'll need to add shared_preferences package
    // For now, return null
    return null;
    // When you add shared_preferences:
    // final prefs = await SharedPreferences.getInstance();
    // final username = prefs.getString('saved_username');
    // final password = prefs.getString('saved_password');
    // if (username != null && password != null) {
    //   return {'username': username, 'password': password};
    // }
    // return null;
  }

  // ✅ Close database
  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}
