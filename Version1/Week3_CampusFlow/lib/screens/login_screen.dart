import 'package:flutter/material.dart';
import 'package:campus_flow/services/database_service.dart';
import 'package:campus_flow/models/user_model.dart';
import 'package:campus_flow/screens/registration_screen.dart';
import 'package:campus_flow/screens/lecturer_registration_screen.dart';
import 'package:campus_flow/screens/dashboard_screen.dart';
import 'package:campus_flow/screens/lecturer_dashboard_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  UserType _selectedUserType = UserType.student;

  Future<void> _login() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      _showMessage('Please fill all fields', Colors.red);
      return;
    }

    setState(() => _isLoading = true);

    String loginId = _emailController.text.trim();
    String password = _passwordController.text;

    if (_selectedUserType == UserType.student) {
      // For students: Try both Reg Number and Email
      final student = await DatabaseService.loginStudent(loginId, password);

      setState(() => _isLoading = false);

      if (student != null && mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (context) => DashboardScreen(student: student)),
        );
      } else {
        _showMessage(
            'Invalid Registration Number/Email or Password', Colors.red);
      }
    } else {
      // For lecturers
      final user =
          await DatabaseService.loginUser(loginId, password, UserType.lecturer);

      setState(() => _isLoading = false);

      if (user != null && mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (context) => const LecturerDashboardScreen()),
        );
      } else {
        _showMessage('Invalid Email or Password', Colors.red);
      }
    }
  }

  void _showMessage(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF667eea), Color(0xFF764ba2)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Card(
              elevation: 20,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.school,
                      size: 60,
                      color: Color(0xFF667eea),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Campus Flow',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF667eea),
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Student Management System',
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 40),

                    // User Type Selection
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: DropdownButtonFormField<UserType>(
                        initialValue: _selectedUserType,
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(horizontal: 16),
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: UserType.student,
                            child: Row(
                              children: [
                                Icon(Icons.person, size: 20),
                                SizedBox(width: 10),
                                Text('Login as Student'),
                              ],
                            ),
                          ),
                          DropdownMenuItem(
                            value: UserType.lecturer,
                            child: Row(
                              children: [
                                Icon(Icons.school, size: 20),
                                SizedBox(width: 10),
                                Text('Login as Lecturer'),
                              ],
                            ),
                          ),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _selectedUserType = value;
                              _emailController.clear();
                              _passwordController.clear();
                            });
                          }
                        },
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Email/Reg Number Field
                    TextField(
                      controller: _emailController,
                      keyboardType: TextInputType.text,
                      decoration: InputDecoration(
                        labelText: _selectedUserType == UserType.student
                            ? 'Registration Number or Email'
                            : 'Email Address',
                        prefixIcon: const Icon(Icons.email),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        hintText: _selectedUserType == UserType.student
                            ? 'e.g., STU001 or student@email.com'
                            : 'lecturer@university.com',
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Password Field
                    TextField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        prefixIcon: const Icon(Icons.lock),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility
                                : Icons.visibility_off,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),

                    // Login Button
                    _isLoading
                        ? const CircularProgressIndicator()
                        : ElevatedButton(
                            onPressed: _login,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF667eea),
                              minimumSize: const Size(double.infinity, 50),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: const Text(
                              'Login',
                              style: TextStyle(fontSize: 18),
                            ),
                          ),
                    const SizedBox(height: 20),

                    // Registration Links
                    if (_selectedUserType == UserType.student)
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const RegistrationScreen(),
                            ),
                          );
                        },
                        child: const Text(
                          "Don't have an account? Register as Student",
                          style: TextStyle(color: Color(0xFF667eea)),
                        ),
                      ),

                    if (_selectedUserType == UserType.lecturer)
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const LecturerRegistrationScreen(),
                            ),
                          );
                        },
                        child: const Text(
                          "New Lecturer? Register Here",
                          style: TextStyle(color: Color(0xFF667eea)),
                        ),
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
