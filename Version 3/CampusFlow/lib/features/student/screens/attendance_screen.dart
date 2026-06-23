import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:campus_flow/shared/constants/app_colors.dart';
import 'package:intl/intl.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  List<Map<String, dynamic>> _attendanceRecords = [];
  List<Map<String, dynamic>> _unitAttendance = [];
  Map<String, dynamic> _overallStats = {};
  bool _isLoading = true;

  final int totalWeeks = 14;
  final int classesPerWeek = 1;

  @override
  void initState() {
    super.initState();
    _loadAttendance();
  }

  Future<void> _loadAttendance() async {
    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final snapshot = await FirebaseFirestore.instance
            .collection('attendance')
            .where('studentId', isEqualTo: user.uid)
            .get();

        _attendanceRecords = snapshot.docs.map((doc) {
          final data = doc.data();
          data['id'] = doc.id;
          return data;
        }).toList();

        _calculateUnitAttendance();
        _calculateOverallStats();
      }
    } catch (e) {
      debugPrint('Error loading attendance: $e');
    }

    setState(() => _isLoading = false);
  }

  void _calculateUnitAttendance() {
    final Map<String, List<Map<String, dynamic>>> unitMap = {};

    for (var record in _attendanceRecords) {
      final courseCode = record['courseCode'] ?? 'General';
      if (!unitMap.containsKey(courseCode)) {
        unitMap[courseCode] = [];
      }
      unitMap[courseCode]!.add(record);
    }

    _unitAttendance = unitMap.entries.map((entry) {
      final records = entry.value;
      final total = records.length;
      final present = records.where((r) => r['status'] == 'present').length;
      final absent = records.where((r) => r['status'] == 'absent').length;
      final late = records.where((r) => r['status'] == 'late').length;
      final percentage = total > 0 ? (present / total) * 100 : 0;

      return {
        'courseCode': entry.key,
        'total': total,
        'present': present,
        'absent': absent,
        'late': late,
        'percentage': percentage,
        'status': percentage >= 75
            ? 'Good'
            : percentage >= 60
                ? 'At Risk'
                : 'Critical',
      };
    }).toList();

    _unitAttendance.sort((a, b) =>
        (b['percentage'] as double).compareTo(a['percentage'] as double));
  }

  void _calculateOverallStats() {
    final total = _attendanceRecords.length;
    final present =
        _attendanceRecords.where((r) => r['status'] == 'present').length;
    final absent =
        _attendanceRecords.where((r) => r['status'] == 'absent').length;
    final late = _attendanceRecords.where((r) => r['status'] == 'late').length;
    final excused =
        _attendanceRecords.where((r) => r['status'] == 'excused').length;

    final percentage = total > 0 ? (present / total) * 100 : 0;

    final currentWeek = _getCurrentWeek();
    final totalClasses = currentWeek * classesPerWeek * _unitAttendance.length;
    final classesRemaining = totalClasses - total;
    final classesNeededToQualify = (total * 0.75 - present).ceil();
    final classesRemainingToQualify =
        classesNeededToQualify > 0 ? classesNeededToQualify : 0;

    String status;
    if (percentage >= 75) {
      status = 'Good Standing ✅';
    } else if (percentage >= 60) {
      status = 'At Risk ⚠️';
    } else if (percentage > 0) {
      status = 'Critical ❌';
    } else {
      status = 'No Records 📌';
    }

    _overallStats = {
      'total': total,
      'present': present,
      'absent': absent,
      'late': late,
      'excused': excused,
      'percentage': percentage,
      'classesRemaining': classesRemaining > 0 ? classesRemaining : 0,
      'classesNeededToQualify': classesRemainingToQualify,
      'status': status,
      'isQualified': percentage >= 75,
      'isAtRisk': percentage >= 60 && percentage < 75,
      'isCritical': percentage < 60 && percentage > 0,
      'hasRecords': total > 0,
    };
  }

  int _getCurrentWeek() {
    final startDate = DateTime(DateTime.now().year, 5, 1);
    final diff = DateTime.now().difference(startDate);
    final week = (diff.inDays / 7).ceil();
    return week.clamp(1, 14);
  }

  String _getStatusIcon(String status) {
    switch (status) {
      case 'present':
        return '✅';
      case 'absent':
        return '❌';
      case 'late':
        return '⏰';
      case 'excused':
        return '📋';
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
      case 'excused':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Attendance'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
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
                    _buildOverallStats(),
                    const SizedBox(height: 16),
                    _buildUnitAttendance(),
                    const SizedBox(height: 16),
                    _buildAttendanceChart(),
                    const SizedBox(height: 16),
                    _buildHistory(),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildOverallStats() {
    final hasRecords = _overallStats['hasRecords'] ?? false;
    final percentage = _overallStats['percentage'] ?? 0.0;
    final status = _overallStats['status'] ?? 'No Records';
    final total = _overallStats['total'] ?? 0;
    final present = _overallStats['present'] ?? 0;
    final absent = _overallStats['absent'] ?? 0;
    final late = _overallStats['late'] ?? 0;
    final classesNeeded = _overallStats['classesNeededToQualify'] ?? 0;

    Color statusColor;
    if (percentage >= 75) {
      statusColor = Colors.green;
    } else if (percentage >= 60) {
      statusColor = Colors.orange;
    } else {
      statusColor = Colors.red;
    }

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text(
              '📊 Attendance Overview',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                SizedBox(
                  width: 120,
                  height: 120,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CircularProgressIndicator(
                        value: hasRecords ? percentage / 100 : 0,
                        strokeWidth: 12,
                        backgroundColor: Colors.grey[200],
                        valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            hasRecords
                                ? '${percentage.toStringAsFixed(1)}%'
                                : 'N/A',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: statusColor,
                            ),
                          ),
                          Text(
                            status,
                            style: TextStyle(
                              fontSize: 12,
                              color: statusColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (hasRecords) ...[
                        Text('📚 Total Classes: $total'),
                        Text('✅ Present: $present'),
                        Text('❌ Absent: $absent'),
                        Text('⏰ Late: $late'),
                        if (classesNeeded > 0)
                          Text(
                            '🎯 Need $classesNeeded more classes to qualify for exams',
                            style: TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        if (percentage >= 75)
                          const Text(
                            '✅ You are qualified for exams!',
                            style: TextStyle(
                                color: Colors.green,
                                fontWeight: FontWeight.bold),
                          ),
                      ] else ...[
                        const Text(
                          'No attendance records yet',
                          style: TextStyle(color: Colors.grey),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Your lecturer will mark attendance for you',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUnitAttendance() {
    if (_unitAttendance.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Center(
            child: Text(
              'No unit attendance data available',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
        ),
      );
    }

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '📋 Unit-wise Attendance',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ..._unitAttendance.map((unit) {
              final percentage = unit['percentage'] as double;
              final status = unit['status'] as String;
              Color color;
              if (percentage >= 75) {
                color = Colors.green;
              } else if (percentage >= 60) {
                color = Colors.orange;
              } else {
                color = Colors.red;
              }

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Column(
                  children: [
                    Row(
                      children: [
                        SizedBox(
                          width: 80,
                          child: Text(
                            unit['courseCode'],
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              LinearProgressIndicator(
                                value: percentage / 100,
                                backgroundColor: Colors.grey[200],
                                color: color,
                                minHeight: 8,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${unit['present']}/${unit['total']} present (${percentage.toStringAsFixed(0)}%)',
                                style: TextStyle(
                                    fontSize: 11, color: Colors.grey[600]),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            status,
                            style: TextStyle(
                                color: color,
                                fontSize: 10,
                                fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildAttendanceChart() {
    if (_attendanceRecords.isEmpty) {
      return const SizedBox.shrink();
    }

    final Map<int, int> weeklyPresent = {};
    final Map<int, int> weeklyTotal = {};

    for (var record in _attendanceRecords) {
      final date = DateTime.parse(record['date']);
      final week =
          ((date.difference(DateTime(DateTime.now().year, 5, 1)).inDays / 7)
                  .ceil())
              .clamp(1, 14);
      weeklyTotal[week] = (weeklyTotal[week] ?? 0) + 1;
      if (record['status'] == 'present') {
        weeklyPresent[week] = (weeklyPresent[week] ?? 0) + 1;
      }
    }

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '📈 Weekly Attendance Trend',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _getCurrentWeek(),
                itemBuilder: (context, index) {
                  final week = index + 1;
                  final present = weeklyPresent[week] ?? 0;
                  final total = weeklyTotal[week] ?? 0;
                  final percentage = total > 0 ? (present / total) * 100 : 0;
                  final color = percentage >= 75
                      ? Colors.green
                      : percentage >= 60
                          ? Colors.orange
                          : Colors.red;

                  return Container(
                    width: 30,
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    child: Column(
                      children: [
                        Expanded(
                          child: Align(
                            alignment: Alignment.bottomCenter,
                            child: Container(
                              height:
                                  percentage > 0 ? (percentage / 100) * 80 : 0,
                              width: 20,
                              decoration: BoxDecoration(
                                color: color,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'W$week',
                          style:
                              TextStyle(fontSize: 10, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _legendItem(Colors.green, 'Good (75%+)'),
                _legendItem(Colors.orange, 'At Risk (60-74%)'),
                _legendItem(Colors.red, 'Critical (<60%)'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _legendItem(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
              color: color, borderRadius: BorderRadius.circular(2)),
        ),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 10, color: Colors.grey[600])),
      ],
    );
  }

  Widget _buildHistory() {
    if (_attendanceRecords.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '📜 Recent Attendance',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ..._attendanceRecords.take(5).map((record) {
              final date = DateTime.parse(record['date']);
              final status = record['status'] ?? 'absent';
              final courseCode = record['courseCode'] ?? 'General';

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Text(
                      _getStatusIcon(status),
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '$courseCode - ${DateFormat('MMM dd, yyyy').format(date)}',
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: _getStatusColor(status).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        status.toUpperCase(),
                        style: TextStyle(
                          color: _getStatusColor(status),
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
