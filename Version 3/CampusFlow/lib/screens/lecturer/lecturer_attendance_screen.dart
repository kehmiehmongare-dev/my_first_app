import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:campus_flow/shared/constants/app_colors.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'dart:convert';

class LecturerAttendanceScreen extends StatefulWidget {
  const LecturerAttendanceScreen({super.key});

  @override
  State<LecturerAttendanceScreen> createState() =>
      _LecturerAttendanceScreenState();
}

class _LecturerAttendanceScreenState extends State<LecturerAttendanceScreen> {
  List<Map<String, dynamic>> _students = [];
  final Map<String, String> _attendanceStatus = {};
  bool _isLoading = true;
  String? _selectedCourse;
  List<String> _lecturerCourses = [];

  @override
  void initState() {
    super.initState();
    _loadLecturerCourses();
  }

  Future<void> _loadLecturerCourses() async {
    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final doc = await FirebaseFirestore.instance
            .collection('lecturers')
            .doc(user.uid)
            .get();

        if (doc.exists) {
          final data = doc.data() as Map<String, dynamic>;
          _lecturerCourses = List<String>.from(data['courses'] ?? []);
        }
      }
      if (_lecturerCourses.isEmpty) {
        _lecturerCourses = ['IT301', 'IT302', 'IT303'];
      }
      if (_lecturerCourses.isNotEmpty) {
        _selectedCourse = _lecturerCourses.first;
        await _loadStudentsForCourse(_selectedCourse!);
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint('Error loading lecturer courses: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadStudentsForCourse(String courseCode) async {
    setState(() => _isLoading = true);

    try {
      final studentsSnapshot =
          await FirebaseFirestore.instance.collection('students').get();

      final filteredStudents = studentsSnapshot.docs.where((doc) {
        final data = doc.data();
        final registeredUnits =
            List<String>.from(data['registeredUnits'] ?? []);
        return registeredUnits.contains(courseCode);
      }).toList();

      _students = filteredStudents.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();

      _attendanceStatus.clear();
      for (var student in _students) {
        _attendanceStatus[student['id']] = 'absent';
      }

      debugPrint(
          '✅ Loaded ${_students.length} students for course: $courseCode');
      setState(() => _isLoading = false);
    } catch (e) {
      debugPrint('Error loading students: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _generateQR() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _showMessage('Please login again', Colors.red);
        return;
      }

      if (_selectedCourse == null) {
        _showMessage('Please select a course', Colors.orange);
        return;
      }

      final sessionId = DateTime.now().millisecondsSinceEpoch.toString();

      await FirebaseFirestore.instance
          .collection('attendance_sessions')
          .doc(sessionId)
          .set({
        'sessionId': sessionId,
        'lecturerId': user.uid,
        'courseCode': _selectedCourse,
        'date': DateTime.now().toIso8601String(),
        'timestamp': FieldValue.serverTimestamp(),
        'isActive': true,
        'students': [],
      });

      final qrData = {
        'sessionId': sessionId,
        'courseCode': _selectedCourse,
        'lecturerId': user.uid,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };

      _showQRCodeDialog(qrData);
    } catch (e) {
      _showMessage('Error generating QR: $e', Colors.red);
    }
  }

  void _showQRCodeDialog(Map<String, dynamic> qrData) {
    final qrString = json.encode(qrData);
    int scannedCount = 0;
    final sessionId = qrData['sessionId'];

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) {
          FirebaseFirestore.instance
              .collection('attendance_sessions')
              .doc(sessionId)
              .snapshots()
              .listen((snapshot) {
            if (snapshot.exists) {
              final data = snapshot.data() as Map<String, dynamic>;
              final students = List<String>.from(data['students'] ?? []);
              setStateDialog(() {
                scannedCount = students.length;
              });
            }
          });

          return AlertDialog(
            title: Row(
              children: [
                Icon(Icons.qr_code, color: AppColors.primary),
                const SizedBox(width: 8),
                const Text('QR Code - Attendance'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 20,
                      ),
                    ],
                  ),
                  child: QrImageView(
                    data: qrString,
                    version: QrVersions.auto,
                    size: 300,
                    gapless: false,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Course: ${qrData['courseCode']}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Session ID: ${qrData['sessionId']}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Column(
                      children: [
                        const Text(
                          '👥 Scanned',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        Text(
                          '$scannedCount',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    '📱 Students: Show this QR Code on screen',
                    style: TextStyle(fontSize: 14, color: Colors.blue),
                  ),
                ),
              ],
            ),
            actions: [
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  _showMessage('✅ QR Code session closed', Colors.orange);
                },
                icon: const Icon(Icons.close),
                label: const Text('Close Session'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _submitAttendance() async {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    int markedCount = 0;

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;

      for (var student in _students) {
        final status = _attendanceStatus[student['id']];
        if (status != null && status != 'absent') {
          await FirebaseFirestore.instance.collection('attendance').add({
            'studentId': student['id'],
            'studentName': student['displayName'] ?? 'Student',
            'studentRegNumber': student['regNumber'] ?? 'N/A',
            'courseCode': _selectedCourse ?? 'General',
            'lecturerId': user?.uid,
            'date': today,
            'status': status,
            'timestamp': FieldValue.serverTimestamp(),
          });
          markedCount++;
        }
      }

      _showMessage(
          '✅ Attendance marked for $markedCount students!', Colors.green);
      await _loadStudentsForCourse(_selectedCourse!);
    } catch (e) {
      _showMessage('❌ Error: $e', Colors.red);
    }

    setState(() => _isLoading = false);
  }

  void _toggleSelectAll(bool? value) {
    setState(() {
      for (var student in _students) {
        _attendanceStatus[student['id']] = value == true ? 'present' : 'absent';
      }
    });
  }

  void _showMessage(String message, Color color) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: color,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mark Attendance'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              if (_selectedCourse != null) {
                _loadStudentsForCourse(_selectedCourse!);
              }
            },
          ),
        ],
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
            : Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    color: Colors.white,
                    child: Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: _selectedCourse,
                            decoration: const InputDecoration(
                              labelText: 'Select Course',
                              border: OutlineInputBorder(),
                            ),
                            items: _lecturerCourses.map((course) {
                              return DropdownMenuItem(
                                value: course,
                                child: Text(course),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedCourse = value;
                                if (value != null) {
                                  _loadStudentsForCourse(value);
                                }
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          onPressed: _students.isEmpty ? null : _generateQR,
                          icon: const Icon(Icons.qr_code),
                          label: const Text('QR'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    color: Colors.grey.shade100,
                    child: Row(
                      children: [
                        Checkbox(
                          value: _students.isNotEmpty &&
                              _students.every((s) =>
                                  _attendanceStatus[s['id']] == 'present'),
                          onChanged: _toggleSelectAll,
                          activeColor: AppColors.primary,
                        ),
                        const Text('Select All'),
                        const Spacer(),
                        Text(
                          '${_students.length} students',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: _students.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.people_outline,
                                  size: 64,
                                  color: Colors.white.withValues(alpha: 0.5),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  _lecturerCourses.isEmpty
                                      ? 'No courses assigned'
                                      : 'No students in this course',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.8),
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(8),
                            itemCount: _students.length,
                            itemBuilder: (context, index) {
                              final student = _students[index];
                              return Card(
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: AppColors.primary
                                        .withValues(alpha: 0.1),
                                    child: Text(
                                      (student['displayName'] ?? 'S')[0],
                                      style: const TextStyle(
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ),
                                  title: Text(
                                    student['displayName'] ?? 'Student',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  subtitle: Text(
                                    student['regNumber'] ?? 'N/A',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  trailing: DropdownButton<String>(
                                    value: _attendanceStatus[student['id']],
                                    underline: const SizedBox(),
                                    items: const [
                                      DropdownMenuItem(
                                        value: 'present',
                                        child: Row(
                                          children: [
                                            Icon(Icons.check_circle,
                                                color: Colors.green, size: 16),
                                            SizedBox(width: 4),
                                            Text('Present',
                                                style: TextStyle(
                                                    color: Colors.green)),
                                          ],
                                        ),
                                      ),
                                      DropdownMenuItem(
                                        value: 'late',
                                        child: Row(
                                          children: [
                                            Icon(Icons.access_time,
                                                color: Colors.orange, size: 16),
                                            SizedBox(width: 4),
                                            Text('Late',
                                                style: TextStyle(
                                                    color: Colors.orange)),
                                          ],
                                        ),
                                      ),
                                      DropdownMenuItem(
                                        value: 'absent',
                                        child: Row(
                                          children: [
                                            Icon(Icons.cancel,
                                                color: Colors.red, size: 16),
                                            SizedBox(width: 4),
                                            Text('Absent',
                                                style: TextStyle(
                                                    color: Colors.red)),
                                          ],
                                        ),
                                      ),
                                    ],
                                    onChanged: (value) => setState(() =>
                                        _attendanceStatus[student['id']] =
                                            value!),
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                  if (_students.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.all(16),
                      child: SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _submitAttendance,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Submit Attendance',
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
      ),
    );
  }
}
