import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:campus_flow/features/payments/models/payment_model.dart';
import 'package:campus_flow/features/payments/services/payment_service.dart';

class PaymentDialog extends StatefulWidget {
  final double totalFee;
  final double amountPaid;
  final String studentId;
  final String studentName;
  final String studentRegNumber;

  const PaymentDialog({
    super.key,
    required this.totalFee,
    required this.amountPaid,
    required this.studentId,
    required this.studentName,
    required this.studentRegNumber,
  });

  @override
  State<PaymentDialog> createState() => _PaymentDialogState();
}

class _PaymentDialogState extends State<PaymentDialog> {
  final PaymentService _paymentService = PaymentService();
  PaymentMethod _selectedMethod = PaymentMethod.mpesa;
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _bankNameController = TextEditingController();
  final TextEditingController _cardNumberController = TextEditingController();
  final TextEditingController _cardExpiryController = TextEditingController();
  final TextEditingController _cardCvvController = TextEditingController();
  final TextEditingController _scholarshipRefController =
      TextEditingController();
  final TextEditingController _scholarshipNameController =
      TextEditingController();
  final TextEditingController _receivedByController = TextEditingController();

  bool _isProcessing = false;
  double get _pendingBalance => widget.totalFee - widget.amountPaid;

  @override
  void initState() {
    super.initState();
    _amountController.text = _pendingBalance.toString();
  }

