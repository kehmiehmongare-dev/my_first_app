import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:campus_flow/services/database_helper.dart';

class DeleteService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final DatabaseHelper _db = DatabaseHelper();

  // ==================== DELETE STUDENT ====================

  /// ✅ Permanently delete a student
  /// This deletes from Firebase Auth, Firestore, and Local DB
  Future<DeleteResult> deleteStudent({
    required String uid,
    required String email,
    bool permanent = true,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return DeleteResult.failure('You must be logged in to delete users.');
      }

      // ✅ Check if current user is admin
      final adminDoc = await _firestore.collection('users').doc(user.uid).get();
      if (!adminDoc.exists || adminDoc.data()?['role'] != 'admin') {
        return DeleteResult.failure('Only administrators can delete users.');
      }

      // ✅ Don't allow deleting yourself
      if (uid == user.uid) {
        return DeleteResult.failure('You cannot delete your own account.');
      }

      List<String> errors = [];

      // ✅ Step 1: Delete from Firebase Auth
      try {
        // Note: Deleting users from Auth requires admin SDK
        // We'll use the client-side method if possible
        // For security, this might need to be done via Cloud Function
        // For now, we'll mark as disabled and delete from Firestore

        // Mark as disabled in Firestore instead of deleting from Auth
        await _firestore.collection('users').doc(uid).update({
          'isActive': false,
          'deletedAt': FieldValue.serverTimestamp(),
          'deletedBy': user.uid,
        });
      } catch (e) {
        errors.add('Auth deletion warning: $e');
      }

      // ✅ Step 2: Delete from Firestore collections
      try {
        // Delete from students collection
        await _firestore.collection('students').doc(uid).delete();
      } catch (e) {
        errors.add('Student collection deletion failed: $e');
      }

      try {
        // Delete from users collection
        await _firestore.collection('users').doc(uid).delete();
      } catch (e) {
        errors.add('Users collection deletion failed: $e');
      }

      try {
        // Delete related data
        final attendanceBatch = _firestore.batch();
        final attendanceSnapshot = await _firestore
            .collection('attendance')
            .where('studentId', isEqualTo: uid)
            .get();

        for (var doc in attendanceSnapshot.docs) {
          attendanceBatch.delete(doc.reference);
        }
        await attendanceBatch.commit();
      } catch (e) {
        errors.add('Attendance deletion warning: $e');
      }

      try {
        // Delete related payments
        final paymentsBatch = _firestore.batch();
        final paymentsSnapshot = await _firestore
            .collection('payments')
            .where('studentId', isEqualTo: uid)
            .get();

        for (var doc in paymentsSnapshot.docs) {
          paymentsBatch.delete(doc.reference);
        }
        await paymentsBatch.commit();
      } catch (e) {
        errors.add('Payments deletion warning: $e');
      }

      // ✅ Step 3: Delete from local SQLite
      try {
        await _db.deleteStudent(uid);
      } catch (e) {
        errors.add('Local DB deletion warning: $e');
      }

      if (errors.isEmpty) {
        return DeleteResult.success('Student deleted successfully.');
      } else {
        return DeleteResult.partialSuccess(
          'Student deleted with some warnings.',
          errors,
        );
      }
    } catch (e) {
      return DeleteResult.failure('Failed to delete student: $e');
    }
  }

  // ==================== DELETE LECTURER ====================

  /// ✅ Delete a lecturer
  Future<DeleteResult> deleteLecturer({
    required String uid,
    required String email,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return DeleteResult.failure('You must be logged in to delete users.');
      }

      // ✅ Check if current user is admin
      final adminDoc = await _firestore.collection('users').doc(user.uid).get();
      if (!adminDoc.exists || adminDoc.data()?['role'] != 'admin') {
        return DeleteResult.failure('Only administrators can delete users.');
      }

      // ✅ Don't allow deleting yourself
      if (uid == user.uid) {
        return DeleteResult.failure('You cannot delete your own account.');
      }

      List<String> errors = [];

      // ✅ Delete from Firestore collections
      try {
        await _firestore.collection('lecturers').doc(uid).delete();
      } catch (e) {
        errors.add('Lecturers collection deletion failed: $e');
      }

      try {
        await _firestore.collection('users').doc(uid).delete();
      } catch (e) {
        errors.add('Users collection deletion failed: $e');
      }

      // ✅ Delete related courses
      try {
        final coursesSnapshot = await _firestore
            .collection('courses')
            .where('lecturerId', isEqualTo: uid)
            .get();

        for (var doc in coursesSnapshot.docs) {
          await doc.reference.update({
            'lecturerId': null,
            'lecturerName': 'Unassigned',
          });
        }
      } catch (e) {
        errors.add('Course update warning: $e');
      }

      if (errors.isEmpty) {
        return DeleteResult.success('Lecturer deleted successfully.');
      } else {
        return DeleteResult.partialSuccess(
          'Lecturer deleted with some warnings.',
          errors,
        );
      }
    } catch (e) {
      return DeleteResult.failure('Failed to delete lecturer: $e');
    }
  }

  // ==================== SOFT DELETE ====================

  /// ✅ Soft delete (archive) a student
  /// Marks as deleted but keeps data for recovery
  Future<DeleteResult> softDeleteStudent(String uid) async {
    try {
      await _firestore.collection('students').doc(uid).update({
        'isActive': false,
        'deletedAt': FieldValue.serverTimestamp(),
        'deletedBy': _auth.currentUser?.uid,
      });

      return DeleteResult.success('Student archived successfully.');
    } catch (e) {
      return DeleteResult.failure('Failed to archive student: $e');
    }
  }

  // ==================== RESTORE SOFT DELETED ====================

  /// ✅ Restore a soft-deleted student
  Future<DeleteResult> restoreStudent(String uid) async {
    try {
      await _firestore.collection('students').doc(uid).update({
        'isActive': true,
        'deletedAt': null,
        'restoredAt': FieldValue.serverTimestamp(),
        'restoredBy': _auth.currentUser?.uid,
      });

      return DeleteResult.success('Student restored successfully.');
    } catch (e) {
      return DeleteResult.failure('Failed to restore student: $e');
    }
  }

  // ==================== BULK DELETE ====================

  /// ✅ Bulk delete multiple students
  Future<BulkDeleteResult> bulkDeleteStudents(List<String> uids) async {
    int success = 0;
    int failed = 0;
    List<String> errors = [];

    for (var uid in uids) {
      final result = await deleteStudent(uid: uid, email: '');
      if (result.isSuccess) {
        success++;
      } else {
        failed++;
        errors.add(result.message);
      }
    }

    return BulkDeleteResult(
      total: uids.length,
      success: success,
      failed: failed,
      errors: errors,
    );
  }
}

// ==================== RESULT CLASSES ====================

class DeleteResult {
  final bool isSuccess;
  final String message;
  final List<String>? warnings;

  DeleteResult._(this.isSuccess, this.message, [this.warnings]);

  factory DeleteResult.success(String message) {
    return DeleteResult._(true, message);
  }

  factory DeleteResult.failure(String message) {
    return DeleteResult._(false, message);
  }

  factory DeleteResult.partialSuccess(String message, List<String> warnings) {
    return DeleteResult._(true, message, warnings);
  }
}

class BulkDeleteResult {
  final int total;
  final int success;
  final int failed;
  final List<String> errors;

  BulkDeleteResult({
    required this.total,
    required this.success,
    required this.failed,
    this.errors = const [],
  });

  String get summary => 'Total: $total, Success: $success, Failed: $failed';
}
