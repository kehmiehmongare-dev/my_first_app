import 'package:flutter/material.dart';
import 'package:campus_flow/screens/shared/login_screen.dart';
import 'package:campus_flow/screens/record_management_screen.dart';
import 'package:campus_flow/screens/api_consumer_screen.dart';
import 'package:campus_flow/screens/data_management_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:campus_flow/services/firebase_service.dart' as my_firebase;
import 'package:campus_flow/screens/firebase_test_screen.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  try {
    await my_firebase.CampusFirebaseService.init();
    print('✅ Firebase initialized');

    // Test Firestore connection automatically
    await testFirestoreConnection();
  } catch (e) {
    print('❌ Firebase init error: $e');
  }

  runApp(const CampusFlowApp());
}

Future<void> testFirestoreConnection() async {
  try {
    await FirebaseFirestore.instance.collection('students').add({
      'name': 'Naom Mongare',
      'app': 'CampusFlow',
      'connected_at': DateTime.now().toString(),
      'status': 'Database is officially working!',
    });
    print("🎉 SUCCESS: Sent data to Firestore!");
  } catch (e) {
    print("❌ ERROR sending data: $e");
  }
}

class CampusFlowApp extends StatelessWidget {
  const CampusFlowApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Campus Flow',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        useMaterial3: true,
      ),
      home: const MainMenuScreen(),
    );
  }
}

class MainMenuScreen extends StatelessWidget {
  const MainMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Campus Flow'),
        backgroundColor: const Color(0xFF667eea),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF667eea), Color(0xFF764ba2)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // App Logo/Title
                Center(
                  child: Column(
                    children: [
                      Image.asset(
                        'assets/images/IT.png',
                        width: 60,
                        height: 60,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Campus Flow',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const Text(
                        'Student Management System',
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),

                // MAIN FEATURES - Your Original Work
                _buildSectionTitle('🔐 Authentication'),
                _buildMenuCard(
                  'Login / Register',
                  'Student & Lecturer Login/Registration',
                  Icons.login,
                  Colors.blue,
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  ),
                ),
                const SizedBox(height: 10),

                _buildSectionTitle('👨‍🎓 Student Features'),
                _buildMenuCard(
                  'Student Dashboard',
                  'View attendance, courses, fees, profile',
                  Icons.dashboard,
                  Colors.purple,
                  () => ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Please login as student first')),
                  ),
                ),
                const SizedBox(height: 10),

                _buildSectionTitle('👨‍🏫 Lecturer Features'),
                _buildMenuCard(
                  'Lecturer Dashboard',
                  'Mark attendance, view students, reports',
                  Icons.school,
                  Colors.orange,
                  () => ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Please login as lecturer first')),
                  ),
                ),
                const SizedBox(height: 10),

                _buildSectionTitle('📊 Data Management (Week 4 & 5)'),
                _buildMenuCard(
                  '📁 Record Management',
                  'SQLite CRUD - Add, Edit, Delete, Search',
                  Icons.storage,
                  Colors.green,
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const RecordManagementScreen()),
                  ),
                ),
                const SizedBox(height: 10),
                _buildMenuCard(
                  '🌐 API Consumer',
                  'JSON APIs - RandomUser.me',
                  Icons.cloud_queue,
                  Colors.teal,
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const ApiConsumerScreen()),
                  ),
                ),
                const SizedBox(height: 10),
                _buildMenuCard(
                  '📊 Data Management',
                  'Sync SQLite ↔ Firebase (Coming Soon)',
                  Icons.data_usage,
                  Colors.indigo,
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const DataManagementScreen()),
                  ),
                ),
                const SizedBox(height: 10),

                // ====== NEW: FIREBASE TEST ======
                _buildSectionTitle('🔥 Firebase'),
                _buildMenuCard(
                  '🔥 Firebase Test',
                  'Test Firebase connection, Auth, Firestore',
                  Icons.fireplace,
                  Colors.orange,
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const FirebaseTestScreen()),
                  ),
                ),
                const SizedBox(height: 30),

                // Footer
                const Text(
                  '© 2024 Campus Flow - All Rights Reserved',
                  style: TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
      ),
    );
  }

  Widget _buildMenuCard(String title, String subtitle, IconData icon,
      Color color, VoidCallback onTap) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 28, color: color),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(color: Colors.grey[600], fontSize: 11),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}
