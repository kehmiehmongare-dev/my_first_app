import 'package:flutter/material.dart';
import 'package:campus_flow/features/payments/screens/payment_screen.dart';

class PaymentButton extends StatelessWidget {
  final String studentId;
  final String studentName;
  final String studentRegNumber;
  final double amount;
  final String? description;

  const PaymentButton({
    super.key,
    required this.studentId,
    required this.studentName,
    required this.studentRegNumber,
    required this.amount,
    this.description,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PaymentScreen(
              studentId: studentId,
              studentName: studentName,
              studentRegNumber: studentRegNumber,
              amount: amount,
              description: description,
            ),
          ),
        );
      },
      icon: const Icon(Icons.payment),
      label: const Text('Make Payment'),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.green,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      ),
    );
  }
}
