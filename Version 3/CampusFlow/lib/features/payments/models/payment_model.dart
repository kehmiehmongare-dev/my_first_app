import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

enum PaymentMethod {
  mpesa,
  bank,
  card,
  cash,
  scholarship,
}

enum PaymentStatus {
  pending,
  completed,
  failed,
  refunded,
  cancelled,
}

class PaymentMethodInfo {
  static String getDisplayName(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.mpesa:
        return 'M-Pesa';
      case PaymentMethod.bank:
        return 'Bank Transfer';
      case PaymentMethod.card:
        return 'Credit/Debit Card';
      case PaymentMethod.cash:
        return 'Cash';
      case PaymentMethod.scholarship:
        return 'Scholarship';
    }
  }

  static IconData getIcon(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.mpesa:
        return Icons.phone_android;
      case PaymentMethod.bank:
        return Icons.account_balance;
      case PaymentMethod.card:
        return Icons.credit_card;
      case PaymentMethod.cash:
        return Icons.money;
      case PaymentMethod.scholarship:
        return Icons.school;
    }
  }

  static Color getColor(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.mpesa:
        return Colors.green;
      case PaymentMethod.bank:
        return Colors.blue;
      case PaymentMethod.card:
        return Colors.purple;
      case PaymentMethod.cash:
        return Colors.orange;
      case PaymentMethod.scholarship:
        return Colors.teal;
    }
  }
}

class PaymentTransaction {
  final String id;
  final String studentId;
  final String studentName;
  final String studentRegNumber;
  final double amount;
  final PaymentMethod method;
  final PaymentStatus status;
  final DateTime date;
  final String? reference;
  final String? description;
  final Map<String, dynamic>? metadata;

  PaymentTransaction({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.studentRegNumber,
    required this.amount,
    required this.method,
    required this.status,
    required this.date,
    this.reference,
    this.description,
    this.metadata,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'studentId': studentId,
        'studentName': studentName,
        'studentRegNumber': studentRegNumber,
        'amount': amount,
        'method': method.name,
        'status': status.name,
        'date': date.toIso8601String(),
        'reference': reference,
        'description': description,
        'metadata': metadata,
      };

  factory PaymentTransaction.fromJson(Map<String, dynamic> json) =>
      PaymentTransaction(
        id: json['id'],
        studentId: json['studentId'],
        studentName: json['studentName'],
        studentRegNumber: json['studentRegNumber'],
        amount: json['amount'],
        method:
            PaymentMethod.values.firstWhere((e) => e.name == json['method']),
        status:
            PaymentStatus.values.firstWhere((e) => e.name == json['status']),
        date: DateTime.parse(json['date']),
        reference: json['reference'],
        description: json['description'],
        metadata: json['metadata'],
      );

  String get formattedAmount =>
      'KSh ${NumberFormat('#,###.00').format(amount)}';
  String get formattedDate => DateFormat('dd/MM/yyyy HH:mm').format(date);
}
