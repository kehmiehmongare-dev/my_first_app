import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:campus_flow/models/student_model.dart';
import 'package:campus_flow/models/lecturer_model.dart';
import 'package:campus_flow/models/user_model.dart';
import 'package:campus_flow/models/course_model.dart';

class DatabaseService {
  static Map<String, dynamic> _storage = {};
  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized) return;

    if (!kIsWeb) {
      await _loadFromFile();
    }
    _initialized = true;
  }

  static Future<void> _loadFromFile() async {
    try {
      final dir = Directory.current;
      final appDir = Directory('${dir.path}/campus_flow_data');
      if (!await appDir.exists()) {
        await appDir.create(recursive: true);
      }

      final file = File('${appDir.path}/data.json');
      if (await file.exists()) {
        final content = await file.readAsString();
        if (content.isNotEmpty) {
          _storage = json.decode(content);
        }
      }
    } catch (e) {
      _storage = {};
    }
  }

  static Future<void> _save() async {
    if (kIsWeb) return;

    try {
      final dir = Directory.current;
      final appDir = Directory('${dir.path}/campus_flow_data');
      if (!await appDir.exists()) {
        await appDir.create(recursive: true);
      }
      final file = File('${appDir.path}/data.json');
      await file.writeAsString(json.encode(_storage));
    } catch (e) {
      // Ignore save errors
    }
  }

  // ==================== USER MANAGEMENT ====================

  static Future<User?> getUserByEmail(String email) async {
    final users = _getUsers();
    for (var user in users.values) {
      if (user['email'] == email) {
        return User.fromJson(user);
      }
    }
    return null;
  }

  static Future<User?> getUserById(String id) async {
    final users = _getUsers();
    final data = users[id];
    if (data != null) return User.fromJson(data);
    return null;
  }

  static Map<String, dynamic> _getUsers() {
    return _storage['users'] ?? {};
  }

  // ==================== STUDENT MANAGEMENT ====================

  static Future<bool> registerStudent(Student student) async {
    final students = _getStudents();
    final users = _getUsers();

    bool exists = students.values.any(
      (s) => s['regNumber'] == student.regNumber || s['email'] == student.email,
    );

    if (exists) return false;

    students[student.regNumber] = student.toJson();
    _storage['students'] = students;

    users[student.regNumber] = {
      'id': student.regNumber,
      'email': student.email,
      'password': student.password,
      'fullName': student.fullName,
      'userType': 'student',
      'phone': student.phone,
      'isActive': true,
      'createdAt': DateTime.now().toIso8601String(),
      'lastLogin': DateTime.now().toIso8601String(),
    };
    _storage['users'] = users;

    await _save();
    return true;
  }

  static Future<Student?> getStudentByUserId(String userId) async {
    final students = _getStudents();
    for (var student in students.values) {
      if (student['id'] == userId || student['regNumber'] == userId) {
        return Student.fromJson(student);
      }
    }
    return null;
  }

  static Map<String, dynamic> _getStudents() {
    return _storage['students'] ?? {};
  }

  static Future<List<Student>> getStudentsByCourse(String courseName) async {
    final students = _getStudents();
    final List<Student> list = [];
    for (var student in students.values) {
      if (student['course'] == courseName) {
        list.add(Student.fromJson(student));
      }
    }
    return list;
  }

  // ==================== LECTURER MANAGEMENT ====================

  static Future<bool> registerLecturer(User user, Lecturer lecturer) async {
    final lecturers = _getLecturers();
    final users = _getUsers();

    if (lecturers.containsKey(lecturer.employeeId)) return false;

    lecturers[lecturer.employeeId] = lecturer.toJson();
    _storage['lecturers'] = lecturers;

    users[lecturer.employeeId] = user.toJson();
    _storage['users'] = users;

    await _save();
    return true;
  }

  static Future<Lecturer?> getLecturerByUserId(String userId) async {
    final lecturers = _getLecturers();
    final data = lecturers[userId];
    if (data != null) return Lecturer.fromJson(data);
    return null;
  }

  static Map<String, dynamic> _getLecturers() {
    return _storage['lecturers'] ?? {};
  }

  static Future<List<Course>> getLecturerCourses(String lecturerId) async {
    final courses = _getCourses();
    final List<Course> result = [];
    for (var course in courses.values) {
      if (course['lecturerId'] == lecturerId) {
        result.add(Course.fromJson(course));
      }
    }
    return result;
  }

  // ==================== COURSE MANAGEMENT ====================

  static Future<List<Course>> getStudentCourses(String studentId) async {
    final student = await getStudentByUserId(studentId);
    if (student == null) return [];

    final courses = _getCourses();
    final List<Course> studentCourses = [];
    for (var course in courses.values) {
      if (course['department'] == student.course) {
        studentCourses.add(Course.fromJson(course));
      }
    }
    return studentCourses;
  }

  static Map<String, dynamic> _getCourses() {
    return _storage['courses'] ?? {};
  }

  // ==================== ATTENDANCE MANAGEMENT ====================

  static Future<double> getOverallAttendance(String studentId) async {
    final attendance = _getAttendance();
    int total = 0;
    int present = 0;

    for (var record in attendance.values) {
      if (record['studentId'] == studentId) {
        total++;
        if (record['status'] == 'present') {
          present++;
        }
      }
    }

    if (total == 0) return 0.0;
    return (present / total) * 100;
  }

  static Future<Map<String, dynamic>> getAttendanceStats(
      String studentId) async {
    final attendance = _getAttendance();
    int present = 0;
    int absent = 0;
    int late = 0;

    for (var record in attendance.values) {
      if (record['studentId'] == studentId) {
        switch (record['status']) {
          case 'present':
            present++;
            break;
          case 'absent':
            absent++;
            break;
          case 'late':
            late++;
            break;
        }
      }
    }

    return {
      'present': present,
      'absent': absent,
      'late': late,
      'total': present + absent + late,
    };
  }

  static Future<List<Map<String, dynamic>>> getStudentAttendanceRecords(
      String studentId) async {
    final attendance = _getAttendance();
    final List<Map<String, dynamic>> records = [];

    for (var record in attendance.values) {
      if (record['studentId'] == studentId) {
        records.add(record);
      }
    }

    records.sort((a, b) => b['date'].compareTo(a['date']));
    return records;
  }

  static Future<void> markAttendanceManual({
    required String studentId,
    required String studentName,
    required String courseId,
    required String courseCode,
    required String date,
    required String status,
  }) async {
    final attendance = _getAttendance();
    final id = '${studentId}_${courseId}_$date';

    attendance[id] = {
      'id': id,
      'studentId': studentId,
      'studentName': studentName,
      'courseId': courseId,
      'courseCode': courseCode,
      'date': date,
      'status': status,
      'checkInTime': DateTime.now().toIso8601String(),
    };
    _storage['attendance'] = attendance;
    await _save();
  }

  static Map<String, dynamic> _getAttendance() {
    return _storage['attendance'] ?? {};
  }

  // ==================== FEE MANAGEMENT ====================

  static Future<int> getPendingFees(String studentId) async {
    return 55500;
  }

  // ==================== LOGIN ====================

  static Future<User?> loginUser({
    required String username,
    required String password,
    required UserType userType,
  }) async {
    final users = _getUsers();

    for (var user in users.values) {
      if ((user['email'] == username || user['id'] == username) &&
          user['password'] == password &&
          user['userType'] == userType.name) {
        return User.fromJson(user);
      }
    }
    return null;
  }

  // ==================== SESSION ====================

  static Future<void> saveCredentials(String username, String password) async {
    _storage['savedCredentials'] = {'username': username, 'password': password};
    await _save();
  }

  static Future<Map<String, String>?> getSavedCredentials() async {
    final data = _storage['savedCredentials'];
    if (data != null) {
      return {'username': data['username'], 'password': data['password']};
    }
    return null;
  }

  static Future<void> addSampleData() async {
    final courses = {
      'CS301': {
        'id': 'CS301',
        'code': 'CS301',
        'name': 'Software Engineering',
        'credits': 4,
        'department': 'BSc Computer Science',
        'lecturerId': 'LEC001',
        'lecturerName': 'Dr. James Wilson',
        'schedule': 'Mon/Wed 10:00 AM',
        'room': 'Room 301',
        'year': 3,
      },
    };
    _storage['courses'] = courses;
    await _save();
  }
}
