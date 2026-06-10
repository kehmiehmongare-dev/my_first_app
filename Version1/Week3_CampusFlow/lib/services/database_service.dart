import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:campus_flow/models/student_model.dart';
import 'package:campus_flow/models/user_model.dart';

class DatabaseService {
  static Map<String, dynamic> _storage = {};
  static bool _initialized = false;

  // Add this method to DatabaseService class
  static Future<void> logAttendanceAttempt({
    required String regNumber,
    required DateTime timestamp,
    required String location,
  }) async {
    final logs = _getAttendanceLogs();
    final id = '${regNumber}_${timestamp.millisecondsSinceEpoch}';
    logs[id] = {
      'regNumber': regNumber,
      'timestamp': timestamp.toIso8601String(),
      'location': location,
    };
    _storage['attendance_logs'] = logs;
    await _save();
  }

  static Map<String, dynamic> _getAttendanceLogs() {
    return _storage['attendance_logs'] ?? {};
  }

  static Future<bool> registerLecturer(User lecturer) async {
    final lecturers = _getLecturers();
    if (lecturers.containsKey(lecturer.id)) return false;

    lecturers[lecturer.id] = lecturer.toJson();
    _storage['lecturers'] = lecturers;
    await _save();
    return true;
  }

// Login User (works for both student and lecturer)
  static Future<User?> loginUser(
      String email, String password, UserType type) async {
    if (type == UserType.student) {
      final students = _getStudents();
      for (var student in students.values) {
        if (student['email'] == email && student['password'] == password) {
          return User(
            id: student['regNumber'],
            name: student['name'],
            email: student['email'],
            password: student['password'],
            type: UserType.student,
            course: student['course'],
            createdAt: DateTime.parse(student['registrationDate']),
          );
        }
      }
    } else {
      final lecturers = _getLecturers();
      for (var lecturer in lecturers.values) {
        if (lecturer['email'] == email && lecturer['password'] == password) {
          return User.fromJson(lecturer);
        }
      }
    }
    return null;
  }

  static Map<String, dynamic> _getLecturers() {
    return _storage['lecturers'] ?? {};
  }

// Get all students for a lecturer's course
  static Future<List<Student>> getStudentsByCourse(String courseName) async {
    final students = _getStudents();
    final List<Student> result = [];
    students.forEach((key, value) {
      final student = Student.fromJson(value);
      if (student.course == courseName) {
        result.add(student);
      }
    });
    return result;
  }

  // INITIALIZATION

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

  // ==================== STUDENT MANAGEMENT ====================

  static Future<bool> registerStudent(Student student) async {
    final students = _getStudents();
    if (students.containsKey(student.regNumber)) return false;

    students[student.regNumber] = student.toJson();
    _storage['students'] = students;
    await _save();
    return true;
  }

  // In database_service.dart, add/update this method:
  static Future<Student?> loginStudent(String loginId, String password) async {
    final students = _getStudents();

    for (var studentJson in students.values) {
      // Check by registration number OR email
      if ((studentJson['regNumber'] == loginId ||
              studentJson['email'] == loginId) &&
          studentJson['password'] == password) {
        return Student.fromJson(studentJson);
      }
    }
    return null;
  }

  static Future<Student?> getStudent(String regNumber) async {
    final students = _getStudents();
    final data = students[regNumber];
    if (data != null) return Student.fromJson(data);
    return null;
  }

  static Future<void> updateStudent(
      String regNumber, Map<String, dynamic> studentData) async {
    final students = _getStudents();
    students[regNumber] = studentData;
    _storage['students'] = students;
    await _save();
  }

  static Map<String, dynamic> _getStudents() {
    return _storage['students'] ?? {};
  }

  static Future<List<Student>> getAllStudents() async {
    final students = _getStudents();
    final List<Student> studentList = [];
    students.forEach((key, value) {
      studentList.add(Student.fromJson(value));
    });
    return studentList;
  }

  static Future<void> printAllStudents() async {
    final students = _getStudents();
    print('Total students: ${students.length}');
    students.forEach((key, value) {
      print(
          'Student: ${value['regNumber']} - ${value['name']} - ${value['email']}');
    });
  }

  // ==================== ATTENDANCE MANAGEMENT ====================

  static Future<void> markAttendance({
    required String regNumber,
    required String date,
    required String status,
    required String unitName,
  }) async {
    final attendance = _getAttendance();
    final id = '${regNumber}_${date}_$unitName';

    attendance[id] = {
      'regNumber': regNumber,
      'date': date,
      'status': status,
      'unitName': unitName,
      'timestamp': DateTime.now().toIso8601String(),
    };
    _storage['attendance'] = attendance;
    await _save();
  }

  static Future<List<Map<String, dynamic>>> getAttendance(
      String regNumber) async {
    final attendance = _getAttendance();
    final result = <Map<String, dynamic>>[];
    attendance.forEach((key, value) {
      if (value['regNumber'] == regNumber) {
        result.add(value);
      }
    });
    result.sort((a, b) => b['date'].compareTo(a['date']));
    return result;
  }

  static Future<double> getAttendancePercentage(String regNumber) async {
    final records = await getAttendance(regNumber);
    if (records.isEmpty) return 0;

    final present = records.where((r) => r['status'] == 'present').length;
    return (present / records.length) * 100;
  }

  static Map<String, dynamic> _getAttendance() {
    return _storage['attendance'] ?? {};
  }

  // ==================== COURSE MANAGEMENT ====================

