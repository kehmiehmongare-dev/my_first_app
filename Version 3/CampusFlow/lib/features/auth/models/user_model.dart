import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole {
  student,
  lecturer,
  admin,
  finance,
  parent,
}

class AppUser {
  final String uid;
  final String email;
  final String? phone;
  final String displayName;
  final UserRole role;
  final bool isActive;
  final DateTime createdAt;
  final DateTime lastLogin;
  final Map<String, dynamic>? profileData;

  AppUser({
    required this.uid,
    required this.email,
    this.phone,
    required this.displayName,
    required this.role,
    required this.isActive,
    required this.createdAt,
    required this.lastLogin,
    this.profileData,
  });

  // Factory method to create from Firebase
  factory AppUser.fromFirebase(Map<String, dynamic> data, String uid) {
    return AppUser(
      uid: uid,
      email: data['email'] ?? '',
      phone: data['phone'],
      displayName: data['displayName'] ?? 'User',
      role: AppUser._parseRole(data['role']),
      isActive: data['isActive'] ?? true,
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      lastLogin: DateTime.now(),
      profileData: data,
    );
  }

  static UserRole _parseRole(String? role) {
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

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'phone': phone,
      'displayName': displayName,
      'role': role.name,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastLogin': Timestamp.fromDate(lastLogin),
    };
  }

  // Check if user has specific role
  bool hasRole(UserRole requiredRole) => role == requiredRole;

  // Check if user has any of the given roles
  bool hasAnyRole(List<UserRole> roles) => roles.contains(role);

  // Helper getters
  bool get isStudent => role == UserRole.student;
  bool get isLecturer => role == UserRole.lecturer;
  bool get isAdmin => role == UserRole.admin;
  bool get isFinance => role == UserRole.finance;
  bool get isParent => role == UserRole.parent;
}
