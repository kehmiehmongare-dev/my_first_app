import 'package:cloud_firestore/cloud_firestore.dart';

class StudentModel {
  final String uid;
  final String displayName;
  final String regNumber;
  final String email;
  final String course;
  final String department;
  final double attendanceRate;
  final double totalFees;
  final double paidFees;
  final double pendingFees;
  final List<String> registeredUnits;
  final bool unitsRegistered;
  final DateTime createdAt;
  final DateTime updatedAt;

  StudentModel({
    required this.uid,
    required this.displayName,
    required this.regNumber,
    required this.email,
    required this.course,
    required this.department,
    required this.attendanceRate,
    required this.totalFees,
    required this.paidFees,
    required this.pendingFees,
    required this.registeredUnits,
    required this.unitsRegistered,
    required this.createdAt,
    required this.updatedAt,
  });

  int get registeredUnitsCount => registeredUnits.length;

  factory StudentModel.fromMap(Map<String, dynamic> map, String uid) {
    return StudentModel(
      uid: uid,
      displayName: map['displayName'] ?? 'Student',
      regNumber: map['regNumber'] ?? 'STU001',
      email: map['email'] ?? '',
      course: map['course'] ?? map['courseName'] ?? 'Not Enrolled',
      department: map['department'] ?? map['faculty'] ?? '',
      attendanceRate: (map['attendanceRate'] ?? 0).toDouble(),
      totalFees: (map['totalFees'] ?? map['semesterFee'] ?? 60000).toDouble(),
      paidFees: (map['paidFees'] ?? 0).toDouble(),
      pendingFees: _calculatePendingFees(
        map['totalFees'] ?? map['semesterFee'] ?? 60000,
        map['paidFees'] ?? 0,
      ),
      registeredUnits: _parseRegisteredUnits(map['registeredUnits']),
      unitsRegistered: map['unitsRegistered'] ?? false,
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

  static List<String> _parseRegisteredUnits(dynamic units) {
    if (units == null) return [];
    if (units is List) {
      if (units.isNotEmpty && units[0] is String) {
        return List<String>.from(units);
      } else if (units.isNotEmpty && units[0] is Map) {
        return units
            .map((e) => e['code']?.toString() ?? '')
            .where((e) => e.isNotEmpty)
            .toList();
      }
    }
    return [];
  }

  StudentModel copyWith({
    String? displayName,
    String? regNumber,
    String? email,
    String? course,
    String? department,
    double? attendanceRate,
    double? totalFees,
    double? paidFees,
    List<String>? registeredUnits,
    bool? unitsRegistered,
  }) {
    return StudentModel(
      uid: uid,
      displayName: displayName ?? this.displayName,
      regNumber: regNumber ?? this.regNumber,
      email: email ?? this.email,
      course: course ?? this.course,
      department: department ?? this.department,
      attendanceRate: attendanceRate ?? this.attendanceRate,
      totalFees: totalFees ?? this.totalFees,
      paidFees: paidFees ?? this.paidFees,
      pendingFees: pendingFees,
      registeredUnits: registeredUnits ?? this.registeredUnits,
      unitsRegistered: unitsRegistered ?? this.unitsRegistered,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}
