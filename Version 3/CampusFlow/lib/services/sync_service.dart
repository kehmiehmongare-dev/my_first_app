import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/local_student_model.dart';
import 'database_helper.dart';

class SyncService {
  final DatabaseHelper _db = DatabaseHelper();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // ✅ Sync local students with Firebase
  Future<Map<String, int>> syncStudents() async {
    int added = 0;
    int updated = 0;
    int failed = 0;

    try {
      final user = _auth.currentUser;
      if (user == null) return {'added': 0, 'updated': 0, 'failed': 1};

      // Get unsynced students
      final unsynced = await _db.getUnsyncedStudents();

      for (var student in unsynced) {
        try {
          // Check if exists in Firebase
          final doc =
              await _firestore.collection('students').doc(student.uid).get();

          if (doc.exists) {
            // Update existing
            await _firestore
                .collection('students')
                .doc(student.uid)
                .update(student.toFirestore());
            updated++;
          } else {
            // Create new
            await _firestore
                .collection('students')
                .doc(student.uid)
                .set(student.toFirestore());
            added++;
          }

          // Mark as synced
          await _db.markAsSynced(student.uid);
        } catch (e) {
          print('Sync error for ${student.uid}: $e');
          failed++;
        }
      }

      return {'added': added, 'updated': updated, 'failed': failed};
    } catch (e) {
      print('Sync service error: $e');
      return {'added': 0, 'updated': 0, 'failed': 1};
    }
  }

  // ✅ Sync Firebase students to local
  Future<int> syncFirebaseToLocal() async {
    int added = 0;

    try {
      final user = _auth.currentUser;
      if (user == null) return 0;

      final snapshot = await _firestore.collection('students').get();

      final students = snapshot.docs.map((doc) {
        final data = doc.data();
        return LocalStudentModel(
          uid: doc.id,
          displayName: data['displayName'] ?? 'Student',
          regNumber: data['regNumber'] ?? 'STU001',
          email: data['email'] ?? '',
          course: data['course'] ?? data['courseName'] ?? 'Not Enrolled',
          department: data['department'] ?? data['faculty'] ?? '',
          totalFees: (data['totalFees'] ?? 60000).toDouble(),
          paidFees: (data['paidFees'] ?? 0).toDouble(),
          pendingFees: (data['pendingFees'] ?? 60000).toDouble(),
          temporaryPassword: data['temporaryPassword'],
          isSynced: true,
          createdAt:
              (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
          updatedAt:
              (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        );
      }).toList();

      if (students.isNotEmpty) {
        await _db.insertStudents(students);
        added = students.length;
      }

      return added;
    } catch (e) {
      print('Sync Firebase to local error: $e');
      return 0;
    }
  }
}
