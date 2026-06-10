import 'package:flutter/material.dart';
import 'package:campus_flow/models/student_model.dart';
import 'package:campus_flow/services/database_service.dart';
import 'package:campus_flow/screens/attendance_screen.dart';
import 'package:campus_flow/screens/profile_screen.dart';
import 'package:campus_flow/screens/courses_screen.dart';

class DashboardScreen extends StatefulWidget {
  final Student student;
  const DashboardScreen({super.key, required this.student});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;
  Map<String, dynamic> _stats = {};
  bool _isLoading = true;
  // Removed unused _greeting field

  late List<Widget> _screens;

  void updateIndex(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  void initState() {
    super.initState();
    _loadStats();
    _initializeScreens();
  }

  void _initializeScreens() {
    _screens = [
      DashboardHome(student: widget.student, stats: _stats),
      AttendanceScreen(student: widget.student),
      CoursesScreen(student: widget.student),
      ProfileScreen(student: widget.student),
    ];
  }

  Future<void> _loadStats() async {
    setState(() => _isLoading = true);

    await Future.delayed(const Duration(seconds: 3));

    try {
      final stats =
          await DatabaseService.getDashboardStats(widget.student.regNumber);
      if (mounted) {
        setState(() {
          _stats = stats;
          _isLoading = false;
        });
      }
    } catch (e) {
      ('Error loading stats: $e'); // Check terminal for error
      if (mounted) {
        setState(() {
          _stats = {
            'totalCourses': 0,
            'totalCredits': 0,
            'attendanceRate': 0.0,
            'totalClasses': 0,
            'presentCount': 0,
            'absentCount': 0,
            'lateCount': 0,
            'streak': 0,
          };
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF667eea), Color(0xFF764ba2)],
          ),
        ),
        child: Row(
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.95),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 10),
                ],
              ),
              child: NavigationRail(
                selectedIndex: _selectedIndex,
                onDestinationSelected: (index) =>
                    setState(() => _selectedIndex = index),
                labelType: NavigationRailLabelType.selected,
                leading: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                          ),
                          borderRadius: BorderRadius.all(Radius.circular(15)),
                        ),
                        child: const Icon(Icons.school,
                            color: Colors.white, size: 32),
                      ),
                    ],
                  ),
                ),
                destinations: const [
                  NavigationRailDestination(
                    icon: Icon(Icons.dashboard_outlined),
                    selectedIcon: Icon(Icons.dashboard),
                    label: Text('Home'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.check_circle_outline),
                    selectedIcon: Icon(Icons.check_circle),
                    label: Text('Attendance'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.menu_book_outlined),
                    selectedIcon: Icon(Icons.menu_book),
                    label: Text('Courses'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.person_outline),
                    selectedIcon: Icon(Icons.person),
                    label: Text('Profile'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(color: Colors.white),
                          SizedBox(height: 16),
                          Text(
                            'Loading your dashboard...',
                            style: TextStyle(color: Colors.white70),
                          ),
                        ],
                      ),
                    )
                  : IndexedStack(
                      index: _selectedIndex,
                      children: _screens,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// Dashboard Home Widget
class DashboardHome extends StatelessWidget {
  final Student student;
  final Map<String, dynamic> stats;
  const DashboardHome({super.key, required this.student, required this.stats});

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF667eea), Color(0xFF764ba2)],
        ),
      ),
      child: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            floating: true,
            pinned: true,
            backgroundColor: Colors.transparent,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                '${_getGreeting()}, ${student.name.split(' ').first}',
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.school,
                            size: 50, color: Colors.white),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Campus Flow',
                        style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white),
                      ),
                      const Text('Your Academic Journey',
                          style: TextStyle(color: Colors.white70)),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                Row(
                  children: [
                    Expanded(
                        child: _buildStatCard(
                            'Courses',
                            '${stats['totalCourses'] ?? 0}',
                            Icons.menu_book,
                            Colors.blue)),
                    const SizedBox(width: 12),
                    Expanded(
                        child: _buildStatCard(
                            'Credits',
                            '${stats['totalCredits'] ?? 0}',
                            Icons.credit_card,
                            Colors.green)),
                    const SizedBox(width: 12),
                    Expanded(
                        child: _buildStatCard(
                            'Attendance',
                            '${(stats['attendanceRate'] ?? 0).toStringAsFixed(0)}%',
                            Icons.trending_up,
                            Colors.orange)),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                        child: _buildStatCard(
                            'Present',
                            '${stats['presentCount'] ?? 0}',
                            Icons.check_circle,
                            Colors.green,
                            small: true)),
                    const SizedBox(width: 8),
                    Expanded(
                        child: _buildStatCard(
                            'Absent',
                            '${stats['absentCount'] ?? 0}',
                            Icons.cancel,
                            Colors.red,
                            small: true)),
                    const SizedBox(width: 8),
                    Expanded(
                        child: _buildStatCard(
                            'Late',
                            '${stats['lateCount'] ?? 0}',
                            Icons.access_time,
                            Colors.orange,
                            small: true)),
                    const SizedBox(width: 8),
                    Expanded(
                        child: _buildStatCard(
                            'Streak',
                            '${stats['streak'] ?? 0}',
                            Icons.local_fire_department,
                            Colors.deepOrange,
                            small: true)),
                  ],
                ),
                const SizedBox(height: 24),
                const Text('Quick Actions',
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white)),
                const SizedBox(height: 12),
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 4,
                  childAspectRatio: 1.1,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  children: [
                    _buildQuickAction(Icons.add, 'Mark\nAttendance',
                        Colors.green, () => _navigateToAttendance(context)),
                    _buildQuickAction(Icons.menu_book, 'Enroll\nCourse',
                        Colors.blue, () => _navigateToCourses(context)),
                    _buildQuickAction(Icons.notifications, 'View\nAlerts',
                        Colors.orange, () => _showComingSoon(context)),
                    _buildQuickAction(Icons.analytics, 'My\nProgress',
                        Colors.purple, () => _showComingSoon(context)),
                  ],
                ),
                const SizedBox(height: 24),
                const Text('Recent Activity',
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white)),
                const SizedBox(height: 12),
                _buildActivityCard(),
                const SizedBox(height: 24),
                _buildQuoteCard(),
                const SizedBox(height: 20),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color,
      {bool small = false}) {
    return Container(
      padding: EdgeInsets.all(small ? 12 : 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(small ? 12 : 20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 5))
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: small ? 20 : 28),
          const SizedBox(height: 8),
          Text(value,
              style: TextStyle(
                  fontSize: small ? 18 : 24,
                  fontWeight: FontWeight.bold,
                  color: color)),
          Text(title,
              style: TextStyle(
                  fontSize: small ? 10 : 12, color: Colors.grey[600])),
        ],
      ),
    );
  }

  Widget _buildQuickAction(
      IconData icon, String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 5)
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 8),
            Text(label,
                textAlign: TextAlign.center,
                style:
                    const TextStyle(fontSize: 11, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityCard() {
    final attendanceRate = (stats['attendanceRate'] ?? 0) as double;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10)
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF667eea).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.timeline, color: Color(0xFF667eea)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Overall Performance',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                Text('Keep up the good work!',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: attendanceRate >= 75 ? Colors.green : Colors.orange,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              attendanceRate >= 75 ? 'Excellent' : 'Good',
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuoteCard() {
    final quotes = [
      'Education is the most powerful weapon which you can use to change the world.',
      'The beautiful thing about learning is that no one can take it away from you.',
      'Success is no accident. It is hard work, perseverance, learning, studying, sacrifice.',
      'The future belongs to those who believe in the beauty of their dreams.',
    ];
    final randomQuote = quotes[DateTime.now().day % quotes.length];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.format_quote, color: Colors.white, size: 40),
          const SizedBox(width: 12),
          Expanded(
              child: Text(randomQuote,
                  style: const TextStyle(
                      color: Colors.white, fontStyle: FontStyle.italic))),
        ],
      ),
    );
  }

  void _navigateToAttendance(BuildContext context) {
    final dashboardState =
        context.findAncestorStateOfType<_DashboardScreenState>();
    if (dashboardState != null && dashboardState.mounted) {
      dashboardState
          .updateIndex(1); // Call the method instead of setState directly
    }
  }

  void _navigateToCourses(BuildContext context) {
    final dashboardState =
        context.findAncestorStateOfType<_DashboardScreenState>();
    if (dashboardState != null && dashboardState.mounted) {
      dashboardState
          .updateIndex(2); // Call the method instead of setState directly
    }
  }

  void _showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Feature coming soon!'),
          duration: Duration(seconds: 1)),
    );
  }
}
