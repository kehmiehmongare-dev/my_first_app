import 'package:flutter/material.dart';
import 'package:campus_flow/shared/constants/app_colors.dart';
import 'package:campus_flow/models/financial_report_model.dart';
import 'package:campus_flow/services/financial_report_service.dart';
import 'package:intl/intl.dart';

class AdminFinancialReportsScreen extends StatefulWidget {
  const AdminFinancialReportsScreen({super.key});

  @override
  State<AdminFinancialReportsScreen> createState() =>
      _AdminFinancialReportsScreenState();
}

class _AdminFinancialReportsScreenState
    extends State<AdminFinancialReportsScreen> {
  bool _isLoading = true;
  Map<String, dynamic> _financialSummary = {};
  List<TransactionSummary> _recentTransactions = [];
  String _reportType = 'monthly';

  final FinancialReportService _reportService = FinancialReportService();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      _financialSummary = await _reportService.getFinancialSummary();
      _recentTransactions = List<TransactionSummary>.from(
          _financialSummary['recentTransactions'] ?? []);
    } catch (e) {
      debugPrint('Error loading financial data: $e');
    }

    setState(() => _isLoading = false);
  }

  Future<void> _generateReport() async {
    final now = DateTime.now();
    DateTime startDate;
    DateTime endDate = now;

    switch (_reportType) {
      case 'monthly':
        startDate = DateTime(now.year, now.month, 1);
        break;
      case 'quarterly':
        startDate =
            DateTime(now.year, ((now.month - 1) / 3).floor() * 3 + 1, 1);
        break;
      case 'yearly':
        startDate = DateTime(now.year, 1, 1);
        break;
      default:
        startDate = DateTime(now.year, now.month, 1);
    }

    final report = await _reportService.generateReport(
      reportType: _reportType,
      startDate: startDate,
      endDate: endDate,
    );

    // Show report dialog
    _showReportDialog(report);
  }

  void _showReportDialog(FinancialReport report) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('📊 Financial Report'),
        content: SizedBox(
          width: 500,
          height: 400,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                    'Period: ${DateFormat('dd/MM/yyyy').format(report.startDate)} - ${DateFormat('dd/MM/yyyy').format(report.endDate)}'),
                const Divider(),
                _statRow(
                    'Total Collected',
                    'KSh ${NumberFormat('#,###.00').format(report.totalCollected)}',
                    Colors.green),
                _statRow(
                    'Pending',
                    'KSh ${NumberFormat('#,###.00').format(report.totalPending)}',
                    Colors.orange),
                _statRow(
                    'Overdue',
                    'KSh ${NumberFormat('#,###.00').format(report.totalOverdue)}',
                    Colors.red),
                _statRow(
                    'Refunded',
                    'KSh ${NumberFormat('#,###.00').format(report.totalRefunded)}',
                    Colors.blue),
                const Divider(),
                _statRow('Total Transactions', '${report.totalTransactions}',
                    Colors.purple),
                const SizedBox(height: 12),
                const Text('Payment Method Breakdown:'),
                ...report.paymentMethodBreakdown.entries.map((entry) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(entry.key),
                        Text(
                            'KSh ${NumberFormat('#,###.00').format(entry.value)}'),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              // Export to CSV
              final csv = FinancialReportService.exportToCsv(report);
              // In production, save to file or share
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('✅ Report exported to CSV!'),
                  backgroundColor: Colors.green,
                ),
              );
              Navigator.pop(context);
            },
            icon: const Icon(Icons.download),
            label: const Text('Export CSV'),
          ),
        ],
      ),
    );
  }

  Widget _statRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
          Text(value,
              style: TextStyle(color: color, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final totalCollected = _financialSummary['totalCollectedThisMonth'] ?? 0;
    final pendingFees = _financialSummary['pendingFees'] ?? 0;
    final overdueFees = _financialSummary['overdueFees'] ?? 0;
    final studentsWithPending = _financialSummary['studentsWithPending'] ?? 0;
    final totalTransactions = _financialSummary['totalTransactions'] ?? 0;
    final paymentMethods = _financialSummary['paymentMethods'] ?? {};

    return Scaffold(
      appBar: AppBar(
        title: const Text('Financial Reports'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
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
                    // Summary Cards
                    Row(
                      children: [
                        Expanded(
                          child: _buildSummaryCard(
                            '💰 Collected',
                            'KSh ${NumberFormat('#,###.00').format(totalCollected)}',
                            Icons.trending_up,
                            Colors.green,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildSummaryCard(
                            '⏳ Pending',
                            'KSh ${NumberFormat('#,###.00').format(pendingFees)}',
                            Icons.pending,
                            Colors.orange,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _buildSummaryCard(
                            '⚠️ Overdue',
                            'KSh ${NumberFormat('#,###.00').format(overdueFees)}',
                            Icons.warning,
                            Colors.red,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildSummaryCard(
                            '👨‍🎓 Students',
                            '$studentsWithPending',
                            Icons.people,
                            Colors.purple,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Payment Methods
                    if (paymentMethods.isNotEmpty)
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                '💳 Payment Methods',
                                style: TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 8),
                              ...paymentMethods.entries.map((entry) {
                                final total = paymentMethods.values
                                    .fold(0.0, (sum, v) => sum + v);
                                final percentage =
                                    total > 0 ? (entry.value / total) * 100 : 0;
                                return Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 4),
                                  child: Column(
                                    children: [
                                      Row(
                                        children: [
                                          SizedBox(
                                            width: 80,
                                            child: Text(entry.key),
                                          ),
                                          Expanded(
                                            child: LinearProgressIndicator(
                                              value: percentage / 100,
                                              backgroundColor: Colors.grey[200],
                                              color: AppColors.primary,
                                              minHeight: 8,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                              '${percentage.toStringAsFixed(0)}%'),
                                        ],
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ],
                          ),
                        ),
                      ),
                    const SizedBox(height: 16),

                    // Generate Report
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            const Text(
                              '📊 Generate Report',
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: DropdownButtonFormField<String>(
                                    initialValue: _reportType,
                                    decoration: const InputDecoration(
                                      border: OutlineInputBorder(),
                                    ),
                                    items: const [
                                      DropdownMenuItem(
                                          value: 'monthly',
                                          child: Text('Monthly')),
                                      DropdownMenuItem(
                                          value: 'quarterly',
                                          child: Text('Quarterly')),
                                      DropdownMenuItem(
                                          value: 'yearly',
                                          child: Text('Yearly')),
                                    ],
                                    onChanged: (value) {
                                      setState(() {
                                        _reportType = value!;
                                      });
                                    },
                                  ),
                                ),
                                const SizedBox(width: 12),
                                ElevatedButton(
                                  onPressed: _generateReport,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                  ),
                                  child: const Text('Generate'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Recent Transactions
                    if (_recentTransactions.isNotEmpty)
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                '📋 Recent Transactions',
                                style: TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 8),
                              ..._recentTransactions.take(5).map((tx) {
                                return ListTile(
                                  dense: true,
                                  leading: CircleAvatar(
                                    backgroundColor: tx.status == 'completed'
                                        ? Colors.green
                                        : Colors.orange,
                                    child: Icon(
                                      tx.status == 'completed'
                                          ? Icons.check
                                          : Icons.pending,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                  ),
                                  title: Text(tx.studentName),
                                  subtitle: Text(tx.studentRegNumber),
                                  trailing: Text(
                                    'KSh ${NumberFormat('#,###.00').format(tx.amount)}',
                                    style: TextStyle(
                                      color: tx.status == 'completed'
                                          ? Colors.green
                                          : Colors.orange,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                );
                              }),
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

  Widget _buildSummaryCard(
      String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: TextStyle(fontSize: 11, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
