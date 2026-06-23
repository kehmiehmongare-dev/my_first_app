import 'package:cloud_firestore/cloud_firestore.dart';

class LocalStudentModel {
  final int? id;
  final String uid;
  final String displayName;
  final String regNumber;
  final String email;
  final String course;
  final String department;
  final double totalFees;
  final double paidFees;
  final double pendingFees;
  final String? temporaryPassword;
  final bool isSynced;
  final DateTime createdAt;
  final DateTime updatedAt;

  LocalStudentModel({
    this.id,
    required this.uid,
    required this.displayName,
    required this.regNumber,
    required this.email,
    required this.course,
    required this.department,
    required this.totalFees,
    required this.paidFees,
    required this.pendingFees,
    this.temporaryPassword,
    this.isSynced = false,
    required this.createdAt,
    required this.updatedAt,
  });

  // ✅ Convert to Map for database insertion
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'displayName': displayName,
      'regNumber': regNumber,
      'email': email,
      'course': course,
      'department': department,
      'totalFees': totalFees,
      'paidFees': paidFees,
      'pendingFees': pendingFees,
      'temporaryPassword': temporaryPassword,
      'isSynced': isSynced ? 1 : 0,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  // ✅ Create from Map
  factory LocalStudentModel.fromMap(Map<String, dynamic> map) {
    return LocalStudentModel(
      id: map['id'],
      uid: map['uid'],
      displayName: map['displayName'],
      regNumber: map['regNumber'],
      email: map['email'],
      course: map['course'],
      department: map['department'],
      totalFees: map['totalFees'],
      paidFees: map['paidFees'],
      pendingFees: map['pendingFees'],
      temporaryPassword: map['temporaryPassword'],
      isSynced: map['isSynced'] == 1,
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: DateTime.parse(map['updatedAt']),
    );
  }

  // ✅ Convert to Firebase format - FIXED: Use DateTime.now() instead of FieldValue
  Map<String, dynamic> toFirestore() {
    return {
      'displayName': displayName,
      'regNumber': regNumber,
      'email': email,
      'course': course,
      'department': department,
      'totalFees': totalFees,
      'paidFees': paidFees,
      'pendingFees': pendingFees,
      'temporaryPassword': temporaryPassword,
      'updatedAt':
          DateTime.now().toIso8601String(), // ✅ FIXED: Use DateTime.now()
    };
  }

  // ✅ Factory to create from Firestore
  factory LocalStudentModel.fromFirestore(
      Map<String, dynamic> map, String uid) {
    return LocalStudentModel(
      uid: uid,
      displayName: map['displayName'] ?? 'Student',
      regNumber: map['regNumber'] ?? 'STU001',
      email: map['email'] ?? '',
      course: map['course'] ?? map['courseName'] ?? 'Not Enrolled',
      department: map['department'] ?? map['faculty'] ?? '',
      totalFees: (map['totalFees'] ?? map['semesterFee'] ?? 60000).toDouble(),
      paidFees: (map['paidFees'] ?? 0).toDouble(),
      pendingFees: _calculatePendingFees(
        map['totalFees'] ?? map['semesterFee'] ?? 60000,
        map['paidFees'] ?? 0,
      ),
      temporaryPassword: map['temporaryPassword'],
      isSynced: true,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  static double _calculatePendingFees(dynamic total, dynamic paid) {
    final totalFees = (total ?? 60000).toDouble();
    final paidFees = (paid ?? 0).toDouble();
    final pending = totalFees - paidFees;
    return pending < 0 ? 0 : pending;
  }

  // ✅ Copy with method
  LocalStudentModel copyWith({
    int? id,
    String? uid,
    String? displayName,
    String? regNumber,
    String? email,
    String? course,
    String? department,
    double? totalFees,
    double? paidFees,
    double? pendingFees,
    String? temporaryPassword,
    bool? isSynced,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return LocalStudentModel(
      id: id ?? this.id,
      uid: uid ?? this.uid,
      displayName: displayName ?? this.displayName,
      regNumber: regNumber ?? this.regNumber,
      email: email ?? this.email,
      course: course ?? this.course,
      department: department ?? this.department,
      totalFees: totalFees ?? this.totalFees,
      paidFees: paidFees ?? this.paidFees,
      pendingFees: pendingFees ?? this.pendingFees,
      temporaryPassword: temporaryPassword ?? this.temporaryPassword,
      isSynced: isSynced ?? this.isSynced,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
