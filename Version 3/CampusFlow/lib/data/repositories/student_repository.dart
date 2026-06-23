import 'package:cloud_firestore/cloud_firestore.dart';
import '../../features/student/models/student_model.dart';

class StudentRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<StudentModel?> getStudentById(String uid) async {
    try {
      final doc = await _firestore.collection('students').doc(uid).get();
      if (!doc.exists) return null;
      return StudentModel.fromMap(doc.data()!, uid);
    } catch (e) {
      throw Exception('Failed to load student: $e');
    }
  }

  Future<void> updateStudent(StudentModel student) async {
    try {
      await _firestore.collection('students').doc(student.uid).update({
        'displayName': student.displayName,
        'regNumber': student.regNumber,
        'course': student.course,
        'department': student.department,
        'attendanceRate': student.attendanceRate,
        'totalFees': student.totalFees,
        'paidFees': student.paidFees,
        'registeredUnits': student.registeredUnits,
        'unitsRegistered': student.unitsRegistered,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to update student: $e');
    }
  }
}
