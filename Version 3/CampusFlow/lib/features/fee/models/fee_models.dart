import 'package:intl/intl.dart';

// ==================== FEE BREAKDOWN ====================
class FeeBreakdown {
  final String name;
  final double amount;
  final double percentage;

  FeeBreakdown({
    required this.name,
    required this.amount,
    required this.percentage,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'amount': amount,
        'percentage': percentage,
      };

  factory FeeBreakdown.fromJson(Map<String, dynamic> json) => FeeBreakdown(
        name: json['name'],
        amount: json['amount'],
        percentage: json['percentage'],
      );
}

// ==================== FEE STRUCTURE ====================
class FeeStructure {
  final String id;
  final String courseId;
  final String semester;
  final double amount;
  final List<FeeBreakdown> breakdown;
  final DateTime validFrom;
  final DateTime validTo;

  FeeStructure({
    required this.id,
    required this.courseId,
    required this.semester,
    required this.amount,
    required this.breakdown,
    required this.validFrom,
    required this.validTo,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'courseId': courseId,
        'semester': semester,
        'amount': amount,
        'breakdown': breakdown.map((b) => b.toJson()).toList(),
        'validFrom': validFrom.toIso8601String(),
        'validTo': validTo.toIso8601String(),
      };

  factory FeeStructure.fromJson(Map<String, dynamic> json) => FeeStructure(
        id: json['id'],
        courseId: json['courseId'],
        semester: json['semester'],
        amount: json['amount'],
        breakdown: (json['breakdown'] as List)
            .map((b) => FeeBreakdown.fromJson(b))
            .toList(),
        validFrom: DateTime.parse(json['validFrom']),
        validTo: DateTime.parse(json['validTo']),
      );
}

// ==================== FEE ACCOUNT (Per student per semester) ====================
class FeeAccount {
  final String id;
  final String studentId;
  final String studentName;
  final String semester;
  final double totalFee;
  final double amountPaid;
  final double creditBalance;
  final double pendingBalance;
  final String status;
  final DateTime dueDate;
  final DateTime createdAt;
  final DateTime updatedAt;

  FeeAccount({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.semester,
    required this.totalFee,
    required this.amountPaid,
    required this.creditBalance,
    required this.pendingBalance,
    required this.status,
    required this.dueDate,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'studentId': studentId,
        'studentName': studentName,
        'semester': semester,
        'totalFee': totalFee,
        'amountPaid': amountPaid,
        'creditBalance': creditBalance,
        'pendingBalance': pendingBalance,
        'status': status,
        'dueDate': dueDate.toIso8601String(),
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory FeeAccount.fromJson(Map<String, dynamic> json) => FeeAccount(
        id: json['id'],
        studentId: json['studentId'],
        studentName: json['studentName'],
        semester: json['semester'],
        totalFee: json['totalFee'],
        amountPaid: json['amountPaid'],
        creditBalance: json['creditBalance'],
        pendingBalance: json['pendingBalance'],
        status: json['status'],
        dueDate: DateTime.parse(json['dueDate']),
        createdAt: DateTime.parse(json['createdAt']),
        updatedAt: DateTime.parse(json['updatedAt']),
      );

  String get formattedTotalFee => NumberFormat('#,###.00').format(totalFee);
  String get formattedPendingBalance =>
      NumberFormat('#,###.00').format(pendingBalance);
  String get formattedAmountPaid => NumberFormat('#,###.00').format(amountPaid);
  String get formattedCreditBalance =>
      NumberFormat('#,###.00').format(creditBalance);
}

// ==================== PAYMENT STATUS ====================
enum PaymentStatus {
  pending,
  completed,
  failed,
  cancelled,
}

// ==================== PAYMENT METHOD ====================
enum PaymentMethod {
  mpesa,
  card,
  bank,
  cash,
}

// ==================== PAYMENT TRANSACTION ====================
class PaymentTransaction {
  final String id;
  final String studentId;
  final String studentName;
  final String semester;
  final double amount;
  final PaymentMethod method;
  final PaymentStatus status;
  final String? reference;
  final String? confirmationCode;
  final String? phoneNumber;
  final DateTime date;
  final String? notes;

  PaymentTransaction({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.semester,
    required this.amount,
    required this.method,
    required this.status,
    this.reference,
    this.confirmationCode,
    this.phoneNumber,
    required this.date,
    this.notes,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'studentId': studentId,
        'studentName': studentName,
        'semester': semester,
        'amount': amount,
        'method': method.name,
        'status': status.name,
        'reference': reference,
        'confirmationCode': confirmationCode,
        'phoneNumber': phoneNumber,
        'date': date.toIso8601String(),
        'notes': notes,
      };

  factory PaymentTransaction.fromJson(Map<String, dynamic> json) =>
      PaymentTransaction(
        id: json['id'],
        studentId: json['studentId'],
        studentName: json['studentName'],
        semester: json['semester'],
        amount: json['amount'],
        method:
            PaymentMethod.values.firstWhere((e) => e.name == json['method']),
        status:
            PaymentStatus.values.firstWhere((e) => e.name == json['status']),
        reference: json['reference'],
        confirmationCode: json['confirmationCode'],
        phoneNumber: json['phoneNumber'],
        date: DateTime.parse(json['date']),
        notes: json['notes'],
      );

  String get formattedAmount => NumberFormat('#,###.00').format(amount);
  String get formattedDate => DateFormat('dd/MM/yyyy HH:mm').format(date);
}

// ==================== CREDIT BALANCE ====================
class CreditBalance {
  final String id;
  final String studentId;
  final double amount;
  final String reason;
  final DateTime dateCreated;
  final DateTime? dateUsed;
  final String? usedFor;

  CreditBalance({
    required this.id,
    required this.studentId,
    required this.amount,
    required this.reason,
    required this.dateCreated,
    this.dateUsed,
    this.usedFor,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'studentId': studentId,
        'amount': amount,
        'reason': reason,
        'dateCreated': dateCreated.toIso8601String(),
        'dateUsed': dateUsed?.toIso8601String(),
        'usedFor': usedFor,
      };

  factory CreditBalance.fromJson(Map<String, dynamic> json) => CreditBalance(
        id: json['id'],
        studentId: json['studentId'],
        amount: json['amount'],
        reason: json['reason'],
        dateCreated: DateTime.parse(json['dateCreated']),
        dateUsed:
            json['dateUsed'] != null ? DateTime.parse(json['dateUsed']) : null,
        usedFor: json['usedFor'],
      );
}
