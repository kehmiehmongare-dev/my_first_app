import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:campus_flow/shared/constants/app_colors.dart';
import 'package:intl/intl.dart';
import 'package:campus_flow/services/mpesa_service.dart';

class FeesScreen extends StatefulWidget {
  const FeesScreen({super.key});

  @override
  State<FeesScreen> createState() => _FeesScreenState();
}

class _FeesScreenState extends State<FeesScreen> {
  Map<String, dynamic> _feeData = {};
  List<Map<String, dynamic>> _transactions = [];
  bool _isLoading = true;
  bool _hasUnits = false;

  @override
  void initState() {
    super.initState();
    _loadFees();
  }

  Future<void> _loadFees() async {
    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Check if units are registered
        final studentDoc = await FirebaseFirestore.instance
            .collection('students')
            .doc(user.uid)
            .get();

        if (studentDoc.exists) {
          final data = studentDoc.data() as Map<String, dynamic>;
          _hasUnits = data['unitsRegistered'] ?? false;
        }

        // Get fee data
        if (_hasUnits) {
          final feeDoc = await FirebaseFirestore.instance
              .collection('fees')
              .doc(user.uid)
              .get();

          if (feeDoc.exists) {
            _feeData = feeDoc.data() as Map<String, dynamic>;
          } else {
            _feeData = {
              'totalFee': 60000,
              'amountPaid': 0,
              'pendingBalance': 60000,
              'status': 'pending',
            };
          }

          // Get transactions
          final txSnapshot = await FirebaseFirestore.instance
              .collection('payments')
              .where('studentId', isEqualTo: user.uid)
              .orderBy('date', descending: true)
              .get();

          _transactions = txSnapshot.docs.map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            return data;
          }).toList();
        }
      }
    } catch (e) {
      debugPrint('Error loading fees: $e');
    }

    setState(() => _isLoading = false);
  }

// Update _makePayment method
  Future<void> _makePayment() async {
    final TextEditingController phoneController = TextEditingController();
    final TextEditingController amountController = TextEditingController(
      text: (_feeData['pendingBalance'] ?? 0).toString(),
    );

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) {
          bool isProcessing = false;

          return AlertDialog(
            title: const Text('💳 M-Pesa Payment'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Total Fee:'),
                          Text(
                            'KSh ${NumberFormat('#,###').format(_feeData['totalFee'] ?? 0)}',
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
                            'KSh ${NumberFormat('#,###').format(_feeData['pendingBalance'] ?? 0)}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.red,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: phoneController,
                  decoration: const InputDecoration(
                    labelText: 'M-Pesa Phone Number',
                    border: OutlineInputBorder(),
                    prefixText: '+254 ',
                    hintText: 'e.g., 712345678',
                  ),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: amountController,
                  decoration: const InputDecoration(
                    labelText: 'Amount (KSh)',
                    border: OutlineInputBorder(),
                    prefixText: 'KSh ',
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 8),
                const Text(
                  'You will receive a prompt on your phone',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: isProcessing
                    ? null
                    : () async {
                        final phone = phoneController.text;
                        final amount =
                            double.tryParse(amountController.text) ?? 0;

                        if (phone.isEmpty || amount <= 0) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content:
                                  Text('Please enter valid phone and amount'),
                              backgroundColor: Colors.red,
                            ),
                          );
                          return;
                        }

                        setStateDialog(() => isProcessing = true);

                        try {
                          final user = FirebaseAuth.instance.currentUser;
                          final studentDoc = await FirebaseFirestore.instance
                              .collection('students')
                              .doc(user?.uid)
                              .get();
                          final studentData =
                              studentDoc.data() as Map<String, dynamic>;

                          // Simulate M-Pesa payment
                          final result = await MpesaService.simulatePayment(
                            phoneNumber: phone,
                            amount: amount,
                            accountReference:
                                studentData['regNumber'] ?? 'STU001',
                          );

                          // Save transaction
                          await MpesaService.saveTransaction(
                            studentId: user?.uid ?? '',
                            studentName:
                                studentData['displayName'] ?? 'Student',
                            studentRegNumber:
                                studentData['regNumber'] ?? 'STU001',
                            amount: amount,
                            method: 'M-Pesa',
                            status: 'completed',
                            reference: result['CheckoutRequestID'],
                          );

                          // Update fee account
                          await _updateFeeAfterPayment(amount);

                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                  '✅ Payment of KSh ${NumberFormat('#,###').format(amount)} successful!'),
                              backgroundColor: Colors.green,
                            ),
                          );
                          await _loadFees();
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text('❌ Payment failed: $e'),
                                backgroundColor: Colors.red),
                          );
                        } finally {
                          setStateDialog(() => isProcessing = false);
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                ),
                child: isProcessing
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
        },
      ),
    );
  }

