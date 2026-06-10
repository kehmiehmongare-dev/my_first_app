import 'package:flutter/material.dart';
import 'package:campus_flow/models/student_model.dart';
import 'package:campus_flow/services/database_service.dart';
import 'package:campus_flow/screens/login_screen.dart';

class ProfileScreen extends StatefulWidget {
  final Student student;
  const ProfileScreen({super.key, required this.student});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isEditing = false;
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _courseController;
  late TextEditingController _semesterController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.student.name);
    _emailController = TextEditingController(text: widget.student.email);
    _phoneController = TextEditingController(text: widget.student.phone);
    _courseController = TextEditingController(text: widget.student.course);
    _semesterController =
        TextEditingController(text: widget.student.semester.toString());
  }

  Future<void> _saveChanges() async {
    final updatedStudent = Student(
      regNumber: widget.student.regNumber,
      name: _nameController.text,
      email: _emailController.text,
      phone: _phoneController.text,
      course: _courseController.text,
      semester: int.parse(_semesterController.text),
      password: widget.student.password,
      registrationDate: widget.student.registrationDate,
    );

    await DatabaseService.updateStudent(
        widget.student.regNumber, updatedStudent.toJson());
    setState(() => _isEditing = false);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Profile updated!'), backgroundColor: Colors.green),
    );
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
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('My Profile', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon:
                Icon(_isEditing ? Icons.save : Icons.edit, color: Colors.white),
            onPressed: () {
              if (_isEditing) {
                _saveChanges();
              } else {
                setState(() => _isEditing = true);
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: _logout,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      widget.student.name[0].toUpperCase(),
                      style: const TextStyle(
                          fontSize: 40,
                          fontWeight: FontWeight.bold,
                          color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildInfoTile(
                      'Full Name', _nameController, Icons.person, _isEditing),
                  const Divider(),
                  _buildInfoTile(
                      'Registration Number', null, Icons.assignment_ind, false,
                      value: widget.student.regNumber),
                  const Divider(),
                  _buildInfoTile(
                      'Email', _emailController, Icons.email, _isEditing),
                  const Divider(),
                  _buildInfoTile(
                      'Phone', _phoneController, Icons.phone, _isEditing),
                  const Divider(),
                  _buildInfoTile(
                      'Course', _courseController, Icons.school, _isEditing),
                  const Divider(),
                  _buildInfoTile(
                      'Semester', _semesterController, Icons.book, _isEditing),
                  const Divider(),
                  _buildInfoTile(
                      'Member Since', null, Icons.calendar_today, false,
                      value:
                          '${widget.student.registrationDate.day}/${widget.student.registrationDate.month}/${widget.student.registrationDate.year}'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTile(String label, TextEditingController? controller,
      IconData icon, bool isEditing,
      {String? value}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF667eea), size: 24),
          const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: Text(label,
                style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
          Expanded(
            flex: 3,
            child: isEditing && controller != null
                ? TextField(
                    controller: controller,
                    decoration: const InputDecoration(
                        border: OutlineInputBorder(), isDense: true),
                  )
                : Text(value ?? controller?.text ?? ''),
          ),
        ],
      ),
    );
  }
}
