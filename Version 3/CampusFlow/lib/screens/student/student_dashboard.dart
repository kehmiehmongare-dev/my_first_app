import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:campus_flow/shared/constants/app_colors.dart';
import 'package:campus_flow/shared/widgets/stat_card.dart';
import 'package:campus_flow/features/student/screens/attendance_screen.dart';
import 'package:campus_flow/features/student/screens/courses_screen.dart';
import 'package:campus_flow/features/student/screens/fees_screen.dart';
import 'package:campus_flow/features/student/screens/student_profile_screen.dart';
import 'package:campus_flow/features/student/screens/unit_registration_screen.dart';
import 'package:campus_flow/features/auth/screens/login_screen.dart';
import 'package:campus_flow/features/payments/widgets/payment_button.dart';
import 'package:campus_flow/services/sync_service.dart';
import 'package:campus_flow/services/offline_attendance_db.dart';

class StudentDashboard extends StatefulWidget {
  const StudentDashboard({super.key});

  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
  int _selectedIndex = 0;
  bool _isLoading = false;
  bool _hasError = false;
  String _errorMessage = '';

  // Student data with default values
  String _userName = 'Student';
  String _userRegNumber = 'STU001';
  String _userUid = '';
  String _userCourse = 'Not Enrolled';
  String _userDepartment = '';
  int _courseCount = 0;
  double _attendanceRate = 0;
  double _pendingFees = 0;
  double _totalFees = 60000;
  double _paidFees = 0;
  List<String> _registeredUnits = [];
  String _tempSessionId = '';

  // Sync status
  int _unsyncedCount = 0;
  bool _hasInternet = true;

  // Screens
  late List<Widget> _screens;

  final SyncService _syncService = SyncService();
  final OfflineAttendanceDB _db = OfflineAttendanceDB();

