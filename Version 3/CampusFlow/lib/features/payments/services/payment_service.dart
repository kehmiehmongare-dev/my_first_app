import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:campus_flow/features/payments/models/payment_model.dart';

class PaymentService {
  static final PaymentService _instance = PaymentService._internal();
  factory PaymentService() => _instance;
  PaymentService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ✅ Generate simple ID instead of using uuid
  String _generateId() {
    return 'pay_${DateTime.now().millisecondsSinceEpoch}_${DateTime.now().microsecondsSinceEpoch}';
  }

  // ✅ Process payment with selected method
  Future<PaymentTransaction> processPayment({
    required String studentId,
    required String studentName,
    required String studentRegNumber,
    required double amount,
    required PaymentMethod method,
    required Map<String, dynamic> paymentDetails,
  }) async {
    String? reference;
    String? description;

    switch (method) {
      case PaymentMethod.mpesa:
        final result = await _processMpesaPayment(
          phoneNumber: paymentDetails['phoneNumber'],
          amount: amount,
          accountReference: studentRegNumber,
        );
        reference = result['CheckoutRequestID'];
        description = 'M-Pesa Payment';
        break;

      case PaymentMethod.bank:
        reference = _generateBankReference();
        description = 'Bank Transfer - ${paymentDetails['bankName'] ?? 'N/A'}';
        break;

      case PaymentMethod.card:
        reference = _generateCardReference();
        description = 'Card Payment - ${paymentDetails['cardType'] ?? 'Card'}';
        break;

      case PaymentMethod.cash:
        reference = _generateCashReference();
        description =
            'Cash Payment - Received by ${paymentDetails['receivedBy'] ?? 'Admin'}';
        break;

      case PaymentMethod.scholarship:
        reference =
            paymentDetails['scholarshipRef'] ?? _generateScholarshipReference();
        description =
            'Scholarship - ${paymentDetails['scholarshipName'] ?? 'N/A'}';
        break;
    }

    final transaction = PaymentTransaction(
      id: _generateId(),
      studentId: studentId,
      studentName: studentName,
      studentRegNumber: studentRegNumber,
      amount: amount,
      method: method,
      status: PaymentStatus.pending,
      date: DateTime.now(),
      reference: reference,
      description: description,
      metadata: paymentDetails,
    );

    await _saveTransaction(transaction);
    return transaction;
  }

  // ✅ M-Pesa Payment
  Future<Map<String, dynamic>> _processMpesaPayment({
    required String phoneNumber,
    required double amount,
    required String accountReference,
  }) async {
    // Simulate M-Pesa processing
    await Future.delayed(const Duration(seconds: 2));
    return {
      'CheckoutRequestID': 'MPESA_${DateTime.now().millisecondsSinceEpoch}',
      'ResponseCode': '0',
      'ResponseDescription': 'Success. Request accepted for processing',
    };
  }

  // ✅ Generate references for different methods
  String _generateBankReference() =>
      'BNK_${DateTime.now().millisecondsSinceEpoch}';
  String _generateCardReference() =>
      'CRD_${DateTime.now().millisecondsSinceEpoch}';
  String _generateCashReference() =>
      'CSH_${DateTime.now().millisecondsSinceEpoch}';
  String _generateScholarshipReference() =>
      'SCH_${DateTime.now().millisecondsSinceEpoch}';

  // ✅ Confirm payment (for bank/cash manual confirmation)
  Future<void> confirmPayment(String transactionId) async {
    await _firestore.collection('payments').doc(transactionId).update({
      'status': PaymentStatus.completed.name,
      'confirmedAt': FieldValue.serverTimestamp(),
    });
  }

  // ✅ Refund payment
  Future<void> refundPayment(String transactionId) async {
    await _firestore.collection('payments').doc(transactionId).update({
      'status': PaymentStatus.refunded.name,
      'refundedAt': FieldValue.serverTimestamp(),
    });
  }

  // ✅ Get transactions by student
  Future<List<PaymentTransaction>> getStudentTransactions(
      String studentId) async {
    final snapshot = await _firestore
        .collection('payments')
        .where('studentId', isEqualTo: studentId)
        .orderBy('date', descending: true)
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return PaymentTransaction.fromJson(data);
    }).toList();
  }

  // ✅ Get all transactions (admin)
  Future<List<PaymentTransaction>> getAllTransactions() async {
    final snapshot = await _firestore
        .collection('payments')
        .orderBy('date', descending: true)
        .limit(100)
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return PaymentTransaction.fromJson(data);
    }).toList();
  }

  // ✅ Get transactions by method
  Future<List<PaymentTransaction>> getTransactionsByMethod(
      PaymentMethod method) async {
    final snapshot = await _firestore
        .collection('payments')
        .where('method', isEqualTo: method.name)
        .orderBy('date', descending: true)
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return PaymentTransaction.fromJson(data);
    }).toList();
  }

  // ✅ Save transaction
  Future<void> _saveTransaction(PaymentTransaction transaction) async {
    await _firestore
        .collection('payments')
        .doc(transaction.id)
        .set(transaction.toJson());
  }
}
