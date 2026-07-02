import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'offline_attendance_db.dart';

class SyncService {
  static final SyncService _instance = SyncService._internal();
  factory SyncService() => _instance;
  SyncService._internal();

  final OfflineAttendanceDB _db = OfflineAttendanceDB();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ✅ Check internet connection
  Future<bool> hasInternet() async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      return connectivityResult != ConnectivityResult.none;
    } catch (e) {
      return false;
    }
  }

  // ✅ Sync offline attendance to Firebase
  Future<Map<String, dynamic>> syncAttendance() async {
    final result = <String, dynamic>{
      'synced': 0,
      'failed': 0,
      'errors': <String>[],
    };

    try {
      // Check internet
      if (!await hasInternet()) {
        result['errors'] = ['No internet connection'];
        return result;
      }

      // Get unsynced records
      final unsynced = await _db.getUnsyncedAttendance();

      if (unsynced.isEmpty) {
        result['synced'] = 0;
        return result;
      }

      // Process each record
      for (var record in unsynced) {
        try {
          // ✅ Add to Firebase
          await _firestore.collection('attendance').add({
            'studentId': record['studentId'] ?? '',
            'studentName': record['studentName'] ?? 'Student',
            'regNumber': record['regNumber'] ?? 'STU001',
            'unitCode': record['unitCode'] ?? '',
            'unitName': record['unitName'] ?? '',
            'sessionId': record['sessionId'] ?? '',
            'lecturerId': record['lecturerId'] ?? '',
            'week': record['week'] ?? 1,
            'date': record['date'] ?? DateTime.now().toIso8601String(),
            'timestamp': FieldValue.serverTimestamp(),
            'status': 'present',
            'source': 'offline_sync',
            'syncedAt': FieldValue.serverTimestamp(),
          });

          // ✅ Update attendance session (if sessionId exists)
          final sessionId = record['sessionId'] as String?;
          if (sessionId != null && sessionId.isNotEmpty) {
            await _firestore
                .collection('attendance_sessions')
                .doc(sessionId)
                .update({
              'students': FieldValue.arrayUnion([record['studentId'] ?? '']),
            });
          }

          // ✅ Update student's attendance progress
          final studentId = record['studentId'] as String?;
          final unitCode = record['unitCode'] as String?;
          if (studentId != null && unitCode != null) {
            await _updateStudentProgress(studentId, unitCode);
          }

          // ✅ Mark as synced
          await _db.markAsSynced(record['id'] as int);
          result['synced'] = (result['synced'] as int) + 1;
        } catch (e) {
          result['failed'] = (result['failed'] as int) + 1;
          (result['errors'] as List<String>).add('Record ${record['id']}: $e');
        }
      }

      // ✅ Clean up synced records
      if ((result['synced'] as int) > 0) {
        await _db.deleteSyncedRecords();
      }
    } catch (e) {
      (result['errors'] as List<String>).add('Sync error: $e');
    }

    return result;
  }

  // ✅ Update student's attendance progress
  Future<void> _updateStudentProgress(String studentId, String unitCode) async {
    try {
      // ✅ Get all attendance records for this student and unit
      final snapshot = await _firestore
          .collection('attendance')
          .where('studentId', isEqualTo: studentId)
          .where('unitCode', isEqualTo: unitCode)
          .get();

      final totalClasses = 14; // ✅ 14 weeks
      final attended = snapshot.docs.length;
      final percentage = totalClasses > 0 ? (attended / totalClasses) * 100 : 0;

      // ✅ Update student document
      await _firestore.collection('students').doc(studentId).set({
        'attendance.$unitCode': {
          'totalClasses': totalClasses,
          'attended': attended,
          'percentage': percentage.toStringAsFixed(1),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      // Silently handle error
    }
  }

  // ✅ Start auto-sync listener
  void startAutoSync() {
    Connectivity().onConnectivityChanged.listen((result) async {
      if (result != ConnectivityResult.none) {
        await syncAttendance();
      }
    });
  }

  // ✅ Get sync status for UI
  Future<Map<String, dynamic>> getSyncStatus() async {
    final hasInternet = await this.hasInternet();
    final unsyncedCount = await _db.getUnsyncedCount();

    return {
      'hasInternet': hasInternet,
      'unsyncedCount': unsyncedCount,
      'isSyncing': false,
    };
  }
}
