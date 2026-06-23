import 'package:campus_flow/data/database/sqlite_helper.dart';
import 'package:campus_flow/data/database/firebase_service.dart';

class AttendanceRepository {
  final SQLiteHelper _localDb = SQLiteHelper();
  final FirebaseService _firebase = FirebaseService();

  // Get attendance from local database
  Future<List<Map<String, dynamic>>> getAttendanceLocal(
      String studentId) async {
    return await _localDb.getStudentAttendance(studentId);
  }

  // Get attendance from Firebase
  Future<List<Map<String, dynamic>>> getAttendanceFirebase(
      String regNumber) async {
    return await _firebase.getAttendance(regNumber);
  }

  // Mark attendance (local + Firebase)
  Future<void> markAttendance({
    required String studentId,
    required String studentName,
    required String courseId,
    required String courseCode,
    required String date,
    required String status,
  }) async {
    // Save to local
    await _localDb.markAttendanceManual(
      studentId: studentId,
      studentName: studentName,
      courseId: courseId,
      courseCode: courseCode,
      date: date,
      status: status,
    );

    // Save to Firebase
    await _firebase.saveAttendance({
      'studentId': studentId,
      'studentName': studentName,
      'courseId': courseId,
      'courseCode': courseCode,
      'date': date,
      'status': status,
    });
  }
}
