import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:campus_flow/features/student/screens/student_dashboard.dart';
import 'package:campus_flow/features/lecturer/screens/lecturer_dashboard.dart';
import 'package:campus_flow/features/admin/screens/admin_dashboard.dart';
import 'package:campus_flow/shared/constants/app_colors.dart';
import 'package:campus_flow/services/preferences_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _rememberMe = false;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final PreferencesService _prefs = PreferencesService();

  @override
  void initState() {
    super.initState();
    _prefs.init();
    _loadSavedCredentials();
    _checkIfAlreadyLoggedIn();
  }

  // ==================== LOAD SAVED CREDENTIALS ====================
  Future<void> _loadSavedCredentials() async {
    final email = _prefs.getUserEmail();
    final rememberMe = _prefs.getRememberMe();

    if (email != null && rememberMe) {
      _identifierController.text = email;
      _rememberMe = true;
    }
  }

  // ==================== CHECK IF ALREADY LOGGED IN ====================
  Future<void> _checkIfAlreadyLoggedIn() async {
    final user = _auth.currentUser;
    if (user != null) {
      await _navigateBasedOnRole(user.uid);
    }
  }

  // ==================== MAIN LOGIN METHOD ====================
  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final identifier = _identifierController.text.trim();
      final password = _passwordController.text;

      // ✅ Determine if input is a student registration number
      final bool isStudent = _isRegistrationNumber(identifier);
      final bool isEmail = identifier.contains('@');

      String email;

      if (isStudent) {
        // ✅ STUDENT LOGIN: Convert reg number to email
        email = '${identifier.toLowerCase()}@mylife.mku.ac.ke';
      } else if (isEmail) {
        // ✅ EMAIL LOGIN: Use as is
        email = identifier;
      } else {
        _showError('Please enter a valid Registration Number or Email');
        setState(() => _isLoading = false);
        return;
      }

      // ✅ Attempt Firebase Authentication
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = credential.user;

      // ✅ Check if user is null
      if (user == null) {
        _showError('Login failed. Please try again.');
        setState(() => _isLoading = false);
        return;
      }

      // ✅ Get user role from Firestore
      final doc = await _firestore.collection('users').doc(user.uid).get();

      // ✅ FIXED: Properly check doc.exists and get data
      Map<String, dynamic>? userData;
      String role = 'student';
      String userName = 'Student';

      if (doc.exists) {
        userData = doc.data() as Map<String, dynamic>;
        role = userData['role']?.toString().toLowerCase() ?? 'student';
        userName = userData['displayName'] ?? 'Student';
      } else {
        // Check if in students collection
        final studentDoc =
            await _firestore.collection('students').doc(user.uid).get();
        if (studentDoc.exists) {
          final studentData = studentDoc.data() as Map<String, dynamic>;
          userName = studentData['displayName'] ?? 'Student';
          role = 'student';
        }
      }

      // ✅ Save user session
      await _prefs.saveUserSession(
        email: email,
        uid: user.uid,
        name: userName,
        role: role,
      );

      // ✅ Save remember me preference
      await _prefs.setRememberMe(_rememberMe);

      // ✅ Navigate based on user role
      await _navigateBasedOnRole(user.uid);

      if (mounted) {
        setState(() => _isLoading = false);
      }
    } on FirebaseAuthException catch (e) {
      setState(() => _isLoading = false);
      _showError(_getAuthErrorMessage(e));
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('Login failed: $e');
    }
  }

  // ==================== REGISTRATION NUMBER VALIDATION ====================
  bool _isRegistrationNumber(String identifier) {
    final regExp = RegExp(r'^[A-Za-z]{2,4}[0-9]{6,9}$');
    return regExp.hasMatch(identifier);
  }

  // ==================== ROLE-BASED NAVIGATION ====================
  Future<void> _navigateBasedOnRole(String uid) async {
    try {
      // ✅ First check 'users' collection (for admins and lecturers)
      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(uid).get();

      String role = 'student';
      Map<String, dynamic>? userData;

      if (userDoc.exists) {
        userData = userDoc.data() as Map<String, dynamic>;
        role = userData['role']?.toString().toLowerCase() ?? 'student';
      } else {
        // ✅ If not in 'users', check 'students' collection
        DocumentSnapshot studentDoc =
            await _firestore.collection('students').doc(uid).get();

        if (studentDoc.exists) {
          role = 'student';
          userData = studentDoc.data() as Map<String, dynamic>;
        } else {
          // ✅ If not in 'students', check 'lecturers' collection
          DocumentSnapshot lecturerDoc =
              await _firestore.collection('lecturers').doc(uid).get();

          if (lecturerDoc.exists) {
            role = 'lecturer';
            userData = lecturerDoc.data() as Map<String, dynamic>;
          } else {
            _showError('User profile not found. Please contact administrator.');
            return;
          }
        }
      }

      if (!mounted) return;

      // ✅ Navigate based on role
      switch (role) {
        case 'admin':
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const AdminDashboard()),
          );
          break;

        case 'lecturer':
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const LecturerDashboard()),
          );
          break;

        default:
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const StudentDashboard()),
          );
          break;
      }
    } catch (e) {
      _showError('Failed to load user profile: $e');
      debugPrint('Navigation error: $e');
    }
  }

  // ==================== ERROR HANDLING ====================
  String _getAuthErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No account found with this email or registration number. Please contact admin.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'invalid-email':
        return 'Invalid email address.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many failed attempts. Please try again later.';
      default:
        return e.message ?? 'Login failed. Please try again.';
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  // ==================== FORGOT PASSWORD ====================
  void _showForgotPasswordDialog() {
    final TextEditingController identifierController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Reset Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Enter your Registration Number or Email to receive a password reset link.',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: identifierController,
              decoration: const InputDecoration(
                labelText: 'Registration Number / Email',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final identifier = identifierController.text.trim();
              if (identifier.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content:
                        Text('Please enter your Registration Number or Email'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              String email;
              if (_isRegistrationNumber(identifier)) {
                email = '${identifier.toLowerCase()}@mylife.mku.ac.ke';
              } else if (identifier.contains('@')) {
                email = identifier;
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Invalid Registration Number or Email'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              try {
                await _auth.sendPasswordResetEmail(email: email);
                if (!mounted) return;
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('✅ Password reset link sent to your email!'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('❌ Error: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Send Reset Link'),
          ),
        ],
      ),
    );
  }

  // ==================== BUILD UI ====================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.primary, AppColors.secondary],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Card(
                elevation: 24,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(32),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Logo
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [AppColors.primary, AppColors.secondary],
                            ),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Icon(
                            Icons.school,
                            size: 45,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'Campus Flow',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Student Management System',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 32),

                        // ✅ Identifier Field
                        TextFormField(
                          controller: _identifierController,
                          decoration: InputDecoration(
                            labelText: 'Registration Number / Email',
                            prefixIcon: const Icon(Icons.email_outlined),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your Registration Number or Email';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // ✅ Password Field
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          decoration: InputDecoration(
                            labelText: 'Password',
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                              ),
                              onPressed: () => setState(() {
                                _obscurePassword = !_obscurePassword;
                              }),
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          validator: (value) => value == null || value.isEmpty
                              ? 'Please enter your password'
                              : null,
                        ),
                        const SizedBox(height: 12),

                        // ✅ Remember Me & Forgot Password
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Checkbox(
                                  value: _rememberMe,
                                  onChanged: (value) => setState(() {
                                    _rememberMe = value ?? false;
                                  }),
                                  activeColor: AppColors.primary,
                                ),
                                const Text('Remember me'),
                              ],
                            ),
                            TextButton(
                              onPressed: _showForgotPasswordDialog,
                              child: const Text(
                                'Forgot Password?',
                                style: TextStyle(color: AppColors.primary),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // ✅ Login Button
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _login,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text(
                                    'LOGIN',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // ✅ Login Hint
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.info_outline,
                                    color: AppColors.primary,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Students: Use Registration Number (e.g., BIT202459115)',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey[700],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const SizedBox(width: 24),
                                  Expanded(
                                    child: Text(
                                      'Lecturers & Admin: Use Email',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey[500],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
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
}
