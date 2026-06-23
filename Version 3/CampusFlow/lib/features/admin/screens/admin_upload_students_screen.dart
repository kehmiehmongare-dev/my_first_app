import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart' as fp;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:campus_flow/shared/constants/app_colors.dart';
import 'package:campus_flow/services/email_service.dart';

class AdminUploadStudentsScreen extends StatefulWidget {
  const AdminUploadStudentsScreen({super.key});

  @override
  State<AdminUploadStudentsScreen> createState() =>
      _AdminUploadStudentsScreenState();
}

class _AdminUploadStudentsScreenState extends State<AdminUploadStudentsScreen> {
  bool _isLoading = false;
  String _uploadStatus = '';
  int _successCount = 0;
  int _failedCount = 0;
  int _emailCount = 0;
  final List<String> _failedRows = [];
  final List<Map<String, dynamic>> _previewData = [];

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String _generateTemporaryPassword() {
    final chars =
        'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789!@#';
    final random = DateTime.now().millisecondsSinceEpoch;
    final int seed = random.toInt();
    return List.generate(10, (i) => chars[(seed + i) % chars.length]).join();
  }

  String _generateStudentEmail(String regNumber) {
    return '${regNumber.toLowerCase()}@mylife.mku.ac.ke';
  }

  List<List<String>> _parseCSV(String csvString) {
    List<List<String>> result = [];
    List<String> currentRow = [];
    String currentField = '';
    bool inQuotes = false;

    for (int i = 0; i < csvString.length; i++) {
      String char = csvString[i];

      if (char == '"') {
        inQuotes = !inQuotes;
      } else if (char == ',' && !inQuotes) {
        currentRow.add(currentField.trim());
        currentField = '';
      } else if ((char == '\n' || char == '\r') && !inQuotes) {
        if (char == '\r' &&
            i + 1 < csvString.length &&
            csvString[i + 1] == '\n') {
          i++;
        }
        if (currentField.isNotEmpty || currentRow.isNotEmpty) {
          currentRow.add(currentField.trim());
          result.add(currentRow);
        }
        currentRow = [];
        currentField = '';
      } else {
        currentField += char;
      }
    }

    if (currentField.isNotEmpty || currentRow.isNotEmpty) {
      currentRow.add(currentField.trim());
      result.add(currentRow);
    }

    return result;
  }

  // ✅ Fixed: Use FilePicker.pickFiles() without platform
  Future<void> _pickAndPreviewFile() async {
    try {
      // Use FilePicker.pickFiles for compatibility
      fp.FilePickerResult? result = await fp.FilePicker.pickFiles(
        type: fp.FileType.custom,
        allowedExtensions: ['csv'],
      );

      if (result == null) return;

      final file = result.files.single;
      final bytes = file.bytes;

      if (bytes == null || bytes.isEmpty) {
        _showMessage('File is empty', Colors.red);
        return;
      }

      String csvString = utf8.decode(bytes);
      List<List<String>> csvTable = _parseCSV(csvString);

      if (csvTable.isEmpty) {
        _showMessage('CSV file is empty', Colors.red);
        return;
      }

      final headers = csvTable[0];
      final expectedHeaders = [
        'Full Name',
        'Registration Number',
        'Course',
        'Semester'
      ];
      final missingHeaders =
          expectedHeaders.where((h) => !headers.contains(h)).toList();

      if (missingHeaders.isNotEmpty) {
        _showMessage(
            'Missing columns: ${missingHeaders.join(', ')}', Colors.red);
        return;
      }

      setState(() {
        _previewData.clear();
        _failedRows.clear();
        _successCount = 0;
        _failedCount = 0;
        _emailCount = 0;
      });

      for (int i = 1; i < csvTable.length; i++) {
        final row = csvTable[i];
        if (row.length >= 4) {
          final Map<String, dynamic> student = {
            'fullName': row[0].trim(),
            'regNumber': row[1].trim().toUpperCase(),
            'course': row[2].trim(),
            'semester': int.tryParse(row[3].trim()) ?? 1,
          };

          if (student['fullName'].isNotEmpty &&
              student['regNumber'].isNotEmpty) {
            _previewData.add(student);
          }
        }
      }

      setState(() {
        _uploadStatus = '✅ ${_previewData.length} students ready to upload';
        _successCount = _previewData.length;
      });

      _showMessage(
          '✅ ${_previewData.length} students loaded for preview', Colors.green);
    } catch (e) {
      _showMessage('Error reading file: $e', Colors.red);
    }
  }

