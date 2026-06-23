import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:campus_flow/shared/constants/app_colors.dart';
import 'package:campus_flow/shared/widgets/stat_card.dart';
import 'package:campus_flow/features/lecturer/screens/lecturer_attendance_screen.dart';
import 'package:campus_flow/features/lecturer/screens/lecturer_students_screen.dart';
import 'package:campus_flow/features/lecturer/screens/lecturer_courses_screen.dart';
import 'package:campus_flow/features/lecturer/screens/lecturer_profile_screen.dart';
import 'package:intl/intl.dart';
import 'package:campus_flow/features/auth/screens/login_screen.dart';
import 'package:campus_flow/features/notifications/services/notification_service.dart';
import 'package:campus_flow/features/notifications/models/notification_model.dart';

class LecturerDashboard extends StatefulWidget {
  const LecturerDashboard({super.key});

  @override
  State<LecturerDashboard> createState() => _LecturerDashboardState();
}

class _LecturerDashboardState extends State<LecturerDashboard> {
  int _selectedIndex = 0;
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';

  // ✅ Lecturer data
  String _lecturerName = 'Lecturer';
  String _title = '';
  String _department = '';
  String _employeeId = '';
  int _studentCount = 0;
  int _courseCount = 0;
  double _averageAttendance = 0;
  List<Map<String, dynamic>> _recentActivities = [];
  String _greeting = '';
  List<String> _lecturerCourses = [];

  // ✅ Screens - built AFTER data loads
  late List<Widget> _screens;

  final NotificationService _notificationService = NotificationService();

  @override
  void initState() {
    super.initState();
    _updateGreeting();
    _loadData();
  }

