import 'package:flutter/material.dart';
import 'package:campus_flow/services/database_service.dart';
import 'package:campus_flow/models/student_model.dart';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _regController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passController = TextEditingController();
  final _confirmController = TextEditingController();

  String? _selectedCourse;
  int? _selectedSemester;
  bool _isLoading = false;
  bool _obscurePassword = true;

  final List<String> _courses = [
    'BSc Computer Science',
    'BSc Information Technology',
    'BSc Software Engineering',
  ];

  final List<int> _semesters = [1, 2, 3, 4, 5, 6, 7, 8];

  String _getSemesterDisplay(int semester) {
    int year = (semester + 1) ~/ 2;
    int sem = ((semester - 1) % 2) + 1;
    return 'Year $year - Semester $sem';
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final nameParts = _nameController.text.trim().split(' ');
      final firstName = nameParts[0];
      final lastName = nameParts.length > 1 ? nameParts.last : '';
      final middleName = nameParts.length > 2 ? nameParts[1] : '';

      final student = Student(
        id: _regController.text.trim(),
        userId: _regController.text.trim(),
        regNumber: _regController.text.trim(),
        firstName: firstName,
        middleName: middleName,
        lastName: lastName,
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
        course: _selectedCourse!,
        yearOfStudy: (_selectedSemester! + 1) ~/ 2,
        semester: _selectedSemester!,
        batch: '${DateTime.now().year}',
        enrollmentDate: DateTime.now().toIso8601String(),
        status: 'Active',
        currentGPA: 0.0,
        cumulativeGPA: 0.0,
        password: _passController.text,
        createdAt: DateTime.now(),
        lastLogin: DateTime.now(),
        isActive: true,
        expiryDate:
            DateTime.now().add(const Duration(days: 1460)).toIso8601String(),
      );

      final success = await DatabaseService.registerStudent(student);

      if (!mounted) return;
      setState(() => _isLoading = false);

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Registration successful!'),
              backgroundColor: Colors.green),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Student already exists!'),
              backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Registration'),
        backgroundColor: const Color(0xFF667eea),
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient:
              LinearGradient(colors: [Color(0xFF667eea), Color(0xFF764ba2)]),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      const Icon(Icons.person_add,
                          size: 60, color: Color(0xFF667eea)),
                      const SizedBox(height: 10),
                      const Text('Create Account',
                          style: TextStyle(
                              fontSize: 24, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 30),
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                            labelText: 'Full Name',
                            prefixIcon: Icon(Icons.person)),
                        validator: (value) =>
                            value!.isEmpty ? 'Enter full name' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _regController,
                        decoration: const InputDecoration(
                            labelText: 'Registration Number',
                            prefixIcon: Icon(Icons.assignment_ind)),
                        validator: (value) =>
                            value!.isEmpty ? 'Enter registration number' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _emailController,
                        decoration: const InputDecoration(
                            labelText: 'Email', prefixIcon: Icon(Icons.email)),
                        validator: (value) =>
                            value!.isEmpty ? 'Enter email' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _phoneController,
                        decoration: const InputDecoration(
                            labelText: 'Phone', prefixIcon: Icon(Icons.phone)),
                        validator: (value) =>
                            value!.isEmpty ? 'Enter phone' : null,
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: _selectedCourse,
                        decoration: const InputDecoration(
                            labelText: 'Course',
                            prefixIcon: Icon(Icons.school)),
                        items: _courses
                            .map((c) =>
                                DropdownMenuItem(value: c, child: Text(c)))
                            .toList(),
                        onChanged: (v) => setState(() => _selectedCourse = v),
                        validator: (v) => v == null ? 'Select course' : null,
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<int>(
                        initialValue: _selectedSemester,
                        decoration: const InputDecoration(
                            labelText: 'Semester',
                            prefixIcon: Icon(Icons.book)),
                        items: _semesters
                            .map((s) => DropdownMenuItem(
                                value: s, child: Text(_getSemesterDisplay(s))))
                            .toList(),
                        onChanged: (v) => setState(() => _selectedSemester = v),
                        validator: (v) => v == null ? 'Select semester' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _passController,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          prefixIcon: const Icon(Icons.lock),
                          suffixIcon: IconButton(
                            icon: Icon(_obscurePassword
                                ? Icons.visibility_off
                                : Icons.visibility),
                            onPressed: () => setState(
                                () => _obscurePassword = !_obscurePassword),
                          ),
                        ),
                        validator: (value) =>
                            value!.length < 6 ? 'Password too short' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _confirmController,
                        obscureText: true,
                        decoration: const InputDecoration(
                            labelText: 'Confirm Password',
                            prefixIcon: Icon(Icons.lock_outline)),
                        validator: (value) => value != _passController.text
                            ? 'Passwords do not match'
                            : null,
                      ),
                      const SizedBox(height: 30),
                      _isLoading
                          ? const CircularProgressIndicator()
                          : ElevatedButton(
                              onPressed: _register,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF667eea),
                                minimumSize: const Size(double.infinity, 50),
                              ),
                              child: const Text('Register'),
                            ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
