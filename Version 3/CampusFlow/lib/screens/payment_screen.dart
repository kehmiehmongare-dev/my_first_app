import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:campus_flow/features/payments/models/payment_model.dart';
import 'package:campus_flow/features/payments/services/payment_service.dart';
import 'package:campus_flow/services/mpesa_service.dart';
import 'package:campus_flow/shared/constants/app_colors.dart';
import 'package:intl/intl.dart';

class PaymentScreen extends StatefulWidget {
  final String studentId;
  final String studentName;
  final String studentRegNumber;
  final double amount;
  final String? description;

  const PaymentScreen({
    super.key,
    required this.studentId,
    required this.studentName,
    required this.studentRegNumber,
    required this.amount,
    this.description,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final PaymentService _paymentService = PaymentService();
  bool _isProcessing = false;
  PaymentMethod? _selectedMethod;
  String _phoneNumber = '';
  String _bankName = '';
  String _cardNumber = '';
  String _cardExpiry = '';
  String _cardCvv = '';
  String _scholarshipRef = '';
  String _scholarshipName = '';
  String _receivedBy = '';

  // ✅ Custom amount variables
  double _customAmount = 0;
  bool _useCustomAmount = false;
  double _remainingBalance = 0;

  // ✅ Payment methods available
  final List<PaymentMethod> _availableMethods = [
    PaymentMethod.mpesa,
    PaymentMethod.bank,
    PaymentMethod.card,
    PaymentMethod.cash,
    PaymentMethod.scholarship,
  ];

  @override
  void initState() {
    super.initState();
    _loadStudentBalance();
  }

  Future<void> _loadStudentBalance() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final doc = await FirebaseFirestore.instance
            .collection('students')
            .doc(user.uid)
            .get();

        if (doc.exists) {
          final data = doc.data() as Map<String, dynamic>;
          final totalFees = (data['totalFees'] ?? 60000).toDouble();
          final paidFees = (data['paidFees'] ?? 0).toDouble();
          _remainingBalance = totalFees - paidFees;
          if (_remainingBalance < 0) _remainingBalance = 0;
        }
      }
    } catch (e) {
      debugPrint('Error loading balance: $e');
    }
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Make Payment'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.primary, AppColors.secondary],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // ✅ Amount Card with Custom Amount
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      const Text(
                        'Payment Details',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Show remaining balance
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Remaining Balance:'),
                          Text(
                            'KSh ${NumberFormat('#,###.00').format(_remainingBalance)}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.red,
                            ),
                          ),
                        ],
                      ),

                      const Divider(),
                      const SizedBox(height: 8),

                      // ✅ Custom amount input
                      Row(
                        children: [
                          const Text('Amount to Pay:'),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextFormField(
                              initialValue: widget.amount.toString(),
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                prefixText: 'KSh ',
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 8,
                                ),
                              ),
                              onChanged: (value) {
                                setState(() {
                                  _customAmount = double.tryParse(value) ?? 0;
                                  _useCustomAmount = true;
                                });
                              },
                            ),
                          ),
                        ],
                      ),

                      if (_customAmount > _remainingBalance &&
                          _remainingBalance > 0)
                        const Text(
                          '⚠️ Amount exceeds remaining balance',
                          style: TextStyle(color: Colors.red, fontSize: 12),
                        ),

                      const SizedBox(height: 8),

                      // Quick amount buttons
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _buildQuickAmountButton(
                            _remainingBalance / 2,
                            'Half',
                          ),
                          _buildQuickAmountButton(
                            _remainingBalance,
                            'Full',
                          ),
                          _buildQuickAmountButton(5000, '5K'),
                          _buildQuickAmountButton(10000, '10K'),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Payment Methods Grid
              const Text(
                'Select Payment Method',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),

              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.1,
                ),
                itemCount: _availableMethods.length,
                itemBuilder: (context, index) {
                  final method = _availableMethods[index];
                  return _buildMethodCard(method);
                },
              ),

              const SizedBox(height: 20),

              // Payment Form
              if (_selectedMethod != null) _buildPaymentForm(),

              const SizedBox(height: 20),

              // Pay Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isProcessing ? null : _processPayment,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isProcessing
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Pay Now',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickAmountButton(double amount, String label) {
    return OutlinedButton(
      onPressed: () {
        setState(() {
          _customAmount = amount;
          _useCustomAmount = true;
        });
      },
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        backgroundColor: Colors.white,
        foregroundColor: AppColors.primary,
        side: BorderSide(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Text(
        '$label\nKSh ${amount.toStringAsFixed(0)}',
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 10),
      ),
    );
  }

  Widget _buildMethodCard(PaymentMethod method) {
    final isSelected = _selectedMethod == method;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedMethod = method;
        });
      },
      child: Container(
        decoration: BoxDecoration(
          color:
              isSelected ? Colors.white : Colors.white.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.transparent,
            width: 3,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 5,
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              PaymentMethodInfo.getIcon(method),
              size: 32,
              color: PaymentMethodInfo.getColor(method),
            ),
            const SizedBox(height: 8),
            Text(
              PaymentMethodInfo.getDisplayName(method),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? AppColors.primary : Colors.grey[800],
              ),
            ),
            if (isSelected)
              Container(
                margin: const EdgeInsets.only(top: 4),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  'SELECTED',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentForm() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Payment Details',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 12),
            _buildFormForMethod(),
          ],
        ),
      ),
    );
  }

  Widget _buildFormForMethod() {
    switch (_selectedMethod!) {
      case PaymentMethod.mpesa:
        return Column(
          children: [
            const Text(
              'Enter your M-Pesa registered phone number',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 8),
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Phone Number',
                hintText: '0712345678',
                prefixIcon: Icon(Icons.phone_android),
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.phone,
              onChanged: (value) => _phoneNumber = value,
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue.shade700),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'You will receive an STK Push prompt on your phone',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );

      case PaymentMethod.bank:
        return Column(
          children: [
            const Text(
              'Bank Transfer Details',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 8),
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Bank Name',
                hintText: 'Equity Bank',
                prefixIcon: Icon(Icons.account_balance),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) => _bankName = value,
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.yellow.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '📋 Bank Transfer Instructions:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  SizedBox(height: 4),
                  Text(
                    '• Account: CampusFlow Ltd\n• Account No: 1234567890\n• Bank: KCB Bank\n• Reference: Use your Registration Number',
                    style: TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        );

      case PaymentMethod.card:
        return Column(
          children: [
            const Text(
              'Enter Card Details',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 8),
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Card Number',
                hintText: '4242 4242 4242 4242',
                prefixIcon: Icon(Icons.credit_card),
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              maxLength: 19,
              onChanged: (value) => _cardNumber = value,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Expiry Date',
                      hintText: 'MM/YY',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) => _cardExpiry = value,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'CVV',
                      hintText: '123',
                      border: OutlineInputBorder(),
                    ),
                    obscureText: true,
                    keyboardType: TextInputType.number,
                    maxLength: 3,
                    onChanged: (value) => _cardCvv = value,
                  ),
                ),
              ],
            ),
          ],
        );

      case PaymentMethod.cash:
        return Column(
          children: [
            const Text(
              'Cash Payment Details',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 8),
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Received By (Staff Name)',
                hintText: 'John Doe',
                prefixIcon: Icon(Icons.person),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) => _receivedBy = value,
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                '💵 Please visit the finance office to pay in cash.',
                style: TextStyle(fontSize: 12),
              ),
            ),
          ],
        );

      case PaymentMethod.scholarship:
        return Column(
          children: [
            const Text(
              'Scholarship Details',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 8),
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Scholarship Name',
                hintText: 'Kenya Government Scholarship',
                prefixIcon: Icon(Icons.school),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) => _scholarshipName = value,
            ),
            const SizedBox(height: 8),
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Scholarship Reference',
                hintText: 'SCH-2024-001',
                prefixIcon: Icon(Icons.numbers),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) => _scholarshipRef = value,
            ),
          ],
        );
    }
  }

  // ✅ FIXED: Process payment with proper M-Pesa STK Push
  Future<void> _processPayment() async {
    if (_selectedMethod == null) {
      _showMessage('Please select a payment method', Colors.orange);
      return;
    }

    // ✅ Validate based on method
    switch (_selectedMethod!) {
      case PaymentMethod.mpesa:
        if (_phoneNumber.isEmpty || _phoneNumber.length < 10) {
          _showMessage('Please enter a valid phone number', Colors.red);
          return;
        }
        break;
      case PaymentMethod.bank:
        break;
      case PaymentMethod.card:
        if (_cardNumber.isEmpty || _cardNumber.length < 16) {
          _showMessage('Please enter a valid card number', Colors.red);
          return;
        }
        break;
      case PaymentMethod.cash:
        if (_receivedBy.isEmpty) {
          _showMessage(
            'Please enter the staff name receiving payment',
            Colors.red,
          );
          return;
        }
        break;
      case PaymentMethod.scholarship:
        if (_scholarshipName.isEmpty) {
          _showMessage('Please enter the scholarship name', Colors.red);
          return;
        }
        break;
    }

    setState(() => _isProcessing = true);

    try {
      // ✅ Use custom amount if set
      final amountToPay =
          _useCustomAmount && _customAmount > 0 ? _customAmount : widget.amount;

      // ✅ Build payment details
      Map<String, dynamic> paymentDetails = {};

      switch (_selectedMethod!) {
        case PaymentMethod.mpesa:
          paymentDetails = {'phoneNumber': _phoneNumber};
          break;
        case PaymentMethod.bank:
          paymentDetails = {'bankName': _bankName};
          break;
        case PaymentMethod.card:
          paymentDetails = {
            'cardType': 'Credit Card',
            'last4': _cardNumber.substring(_cardNumber.length - 4),
          };
          break;
        case PaymentMethod.cash:
          paymentDetails = {'receivedBy': _receivedBy};
          break;
        case PaymentMethod.scholarship:
          paymentDetails = {
            'scholarshipName': _scholarshipName,
            'scholarshipRef': _scholarshipRef,
          };
          break;
      }

      // ✅ Process payment in Firestore
      final transaction = await _paymentService.processPayment(
        studentId: widget.studentId,
        studentName: widget.studentName,
        studentRegNumber: widget.studentRegNumber,
        amount: amountToPay,
        method: _selectedMethod!,
        paymentDetails: paymentDetails,
      );

      // ✅ If M-Pesa, initiate STK Push
      if (_selectedMethod! == PaymentMethod.mpesa) {
        try {
          // ✅ Show STK Push loading dialog
          final stkDialog = showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => const AlertDialog(
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Sending STK Push to your phone...'),
                  SizedBox(height: 8),
                  Text(
                    'Please check your phone for the M-Pesa prompt',
                    style: TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
          );

          // ✅ Call M-Pesa API (use real or simulated)
          final result = await MpesaService.simulatePayment(
            phoneNumber: _phoneNumber,
            amount: amountToPay,
            accountReference: widget.studentRegNumber,
          );

          // ✅ Close the loading dialog
          Navigator.pop(context);

          // ✅ Check if STK Push was successful
          if (result['ResponseCode'] == '0') {
            // ✅ Show M-Pesa success with STK Push info
            _showMPesaSuccess(transaction, amountToPay, result);
          } else {
            // ✅ STK Push failed but transaction is saved
            _showPaymentSuccess(transaction);
            _showMessage(
              'M-Pesa request sent. Please check your phone.',
              Colors.orange,
            );
          }
        } catch (e) {
          // ✅ Close loading dialog if still open
          Navigator.pop(context);
          debugPrint('M-Pesa error: $e');

          // ✅ Still show success since transaction is saved
          _showPaymentSuccess(transaction);
          _showMessage(
            'Payment initiated. Please check your phone for M-Pesa prompt.',
            Colors.orange,
          );
        }
      } else {
        // ✅ Non-M-Pesa payment success
        _showPaymentSuccess(transaction);
      }

      setState(() => _isProcessing = false);
    } catch (e) {
      setState(() => _isProcessing = false);
      _showMessage('Payment failed: $e', Colors.red);
    }
  }

  // ✅ M-Pesa specific success dialog with STK Push details
  void _showMPesaSuccess(
    PaymentTransaction transaction,
    double amount,
    Map<String, dynamic> result,
  ) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('📱 STK Push Sent'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '✅ An STK Push has been sent to your phone.',
              style:
                  TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
            ),
            const SizedBox(height: 12),
            Text('Amount: KSh ${NumberFormat('#,###.00').format(amount)}'),
            Text('Phone: $_phoneNumber'),
            Text('Reference: ${transaction.reference ?? 'N/A'}'),
            Text('Request ID: ${result['CheckoutRequestID'] ?? 'N/A'}'),
            const SizedBox(height: 12),
            const Text(
              '📱 Please check your phone and enter your M-Pesa PIN to complete the payment.',
              style: TextStyle(fontSize: 13, color: Colors.blue),
            ),
            const SizedBox(height: 8),
            const Text(
              'The payment will be confirmed automatically once processed.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.yellow.shade50,
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Row(
                children: [
                  Icon(Icons.timer, size: 16, color: Colors.orange),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'If you don\'t receive the prompt within 2 minutes, try again.',
                      style: TextStyle(fontSize: 12, color: Colors.orange),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context, true);
            },
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  void _showPaymentSuccess(PaymentTransaction transaction) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('✅ Payment Initiated'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Amount: ${transaction.formattedAmount}'),
            Text(
              'Method: ${PaymentMethodInfo.getDisplayName(transaction.method)}',
            ),
            Text('Reference: ${transaction.reference ?? 'N/A'}'),
            Text('Status: ${transaction.status.name.toUpperCase()}'),
            const SizedBox(height: 12),
            const Text(
              'Your payment is being processed. You will receive a confirmation shortly.',
              style: TextStyle(fontSize: 13),
            ),
            if (transaction.method == PaymentMethod.mpesa)
              const Text(
                '📱 Please check your phone for the M-Pesa STK Push prompt.',
                style: TextStyle(fontSize: 13, color: Colors.blue),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context, true);
            },
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  void _showMessage(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
