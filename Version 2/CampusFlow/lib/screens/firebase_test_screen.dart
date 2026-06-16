import 'package:flutter/material.dart';
import 'package:campus_flow/services/firebase_service.dart';

class FirebaseTestScreen extends StatefulWidget {
  const FirebaseTestScreen({super.key});

  @override
  State<FirebaseTestScreen> createState() => _FirebaseTestScreenState();
}

class _FirebaseTestScreenState extends State<FirebaseTestScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _regController = TextEditingController();

  String _status = 'Ready';
  List<Map<String, dynamic>> _students = [];
  String _authStatus = 'Not logged in';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkConnection();
  }

  Future<void> _checkConnection() async {
    setState(() => _status = 'Checking connection...');

    try {
      await CampusFirebaseService.testFirestore();
      await CampusFirebaseService.testRealtime();
      if (mounted) {
        setState(() => _status = '✅ Firebase is working!');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _status = '❌ Error: $e');
      }
    }
  }

  Future<void> _registerUser() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      _showMessage('Please enter email and password', Colors.red);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = await CampusFirebaseService.registerWithEmail(
        _emailController.text,
        _passwordController.text,
      );
      if (mounted) {
        setState(() {
          _authStatus = '✅ Logged in as: ${user?.email}';
          _isLoading = false;
        });
        _showMessage('Registration successful!', Colors.green);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showMessage('Error: $e', Colors.red);
      }
    }
  }

  Future<void> _loginUser() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      _showMessage('Please enter email and password', Colors.red);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = await CampusFirebaseService.loginWithEmail(
        _emailController.text,
        _passwordController.text,
      );
      if (mounted) {
        setState(() {
          _authStatus = '✅ Logged in as: ${user?.email}';
          _isLoading = false;
        });
        _showMessage('Login successful!', Colors.green);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showMessage('Error: $e', Colors.red);
      }
    }
  }

  Future<void> _saveStudent() async {
    if (_nameController.text.isEmpty || _regController.text.isEmpty) {
      _showMessage('Please enter name and reg number', Colors.red);
      return;
    }

    setState(() => _isLoading = true);

    try {
      await CampusFirebaseService.saveStudent({
        'regNumber': _regController.text,
        'name': _nameController.text,
        'createdAt': DateTime.now().toIso8601String(),
      });
      if (mounted) {
        setState(() => _isLoading = false);
        _showMessage('✅ Student saved to Firestore!', Colors.green);
        _nameController.clear();
        _regController.clear();
        await _loadStudents();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showMessage('Error: $e', Colors.red);
      }
    }
  }

  Future<void> _loadStudents() async {
    setState(() => _isLoading = true);
    try {
      final students = await CampusFirebaseService.getStudents();
      if (mounted) {
        setState(() {
          _students = students;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showMessage('Error loading students: $e', Colors.red);
      }
    }
  }

  void _showMessage(String message, Color color) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: color),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Firebase Test'),
        backgroundColor: const Color(0xFF667eea),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadStudents,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Status
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _status.contains('✅')
                    ? Colors.green.shade50
                    : _status.contains('❌')
                        ? Colors.red.shade50
                        : Colors.orange.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    _status.contains('✅')
                        ? Icons.check_circle
                        : _status.contains('❌')
                            ? Icons.error
                            : Icons.sync,
                    color: _status.contains('✅')
                        ? Colors.green
                        : _status.contains('❌')
                            ? Colors.red
                            : Colors.orange,
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Text(_status)),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Auth Status
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.account_circle, color: Colors.blue),
                  const SizedBox(width: 12),
                  Expanded(child: Text(_authStatus)),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Authentication Section
            const Text(
              '🔐 Firebase Authentication',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                  labelText: 'Email', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                  labelText: 'Password', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _registerUser,
                    style:
                        ElevatedButton.styleFrom(backgroundColor: Colors.green),
                    child: const Text('Register'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _loginUser,
                    style:
                        ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                    child: const Text('Login'),
                  ),
                ),
              ],
            ),
            const Divider(height: 30),

            // Firestore Section
            const Text(
              '📁 Firestore CRUD',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _regController,
                    decoration: const InputDecoration(
                        labelText: 'Reg Number', border: OutlineInputBorder()),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                        labelText: 'Name', border: OutlineInputBorder()),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _isLoading ? null : _saveStudent,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
              child: const Text('Save Student to Firestore'),
            ),
            const SizedBox(height: 10),

            // Students List
            const Text(
              '📋 Students in Firestore',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 5),
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else if (_students.isEmpty)
              const Center(child: Text('No students found. Add one!'))
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _students.length,
                itemBuilder: (context, index) {
                  final student = _students[index];
                  return Card(
                    child: ListTile(
                      title: Text(student['name'] ?? 'No name'),
                      subtitle: Text('Reg: ${student['regNumber'] ?? 'N/A'}'),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
