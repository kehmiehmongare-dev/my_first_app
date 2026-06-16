import 'package:flutter/material.dart';
import 'package:campus_flow/models/student_model.dart';
import 'package:campus_flow/services/database_service.dart';
import 'package:campus_flow/screens/shared/login_screen.dart';
import 'package:campus_flow/screens/shared/profile_screen.dart';
import 'package:campus_flow/screens/student/attendance_screen.dart';
import 'package:campus_flow/screens/student/courses_screen.dart';
import 'package:campus_flow/screens/student/fees_screen.dart';

class StudentDashboard extends StatefulWidget {
  final Student student;
  const StudentDashboard({super.key, required this.student});

  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
  bool _isLoading = true;
  double _attendanceRate = 0;
  int _courseCount = 0;
  int _pendingFees = 0;
  int _selectedIndex = 0;
  Map<String, dynamic> _attendanceStats = {};

  final List<Widget> _screens = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      _attendanceRate =
          await DatabaseService.getOverallAttendance(widget.student.id);
      _attendanceStats =
          await DatabaseService.getAttendanceStats(widget.student.id);

      final courses =
          await DatabaseService.getStudentCourses(widget.student.id);
      _courseCount = courses.length;
      _pendingFees = await DatabaseService.getPendingFees(widget.student.id);
    } catch (e) {
      debugPrint('Error loading dashboard: $e');
    }

    setState(() => _isLoading = false);

    _screens.clear();
    _screens.addAll([
      DashboardHome(
        student: widget.student,
        attendanceRate: _attendanceRate,
        attendanceStats: _attendanceStats,
        courseCount: _courseCount,
        pendingFees: _pendingFees,
      ),
      AttendanceScreen(student: widget.student),
      CoursesScreen(student: widget.student),
      FeesScreen(student: widget.student),
      ProfileScreen(student: widget.student),
    ]);
  }

  void _logout() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Welcome, ${widget.student.firstName}'),
        backgroundColor: const Color(0xFF667eea),
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const LoginScreen()),
            );
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      drawer: Drawer(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 35,
                    backgroundColor: Colors.white,
                    child: Text(
                      widget.student.firstName[0].toUpperCase(),
                      style: const TextStyle(
                          fontSize: 32, color: Color(0xFF667eea)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    widget.student.fullName,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold),
                  ),
                  Text(
                    widget.student.regNumber,
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.dashboard, color: Color(0xFF667eea)),
              title: const Text('Dashboard'),
              selected: _selectedIndex == 0,
              onTap: () {
                setState(() => _selectedIndex = 0);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading:
                  const Icon(Icons.qr_code_scanner, color: Color(0xFF667eea)),
              title: const Text('Attendance'),
              selected: _selectedIndex == 1,
              onTap: () {
                setState(() => _selectedIndex = 1);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.menu_book, color: Color(0xFF667eea)),
              title: const Text('My Courses'),
              selected: _selectedIndex == 2,
              onTap: () {
                setState(() => _selectedIndex = 2);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.account_balance_wallet,
                  color: Color(0xFF667eea)),
              title: const Text('Fees'),
              selected: _selectedIndex == 3,
              onTap: () {
                setState(() => _selectedIndex = 3);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.person, color: Color(0xFF667eea)),
              title: const Text('Profile'),
              selected: _selectedIndex == 4,
              onTap: () {
                setState(() => _selectedIndex = 4);
                Navigator.pop(context);
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Logout', style: TextStyle(color: Colors.red)),
              onTap: _logout,
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : IndexedStack(
              index: _selectedIndex,
              children: _screens,
            ),
    );
  }
}

// Dashboard Home Widget
class DashboardHome extends StatelessWidget {
  final Student student;
  final double attendanceRate;
  final Map<String, dynamic> attendanceStats;
  final int courseCount;
  final int pendingFees;

  const DashboardHome({
    super.key,
    required this.student,
    required this.attendanceRate,
    required this.attendanceStats,
    required this.courseCount,
    required this.pendingFees,
  });

  @override
  Widget build(BuildContext context) {
    Color attendanceColor;
    String attendanceMessage;
    String attendanceSubMessage;

    if (attendanceRate == 0) {
      attendanceColor = Colors.red;
      attendanceMessage = 'No Attendance Records Yet';
      attendanceSubMessage =
          'Start marking your attendance to track your progress.';
    } else if (attendanceRate < 60) {
      attendanceColor = Colors.red;
      attendanceMessage = 'Critical: Attendance Below 60%';
      attendanceSubMessage =
          'You need to improve your attendance to sit for exams.';
    } else if (attendanceRate < 75) {
      attendanceColor = Colors.orange;
      attendanceMessage = 'Warning: Attendance Below 75%';
      attendanceSubMessage =
          'Attend ${(75 - attendanceRate).ceil()} more classes to reach 75%.';
    } else {
      attendanceColor = Colors.green;
      attendanceMessage = 'Good Standing';
      attendanceSubMessage =
          'Your attendance is above the required 75%. Keep it up!';
    }

    return RefreshIndicator(
      onRefresh: () async {},
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
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: const Color(0xFF667eea),
                      child: Text(
                        student.firstName[0].toUpperCase(),
                        style:
                            const TextStyle(fontSize: 24, color: Colors.white),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            student.fullName,
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            student.regNumber,
                            style: TextStyle(
                                color: Colors.grey[600], fontSize: 12),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF667eea)
                                  .withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              student.course,
                              style: const TextStyle(
                                  fontSize: 10, color: Color(0xFF667eea)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Attendance',
                    attendanceRate == 0
                        ? '0%'
                        : '${attendanceRate.toStringAsFixed(1)}%',
                    Icons.trending_up,
                    attendanceColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'Courses',
                    '$courseCount',
                    Icons.menu_book,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'Fees',
                    pendingFees > 0
                        ? 'KSh ${pendingFees.toStringAsFixed(0)}'
                        : 'Paid',
                    Icons.account_balance_wallet,
                    pendingFees > 0 ? Colors.red : Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Card(
              color: attendanceColor.withValues(alpha: 0.1),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(
                      attendanceRate == 0
                          ? Icons.info_outline
                          : (attendanceRate < 75
                              ? Icons.warning
                              : Icons.check_circle),
                      color: attendanceColor,
                      size: 28,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            attendanceMessage,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: attendanceColor,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            attendanceSubMessage,
                            style: TextStyle(
                                color: Colors.grey[600], fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (attendanceStats['total'] > 0) ...[
              const SizedBox(height: 20),
              const Text(
                'Attendance Details',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildDetailCard(
                      'Present', attendanceStats['present'] ?? 0, Colors.green),
                  const SizedBox(width: 12),
                  _buildDetailCard(
                      'Absent', attendanceStats['absent'] ?? 0, Colors.red),
                  const SizedBox(width: 12),
                  _buildDetailCard(
                      'Late', attendanceStats['late'] ?? 0, Colors.orange),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 5)
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 6),
          Text(value,
              style: TextStyle(
                  fontSize: 16, fontWeight: FontWeight.bold, color: color)),
          Text(title, style: TextStyle(fontSize: 10, color: Colors.grey[600])),
        ],
      ),
    );
  }

  Widget _buildDetailCard(String title, int count, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.05), blurRadius: 3)
          ],
        ),
        child: Column(
          children: [
            Text('$count',
                style: TextStyle(
                    fontSize: 20, fontWeight: FontWeight.bold, color: color)),
            Text(title,
                style: TextStyle(fontSize: 11, color: Colors.grey[600])),
          ],
        ),
      ),
    );
  }
}