  void _updateGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      _greeting = 'Good Morning ☀️';
    } else if (hour < 17) {
      _greeting = 'Good Afternoon 🌤️';
    } else {
      _greeting = 'Good Evening 🌙';
    }
  }

  // ✅ Send Notification Dialog
  void _showSendNotificationDialog() {
    final titleController = TextEditingController();
    final messageController = TextEditingController();
    NotificationType selectedType = NotificationType.announcement;
    String? selectedCourse;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Send Notification'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: messageController,
                decoration: const InputDecoration(
                  labelText: 'Message',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<NotificationType>(
                value: selectedType,
                decoration: const InputDecoration(
                  labelText: 'Type',
                  border: OutlineInputBorder(),
                ),
                items: NotificationType.values.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(type.name.toUpperCase()),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) selectedType = value;
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: selectedCourse,
                decoration: const InputDecoration(
                  labelText: 'Course (Optional)',
                  border: OutlineInputBorder(),
                ),
                items: _lecturerCourses.map((course) {
                  return DropdownMenuItem(
                    value: course,
                    child: Text(course),
                  );
                }).toList(),
                onChanged: (value) {
                  selectedCourse = value;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (titleController.text.isEmpty ||
                  messageController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please fill all fields'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              try {
                if (selectedCourse != null) {
                  // Send to all students in course
                  await _notificationService.sendToCourseStudents(
                    title: titleController.text,
                    message: messageController.text,
                    type: selectedType,
                    courseCode: selectedCourse!,
                  );
                } else {
                  // Send to all students
                  final students = await FirebaseFirestore.instance
                      .collection('students')
                      .get();
                  final studentIds =
                      students.docs.map((doc) => doc.id).toList();

                  await _notificationService.sendNotification(
                    title: titleController.text,
                    message: messageController.text,
                    type: selectedType,
                    recipientIds: studentIds,
                  );
                }

                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('✅ Notification sent successfully!'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('❌ Error: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Send'),
          ),
        ],
      ),
    );
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = '';
    });

    try {
      final user = FirebaseAuth.instance.currentUser;

      // ✅ Check if user is logged in
      if (user == null) {
        setState(() {
          _hasError = true;
          _errorMessage = 'User not logged in. Please login again.';
          _isLoading = false;
        });
        return;
      }

      // ✅ DEBUG: Print user info
      print('🔍 Lecturer Dashboard - User UID: ${user.uid}');
      print('🔍 Lecturer Dashboard - User Email: ${user.email}');

      // ✅ Get lecturer data from Firestore
      final doc = await FirebaseFirestore.instance
          .collection('lecturers')
          .doc(user.uid)
          .get();

      // ✅ DEBUG: Check if document exists
      print('🔍 Lecturer document exists: ${doc.exists}');

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;

        // ✅ DEBUG: Print all data
        print('📊 Lecturer data: $data');

        _lecturerName = data['displayName'] ?? 'Lecturer';
        _title = data['title'] ?? '';
        _department = data['department'] ?? '';
        _employeeId = data['employeeId'] ?? '';
        _lecturerCourses = List<String>.from(data['courses'] ?? []);
        _courseCount = _lecturerCourses.length;

        // ✅ Get student count
        try {
          final studentsSnapshot =
              await FirebaseFirestore.instance.collection('students').get();

          // Filter students by lecturer's courses
          if (_lecturerCourses.isNotEmpty) {
            _studentCount = studentsSnapshot.docs.where((doc) {
              final studentData = doc.data();
              final registeredUnits =
                  List<String>.from(studentData['registeredUnits'] ?? []);
              return registeredUnits
                  .any((unit) => _lecturerCourses.contains(unit));
            }).length;
          } else {
            _studentCount = studentsSnapshot.docs.length;
          }
          print('📊 Student count: $_studentCount');
        } catch (e) {
          print('⚠️ Error getting student count: $e');
          _studentCount = 0;
        }

        // ✅ Get recent activities
        try {
          final attendanceSnapshot = await FirebaseFirestore.instance
              .collection('attendance')
              .where('lecturerId', isEqualTo: user.uid)
              .orderBy('timestamp', descending: true)
              .limit(5)
              .get();

          _recentActivities = attendanceSnapshot.docs.map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            return data;
          }).toList();
        } catch (e) {
          print('⚠️ Error loading attendance: $e');
          _recentActivities = [];
        }
      } else {
        // ✅ Lecturer document doesn't exist - show error
        setState(() {
          _hasError = true;
          _errorMessage =
              'Lecturer profile not found. Please contact administrator.';
          _isLoading = false;
        });
        return;
      }

      // ✅ Build screens AFTER data is loaded
      _screens = [
        _buildHomeScreen(),
        const LecturerAttendanceScreen(),
        const LecturerStudentsScreen(),
        const LecturerCoursesScreen(),
        const LecturerProfileScreen(),
      ];

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('❌ Error loading lecturer data: $e');
      setState(() {
        _hasError = true;
        _errorMessage = 'Error loading data: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  Widget _buildHomeScreen() {
    // ✅ Build full name with title if available
    final fullName =
        _title.isNotEmpty ? '$_title $_lecturerName' : _lecturerName;

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.secondary],
        ),
      ),
      child: RefreshIndicator(
        onRefresh: _loadData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Professional Welcome Card
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 35,
                        backgroundColor: AppColors.primary,
                        child: Text(
                          _lecturerName.isNotEmpty
                              ? _lecturerName[0].toUpperCase()
                              : 'L',
                          style: const TextStyle(
                            fontSize: 28,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '$_greeting,',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              fullName,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (_department.isNotEmpty)
                              Text(
                                _department,
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 13,
                                ),
                              ),
                            if (_employeeId.isNotEmpty)
                              Text(
                                'ID: $_employeeId',
                                style: TextStyle(
                                  color: Colors.grey[500],
                                  fontSize: 11,
                                ),
                              ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                'Faculty Member',
                                style: TextStyle(
                                  color: AppColors.primary,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
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

              // Stats Row
              Row(
                children: [
                  Expanded(
                    child: StatCard(
                      title: 'Students',
                      value: '$_studentCount',
                      icon: Icons.people,
                      color: Colors.blue,
                      onTap: () => setState(() => _selectedIndex = 2),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: StatCard(
                      title: 'Courses',
                      value: '$_courseCount',
                      icon: Icons.menu_book,
                      color: Colors.green,
                      onTap: () => setState(() => _selectedIndex = 3),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: StatCard(
                      title: 'Attendance',
                      value: '${_averageAttendance.toStringAsFixed(0)}%',
                      icon: Icons.trending_up,
                      color: Colors.orange,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Quick Actions
              const Text(
                'Quick Actions',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 4,
                childAspectRatio: 1.2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                children: [
                  _buildQuickAction(
                    Icons.qr_code_scanner,
                    'Attendance',
                    Colors.green,
                    () => setState(() => _selectedIndex = 1),
                  ),
                  _buildQuickAction(
                    Icons.people,
                    'Students',
                    Colors.blue,
                    () => setState(() => _selectedIndex = 2),
                  ),
                  _buildQuickAction(
                    Icons.menu_book,
                    'Courses',
                    Colors.orange,
                    () => setState(() => _selectedIndex = 3),
                  ),
                  _buildQuickAction(
                    Icons.person,
                    'Profile',
                    Colors.purple,
                    () => setState(() => _selectedIndex = 4),
                  ),
                  _buildQuickAction(
                    Icons.notifications,
                    'Notify',
                    Colors.red,
                    _showSendNotificationDialog,
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Recent Activity
              if (_recentActivities.isNotEmpty) ...[
                const Text(
                  'Recent Activity',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                ..._recentActivities.map((activity) {
                  final date = (activity['timestamp'] as Timestamp).toDate();
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.green.withValues(alpha: 0.1),
                        child: Icon(
                          Icons.check_circle,
                          color: Colors.green,
                        ),
                      ),
                      title: Text(
                        '${activity['studentName'] ?? 'Student'} marked present',
                      ),
                      subtitle: Text(
                        DateFormat('MMM dd, hh:mm a').format(date),
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
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // ✅ Show error if there's one
    if (_hasError) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Lecturer Dashboard'),
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
                  onPressed: _loadData,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                  ),
                  child: const Text('Retry'),
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: _logout,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.grey[700],
                  ),
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
        title: Text(
            'Welcome, ${_title.isNotEmpty ? "$_title " : ""}$_lecturerName'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (_selectedIndex == 0) {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
                (route) => false,
              );
            } else {
              setState(() {
                _selectedIndex = 0;
              });
            }
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _screens.isEmpty
              ? const Center(child: Text('No data available'))
              : IndexedStack(
                  index: _selectedIndex,
                  children: _screens,
                ),
    );
  }
}
