import 'package:flutter/material.dart';
import 'package:campus_flow/services/database_service.dart';
import 'package:campus_flow/screens/shared/registration_screen.dart';
import 'package:campus_flow/screens/lecturer/lecturer_registration_screen.dart';
import 'package:campus_flow/screens/student/student_dashboard.dart';
import 'package:campus_flow/screens/lecturer/lecturer_dashboard.dart';
import 'package:campus_flow/models/user_model.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  UserType _userType = UserType.student;
  bool _rememberMe = false;

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
  }

  Future<void> _loadSavedCredentials() async {
    final saved = await DatabaseService.getSavedCredentials();
    if (saved != null && mounted) {
      setState(() {
        _usernameController.text = saved['username'] ?? '';
        _rememberMe = true;
      });
    }
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final user = await DatabaseService.loginUser(
        username: _usernameController.text.trim(),
        password: _passwordController.text,
        userType: _userType,
      );

      if (!mounted) return;

      if (user != null) {
        if (_rememberMe) {
          await DatabaseService.saveCredentials(
            _usernameController.text.trim(),
            _passwordController.text,
          );
        }

        if (_userType == UserType.student) {
          final student = await DatabaseService.getStudentByUserId(user.id);
          if (!mounted) return;
          if (student != null) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                  builder: (context) => StudentDashboard(student: student)),
            );
          }
        } else {
          final lecturer = await DatabaseService.getLecturerByUserId(user.id);
          if (!mounted) return;
          if (lecturer != null) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                  builder: (context) => LecturerDashboard(lecturer: lecturer)),
            );
          }
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Invalid username or password'),
              backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Login failed: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Card(
                elevation: 24,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(32)),
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                                colors: [Color(0xFF667eea), Color(0xFF764ba2)]),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Image.asset(
                            'assets/images/study.png',
                            width: 60,
                            height: 60,
                            fit: BoxFit.contain,
                          ),
                        ),

                        const SizedBox(height: 24),
                        const Text('Campus Flow',
                            style: TextStyle(
                                fontSize: 28, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Text('Student Management System',
                            style: TextStyle(color: Colors.grey[600])),
                        const SizedBox(height: 32),

                        // User Type Selector
                        Center(
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _buildUserTypeButton(
                                    UserType.student, 'Student', Icons.person),
                                const SizedBox(width: 8),
                                _buildUserTypeButton(UserType.lecturer,
                                    'Lecturer', Icons.school),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),

                        TextFormField(
                          controller: _usernameController,
                          decoration: InputDecoration(
                            labelText: _userType == UserType.student
                                ? 'Registration Number / Email'
                                : 'Employee ID / Email',
                            prefixIcon: const Icon(Icons.email_outlined),
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          validator: (value) => value!.isEmpty
                              ? 'Please enter your username'
                              : null,
                        ),
                        const SizedBox(height: 16),

                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          decoration: InputDecoration(
                            labelText: 'Password',
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              icon: Icon(_obscurePassword
                                  ? Icons.visibility_off
                                  : Icons.visibility),
                              onPressed: () => setState(
                                  () => _obscurePassword = !_obscurePassword),
                            ),
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          validator: (value) => value!.isEmpty
                              ? 'Please enter your password'
                              : null,
                        ),
                        const SizedBox(height: 12),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Checkbox(
                                  value: _rememberMe,
                                  onChanged: (value) => setState(
                                      () => _rememberMe = value ?? false),
                                  activeColor: const Color(0xFF667eea),
                                ),
                                const Text('Remember me'),
                              ],
                            ),
                            TextButton(
                              onPressed: () {},
                              child: const Text('Forgot Password?',
                                  style: TextStyle(color: Color(0xFF667eea))),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _login,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF667eea),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                        color: Colors.white, strokeWidth: 2))
                                : const Text('LOGIN',
                                    style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold)),
                          ),
                        ),
                        const SizedBox(height: 16),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text("Don't have an account? ",
                                style: TextStyle(color: Colors.grey[600])),
                            TextButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => _userType ==
                                            UserType.student
                                        ? const RegistrationScreen()
                                        : const LecturerRegistrationScreen(),
                                  ),
                                );
                              },
                              child: Text(
                                'Register as ${_userType == UserType.student ? 'Student' : 'Lecturer'}',
                                style: const TextStyle(
                                    color: Color(0xFF667eea),
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUserTypeButton(UserType type, String label, IconData icon) {
    final isSelected = _userType == type;
    return GestureDetector(
      onTap: () => setState(() => _userType = type),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF667eea) : Colors.transparent,
          borderRadius: BorderRadius.circular(25),
        ),
        child: Row(
          children: [
            Icon(icon,
                size: 18, color: isSelected ? Colors.white : Colors.grey[600]),
            const SizedBox(width: 8),
            Text(label,
                style: TextStyle(
                    color: isSelected ? Colors.white : Colors.grey[600])),
          ],
        ),
      ),
    );
  }
}
