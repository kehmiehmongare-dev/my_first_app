import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:campus_flow/shared/constants/app_colors.dart';
import 'package:intl/intl.dart';

class FeesScreen extends StatefulWidget {
  const FeesScreen({super.key});

  @override
  State<FeesScreen> createState() => _FeesScreenState();
}

class _FeesScreenState extends State<FeesScreen> {
  Map<String, dynamic> _feeData = {};
  List<Map<String, dynamic>> _transactions = [];
  bool _isLoading = true;

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
        // Get fee data from Firestore
        final feeDoc = await FirebaseFirestore.instance
            .collection('fees')
            .doc(user.uid)
            .get();

        if (feeDoc.exists) {
          _feeData = feeDoc.data() as Map<String, dynamic>;
        } else {
          // Default fee data if none exists
          _feeData = {
            'totalFee': 60000,
            'amountPaid': 0,
            'pendingBalance': 60000,
            'status': 'pending',
          };
        }

        // Get transactions from Firestore
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
    } catch (e) {
      debugPrint('Error loading fees: $e');
    }

    setState(() => _isLoading = false);
  }

  Future<void> _makePayment() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('💳 Make Payment'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Total Fee: KSh ${NumberFormat('#,###').format(_feeData['totalFee'] ?? 0)}',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              'Pending: KSh ${NumberFormat('#,###').format(_feeData['pendingBalance'] ?? 0)}',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 16),
            const TextField(
              decoration: InputDecoration(
                labelText: 'M-Pesa Phone Number',
                border: OutlineInputBorder(),
                prefixText: '+254 ',
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 8),
            const TextField(
              decoration: InputDecoration(
                labelText: 'Amount (KSh)',
                border: OutlineInputBorder(),
                prefixText: 'KSh ',
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('✅ Payment initiated! Check your M-Pesa.'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
            ),
            child: const Text('Pay Now'),
          ),
        ],
      ),
    );
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
                                  fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Total Fee:'),
                                Text(
                                  'KSh ${NumberFormat('#,###').format(totalFee)}',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            const Divider(),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Pending Balance:',
                                  style: TextStyle(fontWeight: FontWeight.bold),
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
                                      borderRadius: BorderRadius.circular(10),
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
                                  fontSize: 16, fontWeight: FontWeight.bold),
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
                                final date = (tx['date'] as Timestamp).toDate();
                                return ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: Colors.green,
                                    child: const Icon(Icons.check,
                                        color: Colors.white),
                                  ),
                                  title: Text(tx['method'] ?? 'M-Pesa'),
                                  subtitle: Text(
                                      DateFormat('dd/MM/yyyy').format(date)),
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
                                    'View All ${_transactions.length} Transactions'),
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
}
