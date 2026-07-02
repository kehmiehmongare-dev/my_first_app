import 'package:flutter/material.dart';
import 'package:campus_flow/models/student_model.dart';
import 'package:campus_flow/services/database_service.dart';
import 'package:intl/intl.dart';

class AttendanceScreen extends StatefulWidget {
  final Student student;
  const AttendanceScreen({super.key, required this.student});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  List<Map<String, dynamic>> _attendanceRecords = [];
  bool _isLoading = true;
  double _overallPercentage = 0;
  Map<String, dynamic> _stats = {};

  @override
  void initState() {
    super.initState();
    _loadAttendance();
  }

  Future<void> _loadAttendance() async {
    setState(() => _isLoading = true);

    _attendanceRecords =
        await DatabaseService.getStudentAttendanceRecords(widget.student.id);
    _overallPercentage =
        await DatabaseService.getOverallAttendance(widget.student.id);
    _stats = await DatabaseService.getAttendanceStats(widget.student.id);

    setState(() => _isLoading = false);
  }

  String _getStatusIcon(String status) {
    switch (status) {
      case 'present':
        return '✅';
      case 'absent':
        return '❌';
      case 'late':
        return '⏰';
      default:
        return '📌';
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'present':
        return Colors.green;
      case 'absent':
        return Colors.red;
      case 'late':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Attendance'),
        backgroundColor: const Color(0xFF667eea),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadAttendance,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            const Text(
                              'Overall Attendance',
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 16),
                            Stack(
                              alignment: Alignment.center,
                              children: [
                                SizedBox(
                                  width: 150,
                                  height: 150,
                                  child: CircularProgressIndicator(
                                    value: _overallPercentage / 100,
                                    strokeWidth: 12,
                                    backgroundColor: Colors.grey.shade200,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      _overallPercentage >= 75
                                          ? Colors.green
                                          : _overallPercentage >= 60
                                              ? Colors.orange
                                              : Colors.red,
                                    ),
                                  ),
                                ),
                                Column(
                                  children: [
                                    Text(
                                      '${_overallPercentage.toStringAsFixed(1)}%',
                                      style: const TextStyle(
                                          fontSize: 28,
                                          fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _overallPercentage >= 75
                                          ? 'Good Standing'
                                          : _overallPercentage >= 60
                                              ? 'At Risk'
                                              : _overallPercentage == 0
                                                  ? 'No Records'
                                                  : 'Critical',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: _overallPercentage >= 75
                                            ? Colors.green
                                            : _overallPercentage >= 60
                                                ? Colors.orange
                                                : Colors.red,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _buildStatItem('Present',
                                    _stats['present'] ?? 0, Colors.green),
                                _buildStatItem('Absent', _stats['absent'] ?? 0,
                                    Colors.red),
                                _buildStatItem(
                                    'Late', _stats['late'] ?? 0, Colors.orange),
                                _buildStatItem(
                                    'Total', _stats['total'] ?? 0, Colors.blue),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Attendance History',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '${_attendanceRecords.length} records',
                          style:
                              TextStyle(color: Colors.grey[600], fontSize: 12),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (_attendanceRecords.isEmpty)
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(40),
                          child: Column(
                            children: [
                              const Icon(Icons.history,
                                  size: 64, color: Colors.grey),
                              const SizedBox(height: 16),
                              Text(
                                'No attendance records yet',
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Your attendance will appear here once marked',
                                style: TextStyle(
                                    color: Colors.grey[500], fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _attendanceRecords.length,
                        itemBuilder: (context, index) {
                          final record = _attendanceRecords[index];
                          final date = DateTime.parse(record['date']);
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor:
                                    _getStatusColor(record['status'])
                                        .withValues(alpha: 0.1),
                                child: Text(
                                  _getStatusIcon(record['status']),
                                  style: const TextStyle(fontSize: 20),
                                ),
                              ),
                              title: Text(record['courseCode']),
                              subtitle: Text(
                                  DateFormat('EEEE, MMM d, yyyy').format(date)),
                              trailing: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: _getStatusColor(record['status'])
                                      .withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  record['status'].toUpperCase(),
                                  style: TextStyle(
                                    color: _getStatusColor(record['status']),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildStatItem(String label, int count, Color color) {
    return Column(
      children: [
        Text(
          '$count',
          style: TextStyle(
              fontSize: 20, fontWeight: FontWeight.bold, color: color),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
      ],
    );
  }
}