  // ✅ Fixed: Properly structured upload method
  Future<void> _uploadStudents() async {
    if (_previewData.isEmpty) {
      _showMessage('No students to upload', Colors.red);
      return;
    }

    setState(() {
      _isLoading = true;
      _successCount = 0;
      _failedCount = 0;
      _failedRows.clear();
      _emailCount = 0;
    });

    List<Map<String, dynamic>> createdUsers = [];

    for (var studentData in _previewData) {
      try {
        final regNumber = studentData['regNumber'];
        final fullName = studentData['fullName'];
        final course = studentData['course'];
        final semester = studentData['semester'];

        final email = _generateStudentEmail(regNumber);
        final tempPassword = _generateTemporaryPassword();

        UserCredential? userCredential;
        try {
          userCredential = await _auth.createUserWithEmailAndPassword(
            email: email,
            password: tempPassword,
          );
          debugPrint('Auth user created: $email');
        } catch (e) {
          if (e.toString().contains('email-already-in-use')) {
            debugPrint('User already exists: $email');
            _failedCount++;
            _failedRows.add('$regNumber - User already exists');
            continue;
          } else {
            _failedCount++;
            _failedRows.add('$regNumber - Auth creation failed: $e');
            continue;
          }
        }

        final user = userCredential.user;
        if (user == null) {
          _failedCount++;
          _failedRows.add('$regNumber - Failed to create user');
          continue;
        }

        // ✅ Save to Firestore
        await _firestore.collection('students').doc(user.uid).set({
          'displayName': fullName,
          'email': email,
          'regNumber': regNumber,
          'course': course ?? 'Not Enrolled',
          'department': '',
          'registeredUnits': [],
          'totalFees': 60000,
          'paidFees': 0,
          'pendingFees': 60000,
          'attendanceRate': 0,
          'temporaryPassword': tempPassword,
          'authCreated': true,
          'createdAt': FieldValue.serverTimestamp(),
        });

        await _firestore.collection('users').doc(user.uid).set({
          'displayName': fullName,
          'email': email,
          'role': 'student',
          'isActive': true,
          'createdAt': FieldValue.serverTimestamp(),
          'lastLogin': FieldValue.serverTimestamp(),
        });

        _successCount++;
        createdUsers.add({
          'email': email,
          'fullName': fullName,
          'regNumber': regNumber,
          'tempPassword': tempPassword,
        });
      } catch (e) {
        _failedCount++;
        _failedRows.add('${studentData['regNumber']} - $e');
        debugPrint('Upload error: $e');
      }
    }

    // Send emails
    if (createdUsers.isNotEmpty) {
      await _sendEmails(createdUsers, 'student');
    }

    setState(() {
      _isLoading = false;
      _uploadStatus =
          '✅ $_successCount students uploaded, $_failedCount failed, $_emailCount emails sent';
    });

    _showMessage(
      '✅ $_successCount students uploaded, $_emailCount emails sent',
      _successCount > 0 ? Colors.green : Colors.red,
    );
  }

  Future<void> _sendEmails(
      List<Map<String, dynamic>> users, String role) async {
    for (var user in users) {
      try {
        await EmailService.sendCredentials(
          email: user['email'],
          name: user['fullName'],
          identifier: user['regNumber'],
          password: user['tempPassword'],
          role: role,
        );
        _emailCount++;
        setState(() {
          _uploadStatus =
              '✅ $_successCount students uploaded, $_failedCount failed, $_emailCount emails sent';
        });
        await Future.delayed(const Duration(seconds: 1));
      } catch (e) {
        debugPrint('Email error: $e');
      }
    }
  }

  // ✅ Fixed: Defined _showMessage method
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
        title: const Text('Upload Students'),
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.upload_file,
                          size: 40, color: AppColors.primary),
                      const SizedBox(height: 8),
                      const Text(
                        'Bulk Student Upload',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Upload CSV file with student data',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '📋 Required CSV Format:',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Full Name, Registration Number, Course, Semester',
                              style: TextStyle(fontSize: 12),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Example: Naom Mongare, BIT202459115, BSc IT, 2',
                              style:
                                  TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              '📧 Emails will be auto-generated: regnumber@mylife.mku.ac.ke',
                              style:
                                  TextStyle(fontSize: 12, color: Colors.blue),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton.icon(
                          onPressed: _isLoading ? null : _pickAndPreviewFile,
                          icon: const Icon(Icons.cloud_upload),
                          label: const Text('Select CSV File'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (_previewData.isNotEmpty) ...[
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              '📋 Preview',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '${_previewData.length} students',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Container(
                          height: 200,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: ListView.builder(
                            padding: const EdgeInsets.all(8),
                            itemCount: _previewData.length > 50
                                ? 50
                                : _previewData.length,
                            itemBuilder: (context, index) {
                              final student = _previewData[index];
                              return ListTile(
                                dense: true,
                                leading: CircleAvatar(
                                  backgroundColor:
                                      AppColors.primary.withValues(alpha: 0.1),
                                  radius: 12,
                                  child: Text(
                                    '${index + 1}',
                                    style: TextStyle(
                                        fontSize: 10, color: AppColors.primary),
                                  ),
                                ),
                                title: Text(
                                  student['fullName'],
                                  style: const TextStyle(fontSize: 13),
                                ),
                                subtitle: Text(
                                  '${student['regNumber']} • ${student['course']}',
                                  style: const TextStyle(fontSize: 11),
                                ),
                                trailing: Text(
                                  'Sem ${student['semester']}',
                                  style: const TextStyle(fontSize: 11),
                                ),
                              );
                            },
                          ),
                        ),
                        if (_previewData.length > 50)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              'Showing 50 of ${_previewData.length} students',
                              style: TextStyle(
                                  fontSize: 12, color: Colors.grey[600]),
                            ),
                          ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          height: 45,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _uploadStudents,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Text(
                                    'Upload ${_previewData.length} Students'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              if (_uploadStatus.isNotEmpty) ...[
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Upload Status',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(_uploadStatus),
                        if (_failedCount > 0) ...[
                          const SizedBox(height: 8),
                          const Text(
                            'Failed:',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, color: Colors.red),
                          ),
                          ..._failedRows.map((row) => Text(
                                '• $row',
                                style: TextStyle(
                                    fontSize: 12, color: Colors.red[700]),
                              )),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
