import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import '../models/local_student_model.dart';

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

  // ✅ Close database
  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}
