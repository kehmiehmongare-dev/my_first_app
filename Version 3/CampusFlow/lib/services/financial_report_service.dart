import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:campus_flow/models/financial_report_model.dart';

class FinancialReportService {
  static final FinancialReportService _instance =
      FinancialReportService._internal();
  factory FinancialReportService() => _instance;
  FinancialReportService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ✅ Generate a financial report
  Future<FinancialReport> generateReport({
    required String reportType,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    // Get all payments in date range
    final paymentsSnapshot = await _firestore
        .collection('payments')
        .where('date', isGreaterThanOrEqualTo: startDate)
        .where('date', isLessThanOrEqualTo: endDate)
        .get();

    final transactions = paymentsSnapshot.docs.map((doc) {
      final data = doc.data();
      return TransactionSummary(
        transactionId: doc.id,
        studentId: data['studentId'] ?? '',
        studentName: data['studentName'] ?? 'Unknown',
        studentRegNumber: data['studentRegNumber'] ?? '',
        amount: data['amount']?.toDouble() ?? 0,
        method: data['method'] ?? 'M-Pesa',
        status: data['status'] ?? 'completed',
        date: data['date'] != null
            ? (data['date'] as Timestamp).toDate()
            : DateTime.now(),
        reference: data['reference'],
      );
    }).toList();

    // Calculate totals
    double totalCollected = 0;
    double totalPending = 0;
    double totalOverdue = 0;
    double totalRefunded = 0;
    Map<String, double> paymentMethodBreakdown = {};

    for (var tx in transactions) {
      if (tx.status == 'completed') {
        totalCollected += tx.amount;
        paymentMethodBreakdown[tx.method] =
            (paymentMethodBreakdown[tx.method] ?? 0) + tx.amount;
      } else if (tx.status == 'pending') {
        totalPending += tx.amount;
      } else if (tx.status == 'overdue') {
        totalOverdue += tx.amount;
      } else if (tx.status == 'refunded') {
        totalRefunded += tx.amount;
      }
    }

    return FinancialReport(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      reportType: reportType,
      startDate: startDate,
      endDate: endDate,
      totalCollected: totalCollected,
      totalPending: totalPending,
      totalOverdue: totalOverdue,
      totalRefunded: totalRefunded,
      totalTransactions: transactions.length,
      paymentMethodBreakdown: paymentMethodBreakdown,
      transactions: transactions,
    );
  }

  // ✅ Get overall financial summary
  Future<Map<String, dynamic>> getFinancialSummary() async {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final startOfYear = DateTime(now.year, 1, 1);

    final monthlyReport = await generateReport(
      reportType: 'monthly',
      startDate: startOfMonth,
      endDate: now,
    );

    final yearlyReport = await generateReport(
      reportType: 'yearly',
      startDate: startOfYear,
      endDate: now,
    );

    // Get overdue payments (older than 30 days)
    final overdueDate = now.subtract(const Duration(days: 30));
    final overduePayments = await _firestore
        .collection('payments')
        .where('date', isLessThan: overdueDate)
        .where('status', isEqualTo: 'pending')
        .get();

    double overdueTotal = 0;
    for (var doc in overduePayments.docs) {
      final data = doc.data();
      overdueTotal += data['amount']?.toDouble() ?? 0;
    }

    // Get total students with pending fees
    final studentsWithPending = await _firestore
        .collection('students')
        .where('pendingFees', isGreaterThan: 0)
        .get();

    return {
      'totalCollectedThisMonth': monthlyReport.totalCollected,
      'totalCollectedThisYear': yearlyReport.totalCollected,
      'pendingFees': monthlyReport.totalPending,
      'overdueFees': overdueTotal,
      'studentsWithPending': studentsWithPending.docs.length,
      'totalTransactions': monthlyReport.totalTransactions,
      'paymentMethods': monthlyReport.paymentMethodBreakdown,
      'recentTransactions': monthlyReport.transactions.take(10).toList(),
    };
  }

  // ✅ Export report to CSV
  static String exportToCsv(FinancialReport report) {
    String csv =
        'Transaction ID,Student ID,Student Name,Amount,Method,Status,Date,Reference\n';

    for (var tx in report.transactions) {
      csv +=
          '${tx.transactionId},${tx.studentId},${tx.studentName},${tx.amount},${tx.method},${tx.status},${tx.date.toIso8601String()},${tx.reference ?? ''}\n';
    }

    return csv;
  }
}
