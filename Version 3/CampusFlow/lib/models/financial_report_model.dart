class FinancialReport {
  final String id;
  final String reportType; // 'daily', 'weekly', 'monthly', 'yearly'
  final DateTime startDate;
  final DateTime endDate;
  final double totalCollected;
  final double totalPending;
  final double totalOverdue;
  final double totalRefunded;
  final int totalTransactions;
  final Map<String, double> paymentMethodBreakdown;
  final List<TransactionSummary> transactions;

  FinancialReport({
    required this.id,
    required this.reportType,
    required this.startDate,
    required this.endDate,
    required this.totalCollected,
    required this.totalPending,
    required this.totalOverdue,
    required this.totalRefunded,
    required this.totalTransactions,
    required this.paymentMethodBreakdown,
    required this.transactions,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'reportType': reportType,
    'startDate': startDate.toIso8601String(),
    'endDate': endDate.toIso8601String(),
    'totalCollected': totalCollected,
    'totalPending': totalPending,
    'totalOverdue': totalOverdue,
    'totalRefunded': totalRefunded,
    'totalTransactions': totalTransactions,
    'paymentMethodBreakdown': paymentMethodBreakdown,
    'transactions': transactions.map((t) => t.toJson()).toList(),
  };

  factory FinancialReport.fromJson(Map<String, dynamic> json) => FinancialReport(
    id: json['id'],
    reportType: json['reportType'],
    startDate: DateTime.parse(json['startDate']),
    endDate: DateTime.parse(json['endDate']),
    totalCollected: json['totalCollected'],
    totalPending: json['totalPending'],
    totalOverdue: json['totalOverdue'],
    totalRefunded: json['totalRefunded'],
    totalTransactions: json['totalTransactions'],
    paymentMethodBreakdown: json['paymentMethodBreakdown'],
    transactions: (json['transactions'] as List)
        .map((t) => TransactionSummary.fromJson(t))
        .toList(),
  );
}

class TransactionSummary {
  final String transactionId;
  final String studentId;
  final String studentName;
  final String studentRegNumber;
  final double amount;
  final String method;
  final String status;
  final DateTime date;
  final String? reference;

  TransactionSummary({
    required this.transactionId,
    required this.studentId,
    required this.studentName,
    required this.studentRegNumber,
    required this.amount,
    required this.method,
    required this.status,
    required this.date,
    this.reference,
  });

  Map<String, dynamic> toJson() => {
    'transactionId': transactionId,
    'studentId': studentId,
    'studentName': studentName,
    'studentRegNumber': studentRegNumber,
    'amount': amount,
    'method': method,
    'status': status,
    'date': date.toIso8601String(),
    'reference': reference,
  };

  factory TransactionSummary.fromJson(Map<String, dynamic> json) => TransactionSummary(
    transactionId: json['transactionId'],
    studentId: json['studentId'],
    studentName: json['studentName'],
    studentRegNumber: json['studentRegNumber'],
    amount: json['amount'],
    method: json['method'],
    status: json['status'],
    date: DateTime.parse(json['date']),
    reference: json['reference'],
  );
}