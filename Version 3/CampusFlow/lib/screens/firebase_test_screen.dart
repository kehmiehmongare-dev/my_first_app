import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';


class FirebaseTestScreen extends StatefulWidget {
  const FirebaseTestScreen({super.key});

  @override
  State<FirebaseTestScreen> createState() => _FirebaseTestScreenState();
}

class _FirebaseTestScreenState extends State<FirebaseTestScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();

  String _status = 'Ready';
  final List <Map<String, dynamic>> _students = [];
  String _authStatus = 'Not logged in';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // ✅ Check auth after Firebase is ready
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAuth();
    });
  }

  void _checkAuth() {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        _authStatus = '✅ Logged in as: ${user.email}';
      } else {
        _authStatus = '❌ Not logged in';
      }
      setState(() {});
    } catch (e) {
      _authStatus = '⚠️ Auth not available: $e';
      setState(() {});
    }
  }

  Future<void> _register() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      _showMessage('Please enter email and password', Colors.red);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final credential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      _authStatus = '✅ Registered as: ${credential.user?.email}';
      setState(() => _isLoading = false);
      _showMessage('✅ Registration successful!', Colors.green);
    } catch (e) {
      setState(() => _isLoading = false);
      _showMessage('❌ Error: $e', Colors.red);
    }
  }

  Future<void> _login() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      _showMessage('Please enter email and password', Colors.red);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      _authStatus = '✅ Logged in as: ${credential.user?.email}';
      setState(() => _isLoading = false);
      _showMessage('✅ Login successful!', Colors.green);
    } catch (e) {
      setState(() => _isLoading = false);
      _showMessage('❌ Error: $e', Colors.red);
    }
  }

  Future<void> _testWrite() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showMessage('Please login first', Colors.red);
      return;
    }

    setState(() => _isLoading = true);

    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'email': user.email,
        'name': _nameController.text.isNotEmpty
            ? _nameController.text
            : 'Test User',
        'role': 'student',
        'createdAt': FieldValue.serverTimestamp(),
      });

      setState(() {
        _status = '✅ Write successful!';
        _isLoading = false;
      });
      _showMessage('✅ Data written to your user document!', Colors.green);
    } catch (e) {
      setState(() {
        _status = '❌ Write failed: $e';
        _isLoading = false;
      });
      _showMessage('❌ Error: $e', Colors.red);
    }
  }

  Future<void> _testRead() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showMessage('Please login first', Colors.red);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      setState(() {
        _status = '✅ Read successful! Data: ${doc.data()}';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _status = '❌ Read failed: $e';
        _isLoading = false;
      });
      _showMessage('❌ Error: $e', Colors.red);
    }
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    _authStatus = '❌ Logged out';
    setState(() {});
    _showMessage('✅ Logged out', Colors.orange);
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
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _status.contains('✅')
                    ? Colors.green.shade50
                    : _status.contains('❌')
                        ? Colors.red.shade50
                        : Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    _status.contains('✅')
                        ? Icons.check_circle
                        : _status.contains('❌')
                            ? Icons.error
                            : Icons.info,
                    color: _status.contains('✅')
                        ? Colors.green
                        : _status.contains('❌')
                            ? Colors.red
                            : Colors.grey,
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Text(_status)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _authStatus.contains('Logged in')
                    ? Colors.green.shade50
                    : Colors.orange.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    _authStatus.contains('Logged in')
                        ? Icons.check_circle
                        : Icons.warning,
                    color: _authStatus.contains('Logged in')
                        ? Colors.green
                        : Colors.orange,
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Text(_authStatus)),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              '🔐 Authentication Test',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _register,
                    style:
                        ElevatedButton.styleFrom(backgroundColor: Colors.green),
                    child: const Text('Register'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _login,
                    style:
                        ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                    child: const Text('Login'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Your Name (for testing)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              '🧪 Security Rules Test',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _testWrite,
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple),
                    child: const Text('Write Test'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _testRead,
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo),
                    child: const Text('Read Test'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
