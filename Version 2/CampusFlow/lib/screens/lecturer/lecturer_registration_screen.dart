import 'package:flutter/material.dart';
import 'package:campus_flow/services/database_service.dart';
import 'package:campus_flow/models/user_model.dart';
import 'package:campus_flow/models/lecturer_model.dart';

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
  final _adminCodeController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;

  final List<String> _departments = [
    'Computer Science',
    'Information Technology',
    'Software Engineering'
  ];

  static const String _adminSecretCode = 'MKU_ADMIN_2024';

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    if (_adminCodeController.text != _adminSecretCode) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Invalid Admin Code!'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = User(
        id: _employeeIdController.text,
        email: _emailController.text,
        password: _passwordController.text,
        fullName: _nameController.text,
        userType: UserType.lecturer,
        phone: '',
        createdAt: DateTime.now(),
        lastLogin: DateTime.now(),
        isActive: true,
      );

      final lecturer = Lecturer(
        id: _employeeIdController.text,
        userId: _employeeIdController.text,
        employeeId: _employeeIdController.text,
        department: _departmentController.text,
        designation: 'Lecturer',
        courses: [],
      );

      final success = await DatabaseService.registerLecturer(user, lecturer);

      setState(() => _isLoading = false);

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Registration successful!'),
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
        title: const Text('Lecturer Registration'),
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
                      const Icon(Icons.school,
                          size: 60, color: Color(0xFF667eea)),
                      const SizedBox(height: 10),
                      const Text('Lecturer Account',
                          style: TextStyle(
                              fontSize: 24, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 30),
                      TextFormField(
                        controller: _adminCodeController,
                        obscureText: true,
                        decoration: const InputDecoration(
                            labelText: 'Admin Code',
                            prefixIcon: Icon(Icons.admin_panel_settings)),
                        validator: (v) =>
                            v!.isEmpty ? 'Enter admin code' : null,
                      ),
                      const SizedBox(height: 15),
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                            labelText: 'Full Name',
                            prefixIcon: Icon(Icons.person)),
                        validator: (v) => v!.isEmpty ? 'Enter name' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _emailController,
                        decoration: const InputDecoration(
                            labelText: 'Email', prefixIcon: Icon(Icons.email)),
                        validator: (v) => v!.isEmpty ? 'Enter email' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _employeeIdController,
                        decoration: const InputDecoration(
                            labelText: 'Employee ID',
                            prefixIcon: Icon(Icons.badge)),
                        validator: (v) =>
                            v!.isEmpty ? 'Enter Employee ID' : null,
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: _departmentController.text.isEmpty
                            ? null
                            : _departmentController.text,
                        decoration: const InputDecoration(
                            labelText: 'Department',
                            prefixIcon: Icon(Icons.business)),
                        items: _departments
                            .map((d) =>
                                DropdownMenuItem(value: d, child: Text(d)))
                            .toList(),
                        onChanged: (v) => _departmentController.text = v ?? '',
                        validator: (v) => _departmentController.text.isEmpty
                            ? 'Select department'
                            : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _passwordController,
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
                        validator: (v) =>
                            v!.length < 6 ? 'Password too short' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _confirmController,
                        obscureText: true,
                        decoration: const InputDecoration(
                            labelText: 'Confirm Password',
                            prefixIcon: Icon(Icons.lock_outline)),
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
      ),
    );
  }
}
