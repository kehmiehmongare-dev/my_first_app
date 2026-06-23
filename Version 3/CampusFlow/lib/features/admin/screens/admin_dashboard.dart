import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:campus_flow/shared/constants/app_colors.dart';
import 'package:campus_flow/shared/widgets/stat_card.dart';
import 'package:campus_flow/features/admin/screens/admin_users_screen.dart';
import 'package:campus_flow/features/admin/screens/admin_courses_screen.dart';
import 'package:campus_flow/features/admin/screens/admin_reports_screen.dart';
import 'package:campus_flow/features/admin/screens/admin_settings_screen.dart';
import 'package:campus_flow/features/admin/screens/admin_upload_students_screen.dart';
import 'package:campus_flow/features/admin/screens/admin_upload_lecturers_screen.dart';
import 'package:campus_flow/features/auth/screens/login_screen.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _selectedIndex = 0;
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';

  int _totalStudents = 0;
  int _totalLecturers = 0;
  int _totalCourses = 0;
  int _totalAttendanceToday = 0;
  int _totalUsers = 0;
  String _adminName = 'Admin';
  List<Map<String, dynamic>> _recentActivities = [];

  // ✅ Build screens AFTER data loads
  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = '';
    });

    try {
      final user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        setState(() {
          _hasError = true;
          _errorMessage = 'User not logged in. Please login again.';
          _isLoading = false;
        });
        return;
      }

      debugPrint('Admin Dashboard - User UID: ${user.uid}');

      // Get admin name
      final adminDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (adminDoc.exists) {
        final data = adminDoc.data() as Map<String, dynamic>;
        _adminName = data['displayName'] ?? 'Admin';
      }

      // Get counts - wrapped in try-catch to handle permission errors
      try {
        final studentsSnapshot =
            await FirebaseFirestore.instance.collection('students').get();
        _totalStudents = studentsSnapshot.docs.length;
      } catch (e) {
        debugPrint('Error getting students: $e');
        _totalStudents = 0;
      }

      try {
        final lecturersSnapshot =
            await FirebaseFirestore.instance.collection('lecturers').get();
        _totalLecturers = lecturersSnapshot.docs.length;
      } catch (e) {
        debugPrint('Error getting lecturers: $e');
        _totalLecturers = 0;
      }

      try {
        final coursesSnapshot =
            await FirebaseFirestore.instance.collection('courses').get();
        _totalCourses = coursesSnapshot.docs.length;
      } catch (e) {
        debugPrint('Error getting courses: $e');
        _totalCourses = 0;
      }

      try {
        final today = DateTime.now().toIso8601String().split('T')[0];
        final attendanceSnapshot = await FirebaseFirestore.instance
            .collection('attendance')
            .where('date', isEqualTo: today)
            .get();
        _totalAttendanceToday = attendanceSnapshot.docs.length;
      } catch (e) {
        debugPrint('Error getting attendance: $e');
        _totalAttendanceToday = 0;
      }

      try {
        final activitiesSnapshot = await FirebaseFirestore.instance
            .collection('attendance')
            .orderBy('timestamp', descending: true)
            .limit(5)
            .get();

        _recentActivities = activitiesSnapshot.docs.map((doc) {
          final data = doc.data();
          data['id'] = doc.id;
          return data;
        }).toList();
      } catch (e) {
        debugPrint('Error getting activities: $e');
        _recentActivities = [];
      }

      _totalUsers = _totalStudents + _totalLecturers;

      // ✅ Build screens AFTER data is loaded
      _screens = [
        _buildHomeScreen(),
        const AdminUsersScreen(),
        const AdminCoursesScreen(),
        const AdminReportsScreen(),
        const AdminSettingsScreen(),
      ];

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading admin data: $e');
      setState(() {
        _hasError = true;
        _errorMessage = 'Error loading data: $e';
        _isLoading = false;
      });
    }
  }

  void _goToLogin() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) => false,
    );
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    _goToLogin();
  }

  Widget _buildActionCard(
    String title,
    String subtitle,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Go →',
                  style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHomeScreen() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.secondary],
        ),
      ),
      child: RefreshIndicator(
        onRefresh: _loadStats,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize
                .min, // ✅ Fix: Use min to avoid unbounded constraints
            children: [
              // Welcome Card
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: AppColors.primary,
                        child: Text(
                          _adminName.isNotEmpty
                              ? _adminName[0].toUpperCase()
                              : 'A',
                          style: const TextStyle(
                            fontSize: 24,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Welcome, $_adminName',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'System Administrator',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
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

              // Action Cards - Using Flexible instead of Expanded
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildActionCard(
                    '👤 Manage Users',
                    'Add, edit, delete users',
                    Colors.blue,
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AdminUsersScreen(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildActionCard(
                    '📤 Upload Students',
                    'Bulk upload student data',
                    Colors.green,
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AdminUploadStudentsScreen(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildActionCard(
                    '📤 Upload Lecturers',
                    'Bulk upload lecturer data',
                    Colors.orange,
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AdminUploadLecturersScreen(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildActionCard(
                    '📚 Manage Courses',
                    'Add, edit, delete courses',
                    Colors.purple,
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AdminCoursesScreen(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Stats Row
              Row(
                children: [
                  Expanded(
                    child: StatCard(
                      title: 'Students',
                      value: '$_totalStudents',
                      icon: Icons.people,
                      color: Colors.blue,
                      onTap: () => setState(() => _selectedIndex = 1),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: StatCard(
                      title: 'Lecturers',
                      value: '$_totalLecturers',
                      icon: Icons.school,
                      color: Colors.green,
                      onTap: () => setState(() => _selectedIndex = 1),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: StatCard(
                      title: 'Courses',
                      value: '$_totalCourses',
                      icon: Icons.menu_book,
                      color: Colors.orange,
                      onTap: () => setState(() => _selectedIndex = 2),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: StatCard(
                      title: 'Today\'s Attendance',
                      value: '$_totalAttendanceToday',
                      icon: Icons.trending_up,
                      color: Colors.purple,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: StatCard(
                      title: 'Total Users',
                      value: '$_totalUsers',
                      icon: Icons.people_outline,
                      color: Colors.teal,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Quick Actions
              const Text(
                'Quick Actions',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 3,
                childAspectRatio: 1.2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                children: [
                  _buildQuickAction(
                    Icons.people,
                    'Users',
                    Colors.blue,
                    () => setState(() => _selectedIndex = 1),
                  ),
                  _buildQuickAction(
                    Icons.menu_book,
                    'Courses',
                    Colors.green,
                    () => setState(() => _selectedIndex = 2),
                  ),
                  _buildQuickAction(
                    Icons.bar_chart,
                    'Reports',
                    Colors.orange,
                    () => setState(() => _selectedIndex = 3),
                  ),
                  _buildQuickAction(
                    Icons.settings,
                    'Settings',
                    Colors.purple,
                    () => setState(() => _selectedIndex = 4),
                  ),
                  _buildQuickAction(
                    Icons.upload_file,
                    'Upload\nStudents',
                    Colors.teal,
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              const AdminUploadStudentsScreen(),
                        ),
                      );
                    },
                  ),
                  _buildQuickAction(
                    Icons.upload_file,
                    'Upload\nLecturers',
                    Colors.indigo,
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              const AdminUploadLecturersScreen(),
                        ),
                      );
                    },
                  ),
                  _buildQuickAction(
                    Icons.person_add,
                    'Add User',
                    Colors.pink,
                    () => setState(() => _selectedIndex = 1),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Recent Activity
              if (_recentActivities.isNotEmpty) ...[
                const Text(
                  'Recent Activity',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                ..._recentActivities.map((activity) {
                  final date = (activity['timestamp'] as Timestamp).toDate();
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.green.withValues(alpha: 0.1),
                        child: const Icon(
                          Icons.check_circle,
                          color: Colors.green,
                        ),
                      ),
                      title: Text(
                        '${activity['studentName'] ?? 'Student'} marked present',
                      ),
                      subtitle: Text(
                        '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute}',
                      ),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          activity['status'] ?? 'present',
                          style: const TextStyle(color: Colors.green),
                        ),
                      ),
                    ),
                  );
                }),
              ] else ...[
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Icon(Icons.info_outline, color: Colors.grey[400]),
                        const SizedBox(height: 8),
                        Text(
                          'No recent activities',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
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

  Widget _buildQuickAction(
    IconData icon,
    String label,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 5,
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Admin Dashboard'),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                const SizedBox(height: 16),
                Text(
                  _errorMessage,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _loadStats,
                  child: const Text('Retry'),
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: _logout,
                  child: const Text('Logout'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (_selectedIndex == 0) {
              _goToLogin();
            } else {
              setState(() {
                _selectedIndex = 0;
              });
            }
          },
        ),
        actions: [
          IconButton(icon: const Icon(Icons.logout), onPressed: _logout),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _screens.isEmpty
              ? const Center(child: Text('No data available'))
              : IndexedStack(index: _selectedIndex, children: _screens),
    );
  }
}
