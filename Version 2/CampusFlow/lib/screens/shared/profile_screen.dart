import 'package:flutter/material.dart';
import 'package:campus_flow/models/student_model.dart';

class ProfileScreen extends StatelessWidget {
  final Student student;
  const ProfileScreen({super.key, required this.student});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        backgroundColor: const Color(0xFF667eea),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: const Color(0xFF667eea),
                      child: Text(
                        student.firstName[0].toUpperCase(),
                        style:
                            const TextStyle(fontSize: 40, color: Colors.white),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      student.fullName,
                      style: const TextStyle(
                          fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      student.regNumber,
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    const Divider(height: 30),
                    _infoRow(Icons.email, 'Email', student.email),
                    _infoRow(Icons.phone, 'Phone', student.phone),
                    _infoRow(Icons.school, 'Course', student.course),
                    _infoRow(
                        Icons.book, 'Semester', 'Semester ${student.semester}'),
                    _infoRow(Icons.calendar_today, 'Year of Study',
                        'Year ${student.yearOfStudy}'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: const Color(0xFF667eea)),
          const SizedBox(width: 12),
          SizedBox(
            width: 100,
            child: Text(label,
                style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
