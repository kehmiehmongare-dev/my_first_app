import 'package:campus_flow/data/database/sqlite_helper.dart';
import 'package:campus_flow/data/api/json_api_service.dart';
import 'package:campus_flow/data/database/firebase_service.dart' as fb;

class DataService {
  static final DataService _instance = DataService._internal();
  factory DataService() => _instance;
  DataService._internal();

  final SQLiteHelper _sqlite = SQLiteHelper();
  final fb.FirebaseService _firebase = fb.FirebaseService();

  // ==================== SYNC ALL SOURCES ====================

  // Sync from SQLite to Firebase
  Future<void> syncToFirebase() async {
    final students = await _sqlite.getAllStudents();

    for (var student in students) {
      await _firebase.saveStudent(student);
    }
  }

  // Sync from Firebase to SQLite
  Future<void> syncFromFirebase() async {
    final students = await _firebase.getStudents();

    for (var student in students) {
      // Convert to SQLite student format
      await _sqlite.insertStudent({
        'regNumber': student['regNumber'] ??
            'API_${DateTime.now().millisecondsSinceEpoch}',
        'name': student['name'] ?? 'Unknown',
        'email': student['email'] ?? '',
        'phone': student['phone'] ?? '',
        'course': student['course'] ?? 'General',
        'semester': student['semester'] ?? 1,
      });
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

  // Get students from Firebase
  Future<List<Map<String, dynamic>>> getStudentsFromFirebase() async {
    return await _firebase.getStudents();
  }

  // Get students from API
  Future<List<Map<String, dynamic>>> getStudentsFromApi(
      {int count = 20}) async {
    return await JsonApiService.fetchRandomUsers(count: count);
  }
}
