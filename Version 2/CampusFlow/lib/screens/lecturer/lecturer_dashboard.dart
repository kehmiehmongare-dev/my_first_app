import 'package:flutter/material.dart';
import 'package:campus_flow/models/lecturer_model.dart';
import 'package:campus_flow/screens/lecturer/lecturer_attendance_screen.dart';
import 'package:campus_flow/screens/lecturer/lecturer_students_screen.dart';
import 'package:campus_flow/screens/lecturer/lecturer_reports_screen.dart';
import 'package:campus_flow/screens/shared/login_screen.dart';

class LecturerDashboard extends StatelessWidget {
  final Lecturer lecturer;
  const LecturerDashboard({super.key, required this.lecturer});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lecturer Dashboard'),
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
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
              );
            },
          ),
        ],
      ),
      body: GridView.count(
        padding: const EdgeInsets.all(16),
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        children: [
          _buildMenuCard('Mark Attendance', Icons.qr_code_scanner, Colors.green,
              () {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) =>
                      LecturerAttendanceScreen(lecturer: lecturer)),
            );
          }),
          _buildMenuCard('My Students', Icons.people, Colors.blue, () {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) =>
                      LecturerStudentsScreen(lecturer: lecturer)),
            );
          }),
          _buildMenuCard('Reports', Icons.bar_chart, Colors.orange, () {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) =>
                      LecturerReportsScreen(lecturer: lecturer)),
            );
          }),
          _buildMenuCard('Profile', Icons.person, Colors.purple, () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Profile coming soon')),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildMenuCard(
      String title, IconData icon, Color color, VoidCallback onTap) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(50)),
              child: Icon(icon, size: 40, color: color),
            ),
            const SizedBox(height: 12),
            Text(title,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
