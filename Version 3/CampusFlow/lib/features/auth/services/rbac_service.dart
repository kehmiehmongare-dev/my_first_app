import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:campus_flow/features/auth/models/user_model.dart';

class RbacService {
  static final RbacService _instance = RbacService._internal();
  factory RbacService() => _instance;
  RbacService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ✅ Helper method to parse role
  UserRole _parseRole(String? role) {
    if (role == null) return UserRole.student;
    switch (role.toLowerCase()) {
      case 'admin':
        return UserRole.admin;
      case 'lecturer':
        return UserRole.lecturer;
      case 'finance':
        return UserRole.finance;
      case 'parent':
        return UserRole.parent;
      default:
        return UserRole.student;
    }
  }

  // Check if user is authorized for a specific role
  Future<bool> isAuthorized(String uid, List<UserRole> allowedRoles) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (!doc.exists) return false;

      final data = doc.data();
      final role = _parseRole(data?['role']);
      return allowedRoles.contains(role);
    } catch (e) {
      return false;
    }
  }

  // Get user role
  Future<UserRole?> getUserRole(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (!doc.exists) return null;

      final data = doc.data();
      return _parseRole(data?['role']);
    } catch (e) {
      return null;
    }
  }

  // Update user role (Admin only)
  Future<void> updateUserRole(String uid, UserRole newRole) async {
    await _firestore.collection('users').doc(uid).update({
      'role': newRole.name,
    });
  }

  // Get all users with a specific role
  Future<List<AppUser>> getUsersByRole(UserRole role) async {
    final snapshot = await _firestore
        .collection('users')
        .where('role', isEqualTo: role.name)
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      return AppUser.fromFirebase(data, doc.id);
    }).toList();
  }

  // Create a new user with role
  Future<void> createUserWithRole({
    required String uid,
    required String email,
    required String displayName,
    required UserRole role,
    String? phone,
  }) async {
    final user = AppUser(
      uid: uid,
      email: email,
      phone: phone,
      displayName: displayName,
      role: role,
      isActive: true,
      createdAt: DateTime.now(),
      lastLogin: DateTime.now(),
    );

    await _firestore.collection('users').doc(uid).set(user.toJson());
  }

  // Deactivate user
  Future<void> deactivateUser(String uid) async {
    await _firestore.collection('users').doc(uid).update({
      'isActive': false,
    });
  }

  // Activate user
  Future<void> activateUser(String uid) async {
    await _firestore.collection('users').doc(uid).update({
      'isActive': true,
    });
  }
}

// Permission constants for easy reference
class Permissions {
  static const String viewAttendance = 'view_attendance';
  static const String markAttendance = 'mark_attendance';
  static const String manageStudents = 'manage_students';
  static const String manageFees = 'manage_fees';
  static const String viewReports = 'view_reports';
  static const String manageUsers = 'manage_users';
  static const String systemSettings = 'system_settings';
}