  @override
  void initState() {
    super.initState();
    _screens = [
      const Center(child: CircularProgressIndicator()),
      const AttendanceScreen(),
      const CoursesScreen(),
      const FeesScreen(),
      const ProfileScreen(),
    ];
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadUserData();
      _checkSyncStatus();
    });
  }

  // ==================== CHECK SYNC STATUS ====================
  Future<void> _checkSyncStatus() async {
    final status = await _syncService.getSyncStatus();
    setState(() {
      _hasInternet = status['hasInternet'] ?? false;
      _unsyncedCount = status['unsyncedCount'] ?? 0;
    });

    // ✅ Auto-sync if there are unsynced records and internet is available
    if (_hasInternet && _unsyncedCount > 0) {
      await _syncService.syncAttendance();
      final newStatus = await _syncService.getSyncStatus();
      setState(() {
        _unsyncedCount = newStatus['unsyncedCount'] ?? 0;
      });
    }
  }

  // ==================== LOAD USER DATA ====================
  Future<void> _loadUserData() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = '';
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() {
          _hasError = true;
          _errorMessage = 'Please login again.';
          _isLoading = false;
        });
        _updateHomeScreenWithError();
        return;
      }

      _userUid = user.uid;

      final doc = await FirebaseFirestore.instance
          .collection('students')
          .doc(user.uid)
          .get()
          .timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          throw Exception('Connection timeout. Please check your network.');
        },
      );

      if (!doc.exists) {
        final fallbackQuery = await FirebaseFirestore.instance
            .collection('students')
            .where('email', isEqualTo: user.email)
            .get();

        if (fallbackQuery.docs.isEmpty) {
          setState(() {
            _hasError = true;
            _errorMessage = 'Student profile not found.';
            _isLoading = false;
          });
          _updateHomeScreenWithError();
          return;
        }
        _parseStudentData(fallbackQuery.docs.first.data());
      } else {
        _parseStudentData(doc.data() as Map<String, dynamic>);
      }

      _updateHomeScreenWithData();
      setState(() => _isLoading = false);
    } catch (e) {
      setState(() {
        _hasError = true;
        _errorMessage = 'Error: ${e.toString()}';
        _isLoading = false;
      });
      _updateHomeScreenWithError();
    }
  }

  // ✅ Parse student data from Firestore
  void _parseStudentData(Map<String, dynamic> data) {
    _userName = data['displayName'] ?? 'Student';
    _userRegNumber = data['regNumber'] ?? 'STU001';
    _userCourse = data['course'] ?? data['courseName'] ?? 'Not Enrolled';
    _userDepartment = data['department'] ?? data['faculty'] ?? '';
    _attendanceRate = (data['attendanceRate'] ?? 0).toDouble();
    _totalFees = (data['totalFees'] ?? data['semesterFee'] ?? 60000).toDouble();
    _paidFees = (data['paidFees'] ?? 0).toDouble();
    _pendingFees = _totalFees - _paidFees;
    if (_pendingFees < 0) _pendingFees = 0;

    final unitsData = data['registeredUnits'];
    _registeredUnits.clear();

    if (unitsData != null && unitsData is List) {
      if (unitsData.isNotEmpty) {
        if (unitsData[0] is String) {
          _registeredUnits = List<String>.from(unitsData);
        } else if (unitsData[0] is Map) {
          _registeredUnits = unitsData
              .map((e) => e['code']?.toString() ?? '')
              .where((e) => e.isNotEmpty)
              .toList();
        }
      }
      _courseCount = _registeredUnits.length;
    } else {
      _courseCount = 0;
    }
  }

  void _updateHomeScreenWithData() {
    setState(() {
      _screens[0] = _buildHomeScreen();
    });
  }

  void _updateHomeScreenWithError() {
    setState(() {
      _screens[0] = Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
              const SizedBox(height: 16),
              Text(
                _errorMessage,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _loadUserData,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 12,
                  ),
                ),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    });
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  // ==================== SUPPORT DIALOG ====================
  void _showSupportDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.support_agent, color: AppColors.primary),
            const SizedBox(width: 8),
            const Text('Support Center'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'How can we help you?',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ListTile(
              leading: Icon(Icons.email, color: AppColors.primary),
              title: const Text('Email Support'),
              subtitle: const Text('support@campusflow.com'),
              onTap: () {
                Navigator.pop(context);
                _showMessage('📧 Email: support@campusflow.com', Colors.blue);
              },
              dense: true,
            ),
            ListTile(
              leading: Icon(Icons.phone, color: AppColors.primary),
              title: const Text('Call Support'),
              subtitle: const Text('+254 700 000 000'),
              onTap: () {
                Navigator.pop(context);
                _showMessage('📞 Call: +254 700 000 000', Colors.green);
              },
              dense: true,
            ),
            ListTile(
              leading: Icon(Icons.help, color: AppColors.primary),
              title: const Text('FAQ'),
              subtitle: const Text('Frequently Asked Questions'),
              onTap: () {
                Navigator.pop(context);
                _showFAQDialog();
              },
              dense: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showFAQDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('❓ Frequently Asked Questions'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('📚 How to register for units?',
                style: TextStyle(fontWeight: FontWeight.bold)),
            Text('Go to Quick Actions → Register Units'),
            SizedBox(height: 10),
            Text('💰 How to pay fees?',
                style: TextStyle(fontWeight: FontWeight.bold)),
            Text('Go to Finance tab → Select payment method'),
            SizedBox(height: 10),
            Text('📊 How to check attendance?',
                style: TextStyle(fontWeight: FontWeight.bold)),
            Text('Go to Attendance tab → View your records'),
            SizedBox(height: 10),
            Text('📖 How to view courses?',
                style: TextStyle(fontWeight: FontWeight.bold)),
            Text('Go to Units tab → See all registered units'),
            SizedBox(height: 10),
            Text('📞 How to contact support?',
                style: TextStyle(fontWeight: FontWeight.bold)),
            Text('Go to Support → Email or Call'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showMessage(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ==================== QR CODE ATTENDANCE ====================
  Future<void> _scanQRCode() async {
    try {
      final sessionId = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('📱 Scan QR Code'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.qr_code_scanner,
                  size: 80, color: AppColors.primary),
              const SizedBox(height: 16),
              const Text(
                'Enter the Session ID from your lecturer:',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              TextField(
                decoration: const InputDecoration(
                  hintText: 'e.g., 1734567890123',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.qr_code),
                ),
                keyboardType: TextInputType.number,
                onChanged: (value) => _tempSessionId = value,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, null),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (_tempSessionId.isNotEmpty) {
                  Navigator.pop(context, _tempSessionId);
                } else {
                  _showMessage('Please enter a Session ID', Colors.red);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
              ),
              child: const Text('Mark Attendance'),
            ),
          ],
        ),
      );

      if (sessionId != null && sessionId.isNotEmpty) {
        await _markAttendance(sessionId);
      }
    } catch (e) {
      _showMessage('Error: $e', Colors.red);
    }
  }

  Future<void> _markAttendance(String sessionId) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // ✅ Check if we have internet
      final hasInternet = await _syncService.hasInternet();

      if (!hasInternet) {
        // ✅ OFFLINE: Save to SQLite
        final week = await _calculateWeek();
        await _db.saveAttendance({
          'studentId': user.uid,
          'studentName': _userName,
          'regNumber': _userRegNumber,
          'unitCode': 'Unknown', // Will be extracted from QR
          'sessionId': sessionId,
          'week': week,
          'qrData': sessionId,
        });
        _showMessage('📴 Attendance saved offline! Will sync when online.',
            Colors.orange);
        await _checkSyncStatus();
        return;
      }

      // ✅ ONLINE: Mark directly
      final sessionDoc = await FirebaseFirestore.instance
          .collection('attendance_sessions')
          .doc(sessionId)
          .get();

      if (!sessionDoc.exists) {
        _showMessage('❌ Invalid QR Code - Session not found', Colors.red);
        return;
      }

      final sessionData = sessionDoc.data() as Map<String, dynamic>;

      if (sessionData['isActive'] != true) {
        _showMessage('❌ This QR Code has expired', Colors.red);
        return;
      }

      final students = List<String>.from(sessionData['students'] ?? []);
      if (students.contains(user.uid)) {
        _showMessage('✅ You already marked attendance!', Colors.orange);
        return;
      }

      await sessionDoc.reference.update({
        'students': FieldValue.arrayUnion([user.uid]),
      });

      final week = await _calculateWeek();

      await FirebaseFirestore.instance.collection('attendance').add({
        'studentId': user.uid,
        'studentName': _userName,
        'studentRegNumber': _userRegNumber,
        'courseCode': sessionData['courseCode'],
        'sessionId': sessionId,
        'week': week,
        'date': DateTime.now().toIso8601String(),
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'present',
        'lecturerId': sessionData['lecturerId'],
      });

      await _updateAttendanceRate();
      _showMessage('✅ Attendance marked successfully!', Colors.green);
    } catch (e) {
      _showMessage('Error marking attendance: $e', Colors.red);
    }
  }

  Future<int> _calculateWeek() async {
    final semesterStart = DateTime(2024, 1, 15);
    final now = DateTime.now();
    final difference = now.difference(semesterStart);
    final week = (difference.inDays / 7).floor() + 1;
    return week.clamp(1, 14);
  }

  Future<void> _updateAttendanceRate() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final attendanceSnapshot = await FirebaseFirestore.instance
          .collection('attendance')
          .where('studentId', isEqualTo: user.uid)
          .get();

      final total = attendanceSnapshot.docs.length;
      final present = attendanceSnapshot.docs
          .where((doc) => doc['status'] == 'present')
          .length;

      final rate = total > 0 ? (present / total) * 100 : 0;

      await FirebaseFirestore.instance
          .collection('students')
          .doc(user.uid)
          .update({
        'attendanceRate': rate,
      });

      setState(() {
        _attendanceRate = rate.toDouble();
      });
    } catch (e) {
      debugPrint('Error updating attendance rate: $e');
    }
  }

  // ==================== ATTENDANCE PROGRESS WIDGET ====================
  Widget _buildAttendanceProgress() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.trending_up, color: AppColors.primary),
                const SizedBox(width: 8),
                const Text(
                  '📊 Attendance Progress',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                _buildSyncStatus(),
              ],
            ),
            const SizedBox(height: 12),
            if (_registeredUnits.isEmpty)
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: Text(
                  'No units registered yet.',
                  style: TextStyle(color: Colors.grey),
                ),
              )
            else
              ..._registeredUnits.map((unit) => _buildUnitProgress(unit)),
          ],
        ),
      ),
    );
  }

  Widget _buildSyncStatus() {
    if (_unsyncedCount > 0 && _hasInternet) {
      return Row(
        children: [
          const Icon(Icons.sync, color: Colors.blue, size: 16),
          const SizedBox(width: 4),
          Text(
            'Syncing...',
            style: TextStyle(fontSize: 12, color: Colors.blue[600]),
          ),
        ],
      );
    } else if (_unsyncedCount > 0) {
      return Row(
        children: [
          const Icon(Icons.cloud_off, color: Colors.orange, size: 16),
          const SizedBox(width: 4),
          Text(
            '$_unsyncedCount offline',
            style: TextStyle(fontSize: 12, color: Colors.orange[600]),
          ),
        ],
      );
    } else if (_hasInternet) {
      return Row(
        children: [
          const Icon(Icons.cloud_done, color: Colors.green, size: 16),
          const SizedBox(width: 4),
          Text(
            'Synced',
            style: TextStyle(fontSize: 12, color: Colors.green[600]),
          ),
        ],
      );
    } else {
      return const Icon(Icons.wifi_off, color: Colors.red, size: 16);
    }
  }

  Widget _buildUnitProgress(String unitCode) {
    return FutureBuilder<DocumentSnapshot>(
      future:
          FirebaseFirestore.instance.collection('students').doc(_userUid).get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const SizedBox();
        }

        final data = snapshot.data!.data() as Map<String, dynamic>;
        final attendance = data['attendance'] ?? {};
        final unitData = attendance[unitCode] ??
            {'percentage': 0, 'attended': 0, 'totalClasses': 14};

        final percentage = (unitData['percentage'] ?? 0).toDouble();
        final attended = unitData['attended'] ?? 0;
        final total = unitData['totalClasses'] ?? 14;

        return Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    unitCode,
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 13,
                    ),
                  ),
                ),
                Text(
                  '${percentage.toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: percentage >= 75 ? Colors.green : Colors.red,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '$attended/$total',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: percentage / 100,
                minHeight: 8,
                backgroundColor: Colors.grey[200],
                color: percentage >= 75 ? Colors.green : Colors.red,
              ),
            ),
            const SizedBox(height: 12),
          ],
        );
      },
    );
  }

  // ==================== BUILD HOME SCREEN ====================
  Widget _buildHomeScreen() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.secondary],
        ),
      ),
      child: RefreshIndicator(
        onRefresh: _loadUserData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome Card
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: AppColors.primary,
                        child: Text(
                          _userName.isNotEmpty
                              ? _userName[0].toUpperCase()
                              : 'S',
                          style: const TextStyle(
                            fontSize: 24,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Welcome, $_userName',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Reg: $_userRegNumber',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                            if (_userCourse != 'Not Enrolled')
                              Container(
                                margin: const EdgeInsets.only(top: 4),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color:
                                      AppColors.primary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '📚 $_userCourse',
                                  style: TextStyle(
                                    color: AppColors.primary,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Stats Row
              Row(
                children: [
                  Expanded(
                    child: StatCard(
                      title: 'Attendance',
                      value: '${_attendanceRate.toStringAsFixed(1)}%',
                      icon: Icons.trending_up,
                      color:
                          _attendanceRate >= 75 ? Colors.green : Colors.orange,
                      onTap: () => setState(() => _selectedIndex = 1),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: StatCard(
                      title: 'Units',
                      value: '$_courseCount',
                      icon: Icons.menu_book,
                      color: Colors.blue,
                      onTap: () => setState(() => _selectedIndex = 2),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: StatCard(
                      title: 'Fees',
                      value: _pendingFees > 0
                          ? 'KSh ${_pendingFees.toStringAsFixed(0)}'
                          : 'Paid ✅',
                      icon: Icons.account_balance_wallet,
                      color: _pendingFees > 0 ? Colors.red : Colors.green,
                      onTap: () => setState(() => _selectedIndex = 3),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // ✅ Attendance Progress Section
              _buildAttendanceProgress(),
              const SizedBox(height: 16),

              // Course Section
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.school, color: AppColors.primary),
                          const SizedBox(width: 8),
                          Text(
                            'My Course',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (_userCourse != 'Not Enrolled') ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _userCourse,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (_userDepartment.isNotEmpty)
                                Text(
                                  _userDepartment,
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 12,
                                  ),
                                ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Registered Units: $_courseCount',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w500,
                                      color: Colors.grey[700],
                                    ),
                                  ),
                                  ElevatedButton(
                                    onPressed: () {
                                      setState(() => _selectedIndex = 2);
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.primary,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      minimumSize: Size.zero,
                                      tapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                    ),
                                    child: const Text(
                                      'View All',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Payment Section
              if (_pendingFees > 0) ...[
                Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.payment, color: Colors.green[700]),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Text(
                                'You have pending fees.',
                                style: TextStyle(fontSize: 14),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Total: KSh ${_totalFees.toStringAsFixed(0)}',
                              style: const TextStyle(fontSize: 12),
                            ),
                            Text(
                              'Paid: KSh ${_paidFees.toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.green,
                              ),
                            ),
                            Text(
                              'Balance: KSh ${_pendingFees.toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.red,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        PaymentButton(
                          studentId: _userUid,
                          studentName: _userName,
                          studentRegNumber: _userRegNumber,
                          amount: _pendingFees,
                          description: 'Fee Payment - $_userCourse',
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Quick Actions
              const Text(
                'Quick Actions',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _buildActionTile(
                    Icons.qr_code_scanner,
                    'Attendance',
                    Colors.green,
                    () => setState(() => _selectedIndex = 1),
                  ),
                  _buildActionTile(
                    Icons.qr_code,
                    'Scan QR',
                    Colors.indigo,
                    _scanQRCode,
                  ),
                  _buildActionTile(
                    Icons.assignment_add,
                    'Register',
                    Colors.orange,
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const UnitRegistrationScreen(),
                        ),
                      ).then((_) => _loadUserData());
                    },
                  ),
                  _buildActionTile(
                    Icons.support_agent,
                    'Support',
                    Colors.purple,
                    _showSupportDialog,
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Motivational Quote
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(16),
                  border:
                      Border.all(color: Colors.white.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.format_quote,
                        color: Colors.white, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Education is the most powerful weapon.',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontStyle: FontStyle.italic,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  // ==================== ACTION TILE ====================
  Widget _buildActionTile(
    IconData icon,
    String label,
    Color color,
    VoidCallback onTap,
  ) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(10),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withAlpha(15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==================== BUILD ====================
  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Student Dashboard'),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: _logout,
            ),
          ],
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                const SizedBox(height: 16),
                Text(
                  _errorMessage,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _loadUserData,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 12,
                    ),
                  ),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Welcome, $_userName'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (_selectedIndex == 0) {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
                (route) => false,
              );
            } else {
              setState(() {
                _selectedIndex = 0;
              });
            }
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'Logout',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            )
          : IndexedStack(
              index: _selectedIndex,
              children: _screens,
            ),
    );
  }
}