  static Future<void> enrollCourse(
      String regNumber, Map<String, dynamic> course) async {
    final courses = _getCourses();
    final id = '${regNumber}_${course['code']}';
    courses[id] = {
      'code': course['code'],
      'name': course['name'],
      'credits': course['credits'],
      'instructor': course['instructor'],
      'regNumber': regNumber,
      'enrolledDate': DateTime.now().toIso8601String(),
    };
    _storage['courses'] = courses;
    await _save();
  }

  static Future<List<Map<String, dynamic>>> getCourses(String regNumber) async {
    final courses = _getCourses();
    final result = <Map<String, dynamic>>[];
    courses.forEach((key, value) {
      if (value['regNumber'] == regNumber) {
        result.add(value);
      }
    });
    return result;
  }

  static Future<void> removeCourse(String regNumber, String courseCode) async {
    final courses = _getCourses();
    final id = '${regNumber}_$courseCode';
    courses.remove(id);
    _storage['courses'] = courses;
    await _save();
  }

  static Map<String, dynamic> _getCourses() {
    return _storage['courses'] ?? {};
  }

  // ==================== NOTIFICATION MANAGEMENT ====================

  static Future<void> sendNotification(
      String regNumber, String title, String message) async {
    final notifications = _getNotifications();
    final id = DateTime.now().millisecondsSinceEpoch.toString();

    notifications[id] = {
      'id': id,
      'regNumber': regNumber,
      'title': title,
      'message': message,
      'date': DateTime.now().toIso8601String(),
      'isRead': false,
    };
    _storage['notifications'] = notifications;
    await _save();
  }

  static Future<List<Map<String, dynamic>>> getNotifications(
      String regNumber) async {
    final notifications = _getNotifications();
    final result = <Map<String, dynamic>>[];
    notifications.forEach((key, value) {
      if (value['regNumber'] == regNumber) {
        result.add(value);
      }
    });
    result.sort((a, b) => b['date'].compareTo(a['date']));
    return result;
  }

  static Future<int> getUnreadCount(String regNumber) async {
    final notifications = await getNotifications(regNumber);
    return notifications.where((n) => !n['isRead']).length;
  }

  static Future<void> markNotificationAsRead(String id) async {
    final notifications = _getNotifications();
    if (notifications.containsKey(id)) {
      notifications[id]['isRead'] = true;
      _storage['notifications'] = notifications;
      await _save();
    }
  }

  static Future<void> markAllNotificationsAsRead(String regNumber) async {
    final notifications = _getNotifications();
    bool changed = false;
    notifications.forEach((key, value) {
      if (value['regNumber'] == regNumber && value['isRead'] == false) {
        notifications[key]['isRead'] = true;
        changed = true;
      }
    });
    if (changed) {
      _storage['notifications'] = notifications;
      await _save();
    }
  }

  static Map<String, dynamic> _getNotifications() {
    return _storage['notifications'] ?? {};
  }

  // ==================== DASHBOARD STATISTICS ====================

  static Future<Map<String, dynamic>> getDashboardStats(
      String regNumber) async {
    final attendance = await getAttendance(regNumber);
    final courses = await getCourses(regNumber);

    final totalPresent =
        attendance.where((a) => a['status'] == 'present').length;
    final totalAbsent = attendance.where((a) => a['status'] == 'absent').length;
    final totalLate = attendance.where((a) => a['status'] == 'late').length;
    final attendanceRate =
        attendance.isEmpty ? 0 : (totalPresent / attendance.length) * 100;

    return {
      'totalCourses': courses.length,
      'totalCredits': courses.fold(0, (sum, c) => sum + (c['credits'] as int)),
      'attendanceRate': attendanceRate,
      'totalClasses': attendance.length,
      'presentCount': totalPresent,
      'absentCount': totalAbsent,
      'lateCount': totalLate,
      'streak': _calculateStreak(attendance),
      'lastAttendance':
          attendance.isNotEmpty ? attendance.first['date'] : 'No records',
    };
  }

  static int _calculateStreak(List<Map<String, dynamic>> attendance) {
    int streak = 0;
    // Sort by date to get most recent first
    final sorted = List<Map<String, dynamic>>.from(attendance);
    sorted.sort((a, b) => b['date'].compareTo(a['date']));

    for (var record in sorted) {
      if (record['status'] == 'present') {
        streak++;
      } else {
        break;
      }
    }
    return streak;
  }

  // ==================== UTILITY METHODS ====================

  static Future<void> clearAllData() async {
    _storage = {};
    await _save();
  }

  static Future<Map<String, dynamic>> getSystemStats() async {
    final students = await getAllStudents();
    final allAttendance = _getAttendance();

    return {
      'totalStudents': students.length,
      'totalAttendanceRecords': allAttendance.length,
      'totalCourses': _getCourses().length,
      'totalNotifications': _getNotifications().length,
    };
  }

  static Future<void> backupData() async {
    if (kIsWeb) return;

    try {
      final dir = Directory.current;
      final backupDir = Directory('${dir.path}/campus_flow_backup');
      if (!await backupDir.exists()) {
        await backupDir.create(recursive: true);
      }

      final backupFile = File(
          '${backupDir.path}/backup_${DateTime.now().millisecondsSinceEpoch}.json');
      await backupFile.writeAsString(json.encode(_storage));
    } catch (e) {
      // Handle backup error
    }
  }

  static Future<bool> restoreData(String backupFilePath) async {
    try {
      final file = File(backupFilePath);
      if (await file.exists()) {
        final content = await file.readAsString();
        _storage = json.decode(content);
        await _save();
        return true;
      }
    } catch (e) {
      return false;
    }
    return false;
  }
}
