import 'package:campus_flow/database/sqlite_helper.dart';
import 'package:campus_flow/services/firebase_service.dart';
import 'package:campus_flow/services/json_api_service.dart';

class DataService {
  static final DataService _instance = DataService._internal();
  factory DataService() => _instance;
  DataService._internal();

  final SQLiteHelper _sqlite = SQLiteHelper();

  // ==================== SYNC ALL SOURCES ====================

  // Sync from SQLite to Firebase
  Future<void> syncToFirebase() async {
    final students = await _sqlite.getAllStudents();
    final records = await _sqlite.getAllRecords();

    for (var student in students) {
      await CampusFirebaseService.saveStudent(student);
      await CampusFirebaseService.saveStudentRealtime(student);
    }

    for (var record in records) {
      await CampusFirebaseService.saveAttendance(record);
    }
  }

  // Sync from Firebase to SQLite
  Future<void> syncFromFirebase() async {
    // Use getStudents() instead of getStudentsOnce()
    final students = await CampusFirebaseService.getStudents();

    for (var student in students) {
      student['id'] = null;
      await _sqlite.insertStudent(student);
    }
  }

  // Import from JSON API to SQLite
  Future<void> importUsersFromApi({int count = 20}) async {
    final users = await JsonApiService.fetchRandomUsers(count: count);
    for (var user in users) {
      await _sqlite.insertStudent({
        'regNumber':
            'API_${DateTime.now().millisecondsSinceEpoch}_${users.indexOf(user)}',
        'name': user['name'],
        'email': user['email'],
        'phone': user['phone'] ?? 'N/A',
        'course': user['country'] ?? 'Unknown',
        'semester': 1,
      });
    }
  }

  // ==================== DATA SOURCE SELECTOR ====================

  // Get students from SQLite
  Future<List<Map<String, dynamic>>> getStudentsFromLocal() async {
    return await _sqlite.getAllStudents();
  }

  // Get students from Firebase (once)
  Future<List<Map<String, dynamic>>> getStudentsFromFirebase() async {
    return await CampusFirebaseService.getStudents();
  }

  // Get students from API
  Future<List<Map<String, dynamic>>> getStudentsFromApi(
      {int count = 20}) async {
    return await JsonApiService.fetchRandomUsers(count: count);
  }
}
