import 'package:flutter/material.dart';
import 'package:campus_flow/services/database_service.dart';
import 'package:campus_flow/models/user_model.dart';

class LecturerRegistrationScreen extends StatefulWidget {
  const LecturerRegistrationScreen({super.key});

  @override
  State<LecturerRegistrationScreen> createState() =>
      _LecturerRegistrationScreenState();
}

class _LecturerRegistrationScreenState
    extends State<LecturerRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _employeeIdController = TextEditingController();
  final _departmentController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _isLoading = false;

  final List<String> _departments = [
    'Computer Science',
    'Information Technology',
    'Engineering',
    'Business',
    'Law',
    'Mathematics',
  ];

  Future<void> _register() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      final lecturer = User(
        id: _employeeIdController.text,
        name: _nameController.text,
        email: _emailController.text,
        password: _passwordController.text,
        type: UserType.lecturer,
        department: _departmentController.text,
        employeeId: _employeeIdController.text,
        createdAt: DateTime.now(),
      );

      final success = await DatabaseService.registerLecturer(lecturer);
      setState(() => _isLoading = false);

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Lecturer registered!'),
              backgroundColor: Colors.green),
        );
        Navigator.pop(context);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Registration failed!'),
              backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lecturer Registration'),
        backgroundColor: const Color(0xFF667eea),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF667eea), Color(0xFF764ba2)],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Card(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    const Icon(Icons.person_add,
                        size: 60, color: Color(0xFF667eea)),
                    const SizedBox(height: 10),
                    const Text('Lecturer Account',
                        style: TextStyle(
                            fontSize: 24, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 30),
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(labelText: 'Full Name'),
                      validator: (v) => v!.isEmpty ? 'Enter name' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(labelText: 'Email'),
                      validator: (v) => v!.isEmpty ? 'Enter email' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _employeeIdController,
                      decoration:
                          const InputDecoration(labelText: 'Employee ID'),
                      validator: (v) => v!.isEmpty ? 'Enter Employee ID' : null,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: _departmentController.text.isEmpty
                          ? null
                          : _departmentController.text,
                      decoration:
                          const InputDecoration(labelText: 'Department'),
                      items: _departments.map((dept) {
                        return DropdownMenuItem(value: dept, child: Text(dept));
                      }).toList(),
                      onChanged: (value) =>
                          _departmentController.text = value ?? '',
                      validator: (v) => _departmentController.text.isEmpty
                          ? 'Select department'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: const InputDecoration(labelText: 'Password'),
                      validator: (v) =>
                          v!.length < 6 ? 'Password too short' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _confirmController,
                      obscureText: true,
                      decoration:
                          const InputDecoration(labelText: 'Confirm Password'),
                      validator: (v) => v != _passwordController.text
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
                            child: const Text('Register as Lecturer'),
                          ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
