import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:campus_flow/shared/constants/app_colors.dart';
import 'package:intl/intl.dart';

class AdminReportsScreen extends StatefulWidget {
  const AdminReportsScreen({super.key});

  @override
  State<AdminReportsScreen> createState() => _AdminReportsScreenState();
}

class _AdminReportsScreenState extends State<AdminReportsScreen> {
  bool _isLoading = true;
  final Map<String, dynamic> _stats = {};
  List<Map<String, dynamic>> _attendanceTrend = [];

  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  Future<void> _loadReports() async {
    // ✅ Only setState if mounted
    if (mounted) {
      setState(() => _isLoading = true);
    }

    try {
      // Get total students - from students collection
      final studentsSnapshot =
          await FirebaseFirestore.instance.collection('students').get();
      _stats['totalStudents'] = studentsSnapshot.docs.length;

      // Get total lecturers - from lecturers collection
      final lecturersSnapshot =
          await FirebaseFirestore.instance.collection('lecturers').get();
      _stats['totalLecturers'] = lecturersSnapshot.docs.length;

      // Get total courses
      final coursesSnapshot =
          await FirebaseFirestore.instance.collection('courses').get();
      _stats['totalCourses'] = coursesSnapshot.docs.length;

      // Get attendance stats for last 7 days
      final today = DateTime.now();
      final weekAgo = today.subtract(const Duration(days: 7));

      final snapshot = await FirebaseFirestore.instance
          .collection('attendance')
          .where('timestamp',
              isGreaterThanOrEqualTo: Timestamp.fromDate(weekAgo))
          .get();

      final records = snapshot.docs;
      _stats['totalAttendance'] = records.length;

      // Calculate attendance rate
      final present = records.where((doc) => doc['status'] == 'present').length;
      _stats['attendanceRate'] =
          records.isNotEmpty ? (present / records.length) * 100 : 0;

      // Group by day
      final Map<String, int> dailyCount = {};
      for (var doc in records) {
        final date = (doc['timestamp'] as Timestamp).toDate();
        final key = DateFormat('MMM dd').format(date);
        dailyCount[key] = (dailyCount[key] ?? 0) + 1;
      }

      _attendanceTrend = dailyCount.entries
          .map((e) => {'day': e.key, 'count': e.value})
          .toList();
    } catch (e) {
      debugPrint('Error loading reports: $e');
    }

    // ✅ Only setState if mounted
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadReports,
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
                            'Students',
                            '${_stats['totalStudents'] ?? 0}',
                            Icons.people,
                            Colors.blue,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildSummaryCard(
                            'Lecturers',
                            '${_stats['totalLecturers'] ?? 0}',
                            Icons.school,
                            Colors.green,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _buildSummaryCard(
                            'Courses',
                            '${_stats['totalCourses'] ?? 0}',
                            Icons.menu_book,
                            Colors.orange,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildSummaryCard(
                            'Attendance',
                            '${_stats['totalAttendance'] ?? 0}',
                            Icons.trending_up,
                            Colors.purple,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Attendance Rate
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            const Text(
                              'Attendance Rate',
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            SizedBox(
                              height: 100,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  CircularProgressIndicator(
                                    value:
                                        (_stats['attendanceRate'] ?? 0) / 100,
                                    strokeWidth: 12,
                                    backgroundColor: Colors.grey[200],
                                    valueColor:
                                        const AlwaysStoppedAnimation<Color>(
                                            AppColors.primary),
                                  ),
                                  Column(
                                    children: [
                                      Text(
                                        '${(_stats['attendanceRate'] ?? 0).toStringAsFixed(1)}%',
                                        style: const TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const Text('Overall'),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Attendance Trend
                    if (_attendanceTrend.isNotEmpty) ...[
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              const Text(
                                'Attendance Trend (Last 7 Days)',
                                style: TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 12),
                              ..._attendanceTrend.map((item) {
                                return Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 4),
                                  child: Row(
                                    children: [
                                      SizedBox(
                                        width: 60,
                                        child: Text(item['day']),
                                      ),
                                      Expanded(
                                        child: LinearProgressIndicator(
                                          value: (item['count'] as int) / 20,
                                          backgroundColor: Colors.grey[200],
                                          color: AppColors.primary,
                                          minHeight: 8,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text('${item['count']}'),
                                    ],
                                  ),
                                );
                              }),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildSummaryCard(
      String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                  fontSize: 20, fontWeight: FontWeight.bold, color: color),
            ),
            Text(title,
                style: TextStyle(fontSize: 11, color: Colors.grey[600])),
          ],
        ),
      ),
    );
  }
}