  Future<void> _processPayment() async {
    final amount = double.tryParse(_amountController.text) ?? 0;
    if (amount <= 0 || amount > _pendingBalance) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid amount'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Validate based on method
    switch (_selectedMethod) {
      case PaymentMethod.mpesa:
        if (_phoneController.text.length < 9) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please enter a valid phone number'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
        break;
      case PaymentMethod.card:
        if (_cardNumberController.text.length < 16) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please enter a valid card number'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
        break;
      case PaymentMethod.bank:
        if (_bankNameController.text.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please enter bank name'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
        break;
      case PaymentMethod.scholarship:
        if (_scholarshipRefController.text.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please enter scholarship reference'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
        break;
      case PaymentMethod.cash:
        if (_receivedByController.text.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please enter who received the payment'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
        break;
    }

    setState(() => _isProcessing = true);

    try {
      Map<String, dynamic> paymentDetails = {};

      switch (_selectedMethod) {
        case PaymentMethod.mpesa:
          paymentDetails = {'phoneNumber': _phoneController.text};
          break;
        case PaymentMethod.bank:
          paymentDetails = {'bankName': _bankNameController.text};
          break;
        case PaymentMethod.card:
          paymentDetails = {
            'cardType': 'Card',
            'last4': _cardNumberController.text
                .substring(_cardNumberController.text.length - 4),
          };
          break;
        case PaymentMethod.cash:
          paymentDetails = {'receivedBy': _receivedByController.text};
          break;
        case PaymentMethod.scholarship:
          paymentDetails = {
            'scholarshipRef': _scholarshipRefController.text,
            'scholarshipName': _scholarshipNameController.text,
          };
          break;
      }

      final transaction = await _paymentService.processPayment(
        studentId: widget.studentId,
        studentName: widget.studentName,
        studentRegNumber: widget.studentRegNumber,
        amount: amount,
        method: _selectedMethod,
        paymentDetails: paymentDetails,
      );

      // Show success message
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('✅ Payment of ${transaction.formattedAmount} initiated!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('❌ Payment failed: $e'),
              backgroundColor: Colors.red),
        );
      }
    }

    setState(() => _isProcessing = false);
  }

  @override
  Widget build(BuildContext context) {
    final pending = _pendingBalance;

    return AlertDialog(
      title: const Text('💳 Make Payment'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Balance info
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total Fee:'),
                      Text(
                        'KSh ${NumberFormat('#,###').format(widget.totalFee)}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Pending:'),
                      Text(
                        'KSh ${NumberFormat('#,###').format(pending)}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: pending > 0 ? Colors.red : Colors.green,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Payment Method Selection
            const Text(
              'Select Payment Method',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: PaymentMethod.values.map((method) {
                final isSelected = _selectedMethod == method;
                return ChoiceChip(
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        PaymentMethodInfo.getIcon(method),
                        size: 16,
                        color: isSelected
                            ? Colors.white
                            : PaymentMethodInfo.getColor(method),
                      ),
                      const SizedBox(width: 4),
                      Text(PaymentMethodInfo.getDisplayName(method)),
                    ],
                  ),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() => _selectedMethod = method);
                    }
                  },
                  selectedColor: PaymentMethodInfo.getColor(method),
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : Colors.black87,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // Method-specific fields
            _buildMethodFields(),
            const SizedBox(height: 8),

            // Amount field
            TextField(
              controller: _amountController,
              decoration: const InputDecoration(
                labelText: 'Amount (KSh)',
                border: OutlineInputBorder(),
                prefixText: 'KSh ',
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isProcessing ? null : _processPayment,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
          ),
          child: _isProcessing
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2),
                )
              : const Text('Pay Now'),
        ),
      ],
    );
  }

  Widget _buildMethodFields() {
    switch (_selectedMethod) {
      case PaymentMethod.mpesa:
        return TextField(
          controller: _phoneController,
          decoration: const InputDecoration(
            labelText: 'M-Pesa Phone Number',
            border: OutlineInputBorder(),
            prefixText: '+254 ',
            hintText: 'e.g., 712345678',
          ),
          keyboardType: TextInputType.phone,
        );

      case PaymentMethod.bank:
        return Column(
          children: [
            TextField(
              controller: _bankNameController,
              decoration: const InputDecoration(
                labelText: 'Bank Name',
                border: OutlineInputBorder(),
                hintText: 'e.g., KCB Bank',
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '📋 Bank Transfer Details',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 4),
                  Text('Bank: KCB Bank', style: TextStyle(fontSize: 12)),
                  Text('Account: 1234567890', style: TextStyle(fontSize: 12)),
                  Text('Name: Campus Flow Ltd', style: TextStyle(fontSize: 12)),
                  Text('Reference: Your Registration Number',
                      style: TextStyle(fontSize: 12)),
                ],
              ),
            ),
          ],
        );

      case PaymentMethod.card:
        return Column(
          children: [
            TextField(
              controller: _cardNumberController,
              decoration: const InputDecoration(
                labelText: 'Card Number',
                border: OutlineInputBorder(),
                hintText: '1234 5678 9012 3456',
              ),
              keyboardType: TextInputType.number,
              maxLength: 16,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _cardExpiryController,
                    decoration: const InputDecoration(
                      labelText: 'Expiry (MM/YY)',
                      border: OutlineInputBorder(),
                      hintText: '12/25',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _cardCvvController,
                    decoration: const InputDecoration(
                      labelText: 'CVV',
                      border: OutlineInputBorder(),
                      hintText: '123',
                    ),
                    obscureText: true,
                    maxLength: 4,
                  ),
                ),
              ],
            ),
          ],
        );

      case PaymentMethod.cash:
        return Column(
          children: [
            TextField(
              controller: _receivedByController,
              decoration: const InputDecoration(
                labelText: 'Received By (Name)',
                border: OutlineInputBorder(),
                hintText: 'Finance Officer Name',
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info, color: Colors.orange),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Cash payments must be confirmed by the finance office',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );

      case PaymentMethod.scholarship:
        return Column(
          children: [
            TextField(
              controller: _scholarshipRefController,
              decoration: const InputDecoration(
                labelText: 'Scholarship Reference',
                border: OutlineInputBorder(),
                hintText: 'e.g., SCH-2024-001',
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _scholarshipNameController,
              decoration: const InputDecoration(
                labelText: 'Scholarship Name',
                border: OutlineInputBorder(),
                hintText: 'e.g., Government Scholarship',
              ),
            ),
          ],
        );
    }
  }
}
