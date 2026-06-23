import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:campus_flow/shared/constants/app_colors.dart';
import 'package:intl/intl.dart';

class LecturerProfileScreen extends StatefulWidget {
  const LecturerProfileScreen({super.key});

  @override
  State<LecturerProfileScreen> createState() => _LecturerProfileScreenState();
}

class _LecturerProfileScreenState extends State<LecturerProfileScreen> {
  Map<String, dynamic> _userData = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final doc = await FirebaseFirestore.instance
            .collection('lecturers')
            .doc(user.uid)
            .get();

        if (doc.exists) {
          _userData = doc.data() as Map<String, dynamic>;
          _userData['uid'] = user.uid;
          _userData['email'] = user.email ?? '';
        } else {
          _userData = {
            'displayName': user.displayName ?? 'Lecturer',
            'email': user.email ?? '',
            'employeeId': 'LEC001',
            'department': 'Computer Science',
            'designation': 'Senior Lecturer',
            'title': 'Dr.',
            'uid': user.uid,
          };
        }
      }
    } catch (e) {
      debugPrint('Error loading profile: $e');
    }

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final fullName =
        '${_userData['title'] ?? 'Dr.'} ${_userData['displayName'] ?? 'Lecturer'}';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Staff Profile'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.primary, AppColors.secondary],
          ),
        ),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            CircleAvatar(
                              radius: 50,
                              backgroundColor: AppColors.primary,
                              child: Text(
                                (_userData['displayName'] ?? 'L')[0]
                                    .toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 40,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              fullName,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              _userData['designation'] ?? 'Lecturer',
                              style: TextStyle(
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                _userData['department'] ?? 'N/A',
                                style: TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const Divider(),
                            _infoTile(
                              Icons.email,
                              'Email',
                              _userData['email'] ?? '',
                            ),
                            _infoTile(
                              Icons.badge,
                              'Employee ID',
                              _userData['employeeId'] ?? 'N/A',
                            ),
                            _infoTile(
                              Icons.work,
                              'Designation',
                              _userData['designation'] ?? 'Lecturer',
                            ),
                            _infoTile(
                              Icons.business,
                              'Department',
                              _userData['department'] ?? 'N/A',
                            ),
                            _infoTile(
                              Icons.calendar_today,
                              'Joined',
                              _userData['createdAt'] != null
                                  ? DateFormat('MMM dd, yyyy').format(
                                      (_userData['createdAt'] as Timestamp)
                                          .toDate())
                                  : 'N/A',
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _infoTile(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.primary),
          const SizedBox(width: 12),
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