// Add this method to update fee after payment
  Future<void> _updateFeeAfterPayment(double amount) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      final doc = await FirebaseFirestore.instance
          .collection('fees')
          .doc(user?.uid)
          .get();

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        final amountPaid = (data['amountPaid'] ?? 0) + amount;
        final pendingBalance = (data['totalFee'] ?? 0) - amountPaid;

        await FirebaseFirestore.instance
            .collection('fees')
            .doc(user?.uid)
            .update({
          'amountPaid': amountPaid,
          'pendingBalance': pendingBalance,
          'status': pendingBalance <= 0 ? 'paid' : 'partial',
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      debugPrint('Error updating fee: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalFee = (_feeData['totalFee'] ?? 0).toDouble();
    final amountPaid = (_feeData['amountPaid'] ?? 0).toDouble();
    final pendingBalance = (_feeData['pendingBalance'] ?? 0).toDouble();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Fees Management'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadFees,
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.primary, AppColors.secondary],
          ),
        ),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : !_hasUnits
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.warning_amber_rounded,
                          size: 64,
                          color: Colors.orange,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'No Units Registered',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Register units first to see your fee',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: () {
                            // Navigate to unit registration
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                          ),
                          child: const Text('Register Units'),
                        ),
                      ],
                    ),
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        // Fee Summary Card
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              children: [
                                const Text(
                                  'Fee Summary',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text('Total Fee:'),
                                    Text(
                                      'KSh ${NumberFormat('#,###').format(totalFee)}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                const Divider(),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text('Amount Paid:'),
                                    Text(
                                      'KSh ${NumberFormat('#,###').format(amountPaid)}',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green,
                                      ),
                                    ),
                                  ],
                                ),
                                const Divider(),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'Pending Balance:',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      'KSh ${NumberFormat('#,###').format(pendingBalance)}',
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: pendingBalance > 0
                                            ? Colors.red
                                            : Colors.green,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                if (pendingBalance > 0)
                                  SizedBox(
                                    width: double.infinity,
                                    height: 45,
                                    child: ElevatedButton(
                                      onPressed: _makePayment,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.green,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                      ),
                                      child: const Text(
                                        'Pay Now',
                                        style: TextStyle(fontSize: 16),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Fee Breakdown
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Fee Breakdown',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                _feeBreakdownItem(
                                    'Tuition Fee', totalFee * 0.7, '70%'),
                                _feeBreakdownItem(
                                    'Registration Fee', totalFee * 0.1, '10%'),
                                _feeBreakdownItem(
                                    'Library Fee', totalFee * 0.05, '5%'),
                                _feeBreakdownItem(
                                    'ICT Fee', totalFee * 0.1, '10%'),
                                _feeBreakdownItem(
                                    'Activity Fee', totalFee * 0.05, '5%'),
                                const Divider(),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'Total',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold),
                                    ),
                                    Text(
                                      'KSh ${NumberFormat('#,###').format(totalFee)}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Transaction History
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Transaction History',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                if (_transactions.isEmpty)
                                  const Center(
                                    child: Padding(
                                      padding: EdgeInsets.all(20),
                                      child: Text('No transactions yet'),
                                    ),
                                  )
                                else
                                  ..._transactions.map((tx) {
                                    final date =
                                        (tx['date'] as Timestamp).toDate();
                                    return ListTile(
                                      leading: CircleAvatar(
                                        backgroundColor: Colors.green,
                                        child: const Icon(
                                          Icons.check,
                                          color: Colors.white,
                                        ),
                                      ),
                                      title: Text(tx['method'] ?? 'M-Pesa'),
                                      subtitle: Text(
                                        DateFormat('dd/MM/yyyy').format(date),
                                      ),
                                      trailing: Text(
                                        'KSh ${NumberFormat('#,###').format(tx['amount'] ?? 0)}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.green,
                                        ),
                                      ),
                                    );
                                  }),
                                if (_transactions.length > 3)
                                  TextButton(
                                    onPressed: () {},
                                    child: Text(
                                      'View All ${_transactions.length} Transactions',
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
      ),
    );
  }

  Widget _feeBreakdownItem(String label, double amount, String percentage) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 14)),
              Text(
                percentage,
                style: TextStyle(fontSize: 11, color: Colors.grey[600]),
              ),
            ],
          ),
          Text(
            'KSh ${NumberFormat('#,###').format(amount)}',
            style: const TextStyle(fontSize: 14),
          ),
        ],
      ),
    );
  }
}
