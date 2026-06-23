import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/notification_model.dart';

class NotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // ✅ Send notification to students
  Future<void> sendNotification({
    required String title,
    required String message,
    required NotificationType type,
    required List<String> recipientIds,
    String? courseCode,
    bool isImportant = false,
    Map<String, dynamic>? actionData,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not logged in');

      // Get sender info
      String senderName = 'Lecturer';
      String senderRole = 'lecturer';

      final lecturerDoc = await _firestore
          .collection('lecturers')
          .doc(user.uid)
          .get();

      if (lecturerDoc.exists) {
        final data = lecturerDoc.data() as Map<String, dynamic>;
        senderName = data['displayName'] ?? 'Lecturer';
      }

      final notification = NotificationModel(
        id: _firestore.collection('notifications').doc().id,
        title: title,
        message: message,
        type: type,
        senderId: user.uid,
        senderName: senderName,
        senderRole: senderRole,
        recipientIds: recipientIds,
        courseCode: courseCode,
        isImportant: isImportant,
        createdAt: DateTime.now(),
        actionData: actionData,
      );

      await _firestore
          .collection('notifications')
          .doc(notification.id)
          .set(notification.toJson());

      print('✅ Notification sent: $title');
    } catch (e) {
      print('❌ Error sending notification: $e');
      throw Exception('Failed to send notification');
    }
  }

  // ✅ Get notifications for current student
  Stream<List<NotificationModel>> getStudentNotifications() {
    final user = _auth.currentUser;
    if (user == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection('notifications')
        .where('recipientIds', arrayContains: user.uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return NotificationModel.fromJson(doc.data(), doc.id);
          }).toList();
        });
  }

  // ✅ Get unread count for badge
  Stream<int> getUnreadCount() {
    final user = _auth.currentUser;
    if (user == null) {
      return Stream.value(0);
    }

    return _firestore
        .collection('notifications')
        .where('recipientIds', arrayContains: user.uid)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  // ✅ Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      await _firestore
          .collection('notifications')
          .doc(notificationId)
          .update({
            'isRead': true,
          });
    } catch (e) {
      print('Error marking notification as read: $e');
    }
  }

  // ✅ Mark all as read
  Future<void> markAllAsRead() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final batch = _firestore.batch();
      final snapshot = await _firestore
          .collection('notifications')
          .where('recipientIds', arrayContains: user.uid)
          .where('isRead', isEqualTo: false)
          .get();

      for (var doc in snapshot.docs) {
        batch.update(doc.reference, {'isRead': true});
      }

      await batch.commit();
    } catch (e) {
      print('Error marking all as read: $e');
    }
  }

  // ✅ Delete notification (lecturer only)
  Future<void> deleteNotification(String notificationId) async {
    try {
      await _firestore
          .collection('notifications')
          .doc(notificationId)
          .delete();
    } catch (e) {
      print('Error deleting notification: $e');
    }
  }

  // ✅ Send to all students in a course
  Future<void> sendToCourseStudents({
    required String title,
    required String message,
    required NotificationType type,
    required String courseCode,
    bool isImportant = false,
  }) async {
    try {
      // Get all students in this course
      final studentsSnapshot = await _firestore
          .collection('students')
          .where('courseCode', isEqualTo: courseCode)
          .get();

      final studentIds = studentsSnapshot.docs.map((doc) => doc.id).toList();

      if (studentIds.isEmpty) {
        print('⚠️ No students found for course: $courseCode');
        return;
      }

      await sendNotification(
        title: title,
        message: message,
        type: type,
        recipientIds: studentIds,
        courseCode: courseCode,
        isImportant: isImportant,
      );

      print('✅ Notification sent to ${studentIds.length} students');
    } catch (e) {
      print('❌ Error sending to course students: $e');
      throw Exception('Failed to send notification');
    }
  }
}