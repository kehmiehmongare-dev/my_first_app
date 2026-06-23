import 'dart:convert';
import 'dart:typed_data';

import 'package:campus_flow/shared/constants/app_colors.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart' as fp;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AdminUploadLecturersScreen extends StatefulWidget {
  const AdminUploadLecturersScreen({super.key});

  @override
  State<AdminUploadLecturersScreen> createState() =>
      _AdminUploadLecturersScreenState();
}

class _AdminUploadLecturersScreenState
    extends State<AdminUploadLecturersScreen> {
  static const int _maxPreviewRows = 50;

  bool _isLoading = false;
  String _uploadStatus = '';
  int _successCount = 0;
  int _failedCount = 0;
  final List<String> _failedRows = [];
  final List<Map<String, dynamic>> _previewData = [];

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String _generateTemporaryPassword() {
    const chars =
        'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789!@#';
    final seed = DateTime.now().millisecondsSinceEpoch % 1000000;

    return List.generate(10, (index) {
      final charIndex = (index * 31 + seed) % chars.length;
      return chars[charIndex];
    }).join();
  }

  Future<bool> _emailExists(String email) async {
    try {
      final query = await _firestore
          .collection('users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();
      return query.docs.isNotEmpty;
    } catch (e) {
      debugPrint('Error checking email: $e');
      return false;
    }
  }

  List<List<String>> _parseCSV(String csvString) {
    final rows = <List<String>>[];
    final currentRow = <String>[];
    final currentField = StringBuffer();
    bool inQuotes = false;

    void commitField() {
      currentRow.add(currentField.toString().trim());
      currentField.clear();
    }

    void commitRow() {
      if (currentField.isNotEmpty || currentRow.isNotEmpty) {
        commitField();
        rows.add(List<String>.from(currentRow));
        currentRow.clear();
      }
    }

    for (int i = 0; i < csvString.length; i++) {
      final char = csvString[i];

      if (char == '"') {
        if (i + 1 < csvString.length && csvString[i + 1] == '"') {
          currentField.write('"');
          i++;
        } else {
          inQuotes = !inQuotes;
        }
      } else if (char == ',' && !inQuotes) {
        commitField();
      } else if ((char == '\n' || char == '\r') && !inQuotes) {
        if (char == '\r' && i + 1 < csvString.length && csvString[i + 1] == '\n') {
          i++;
        }
        commitRow();
      } else {
        currentField.write(char);
      }
    }

    commitRow();
    return rows;
  }

  Future<void> _pickAndPreviewFile() async {
    try {
      final result = await fp.FilePicker.pickFiles(
        type: fp.FileType.custom,
        allowedExtensions: ['csv'],
        withData: true,
      );

      if (result == null) {
        _showMessage('No file selected', Colors.orange);
        return;
      }

      final file = result.files.first;
      final Uint8List? bytes = file.bytes;

      if (bytes == null || bytes.isEmpty) {
        _showMessage('Failed to read file or file is empty', Colors.red);
        return;
      }

      final csvString = utf8.decode(bytes);
      final csvTable = _parseCSV(csvString);

      if (csvTable.isEmpty) {
        _showMessage('CSV file is empty', Colors.red);
        return;
      }

      final headers = csvTable.first.map((value) => value.trim()).toList();
      const expectedHeaders = [
        'Full Name',
        'Email',
        'Department',
        'Employee ID',
      ];

      final missingHeaders = expectedHeaders
          .where((header) => !headers.contains(header))
          .toList();

      if (missingHeaders.isNotEmpty) {
        _showMessage(
          'Missing columns: ${missingHeaders.join(', ')}',
          Colors.red,
        );
        return;
      }

      final fullNameIndex = headers.indexOf('Full Name');
      final emailIndex = headers.indexOf('Email');
      final departmentIndex = headers.indexOf('Department');
      final employeeIdIndex = headers.indexOf('Employee ID');

      final previewData = <Map<String, dynamic>>[];
      final failedRows = <String>[];
      var failedCount = 0;

      for (int rowIndex = 1; rowIndex < csvTable.length; rowIndex++) {
        final row = csvTable[rowIndex];
        if (row.length <= fullNameIndex ||
            row.length <= emailIndex ||
            row.length <= employeeIdIndex) {
          failedRows.add('Row ${rowIndex + 1}: Missing required fields');
          failedCount++;
          continue;
        }

        final lecturer = <String, dynamic>{
          'fullName': row[fullNameIndex].trim(),
          'email': row[emailIndex].trim().toLowerCase(),
          'department': departmentIndex < row.length &&
                  row[departmentIndex].trim().isNotEmpty
              ? row[departmentIndex].trim()
              : 'General',
          'employeeId': row[employeeIdIndex].trim(),
        };

        if (lecturer['fullName'].toString().isEmpty ||
            lecturer['email'].toString().isEmpty ||
            lecturer['employeeId'].toString().isEmpty) {
          failedRows.add('Row ${rowIndex + 1}: Missing required fields');
          failedCount++;
          continue;
        }

        previewData.add(lecturer);
      }

      setState(() {
        _previewData
          ..clear()
          ..addAll(previewData);
        _failedRows
          ..clear()
          ..addAll(failedRows);
        _successCount = previewData.length;
        _failedCount = failedCount;
        _uploadStatus = '✅ ${previewData.length} lecturers ready to upload';
      });

      _showMessage(
        '✅ ${previewData.length} lecturers loaded for preview',
        Colors.green,
      );
    } catch (e) {
      _showMessage('Error selecting file: $e', Colors.red);
      debugPrint('File selection error: $e');
    }
  }

  Future<void> _uploadLecturers() async {
    if (_previewData.isEmpty) {
      _showMessage('No lecturers to upload', Colors.red);
      return;
    }

    setState(() {
      _isLoading = true;
      _successCount = 0;
      _failedCount = 0;
      _failedRows.clear();
    });

    final uploaded = <Map<String, dynamic>>[];
    final adminId = _auth.currentUser?.uid ?? 'unknown';

    for (int index = 0; index < _previewData.length; index++) {
      final lecturerData = _previewData[index];
      final rowNumber = index + 2;

      try {
        final email = lecturerData['email']?.toString().trim() ?? '';
        final fullName = lecturerData['fullName']?.toString().trim() ?? '';
        final department =
            lecturerData['department']?.toString().trim() ?? 'General';
        final employeeId = lecturerData['employeeId']?.toString().trim() ?? '';
        final tempPassword = _generateTemporaryPassword();

        if (email.isEmpty || fullName.isEmpty || employeeId.isEmpty) {
          _failedRows.add('Row $rowNumber: Missing required fields');
          _failedCount++;
          continue;
        }

        if (!RegExp(r'^[\w-.]+@([\w-]+\.)+[\w-]{2,}$').hasMatch(email)) {
          _failedRows.add('Row $rowNumber: Invalid email format: $email');
          _failedCount++;
          continue;
        }

        if (await _emailExists(email)) {
          _failedRows.add('Row $rowNumber: $email - User already exists');
          _failedCount++;
          continue;
        }

        UserCredential userCredential;
        try {
          userCredential = await _auth.createUserWithEmailAndPassword(
            email: email,
            password: tempPassword,
          );
        } catch (e) {
          final errorMsg = e.toString();
          if (errorMsg.contains('email-already-in-use')) {
            _failedRows.add('Row $rowNumber: $email - User already exists in Auth');
          } else {
            _failedRows.add('Row $rowNumber: $email - Auth creation failed: $e');
          }
          _failedCount++;
          continue;
        }

        final user = userCredential.user;
        if (user == null) {
          _failedRows.add('Row $rowNumber: $email - User object is null');
          _failedCount++;
          continue;
        }

        try {
          final batch = _firestore.batch();

          batch.set(_firestore.collection('lecturers').doc(user.uid), {
            'displayName': fullName,
            'email': email,
            'employeeId': employeeId,
            'department': department,
            'designation': 'Lecturer',
            'phone': '',
            'courses': [],
            'createdAt': FieldValue.serverTimestamp(),
            'temporaryPassword': tempPassword,
            'isActive': true,
            'uid': user.uid,
          });

          batch.set(_firestore.collection('users').doc(user.uid), {
            'displayName': fullName,
            'email': email,
            'role': 'lecturer',
            'isActive': true,
            'createdAt': FieldValue.serverTimestamp(),
            'uid': user.uid,
          });

          await batch.commit();

          uploaded.add({
            'name': fullName,
            'email': email,
            'employeeId': employeeId,
            'tempPassword': tempPassword,
          });

          _successCount++;

          await _firestore.collection('system_logs').add({
            'type': 'user_upload',
            'role': 'lecturer',
            'email': email,
            'fullName': fullName,
            'employeeId': employeeId,
            'timestamp': FieldValue.serverTimestamp(),
            'adminId': adminId,
          });
        } catch (e) {
          _failedRows.add('Row $rowNumber: $email - Firestore save failed: $e');
          _failedCount++;

          try {
            await user.delete();
          } catch (_) {
            // Ignore delete errors.
          }
        }
      } catch (e) {
        _failedRows.add('Row $rowNumber: Unexpected error: $e');
        _failedCount++;
      }
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _isLoading = false;
      _uploadStatus = '✅ $_successCount lecturers uploaded, $_failedCount failed';
    });

    if (uploaded.isNotEmpty) {
      _showCredentialsDialog(uploaded);
    }

    _showMessage(
      '✅ $_successCount lecturers uploaded, $_failedCount failed',
      _successCount > 0 ? Colors.green : Colors.red,
    );
  }

  void _showCredentialsDialog(List<Map<String, dynamic>> uploaded) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Lecturer Credentials'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'The following lecturers have been created:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              ...uploaded.map(
                (user) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('👤 ${user['name']}'),
                        Text(
                          '📧 ${user['email']}',
                          style: const TextStyle(fontSize: 12),
                        ),
                        Text(
                          '🔑 ${user['tempPassword']}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.blue,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Please share these credentials with the lecturers securely.',
                style: TextStyle(fontSize: 12, color: Colors.orange),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showMessage(String message, Color color) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.upload_file, size: 40, color: AppColors.primary),
            const SizedBox(height: 8),
            const Text(
              'Bulk Lecturer Upload',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Upload CSV file with lecturer data',
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
                    'Required CSV Format:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Full Name, Email, Department, Employee ID',
                    style: TextStyle(fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Example: Dr. James Wilson, jw@mku.ac.ke, Computer Science, LEC001',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Lecturers use their provided email for login',
                    style: TextStyle(fontSize: 12, color: Colors.blue),
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
    );
  }

  Widget _buildPreviewCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Preview',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${_previewData.length} lecturers',
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
                itemCount:
                    _previewData.length > _maxPreviewRows ? _maxPreviewRows : _previewData.length,
                itemBuilder: (context, index) {
                  final lecturer = _previewData[index];
                  return ListTile(
                    dense: true,
                    leading: CircleAvatar(
                      backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                      radius: 12,
                      child: Text(
                        '${index + 1}',
                        style: TextStyle(
                          fontSize: 10,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    title: Text(
                      lecturer['fullName'].toString(),
                      style: const TextStyle(fontSize: 13),
                    ),
                    subtitle: Text(
                      '${lecturer['department']} • ${lecturer['employeeId']}',
                      style: const TextStyle(fontSize: 11),
                    ),
                    trailing: Text(
                      lecturer['email'].toString(),
                      style: const TextStyle(fontSize: 10, color: Colors.grey),
                    ),
                  );
                },
              ),
            ),
            if (_previewData.length > _maxPreviewRows)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'Showing $_maxPreviewRows of ${_previewData.length} lecturers',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 45,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _uploadLecturers,
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
                    : Text('Upload ${_previewData.length} Lecturers'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard() {
    return Card(
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
            if (_failedRows.isNotEmpty) ...[
              const SizedBox(height: 8),
              const Text(
                'Failed:',
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
              ),
              Container(
                constraints: const BoxConstraints(maxHeight: 100),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: _failedRows
                        .map(
                          (row) => Padding(
                            padding: const EdgeInsets.only(bottom: 2),
                            child: Text(
                              '• $row',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.red[700],
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
              ),
            ],
            if (_successCount > 0) ...[
              const SizedBox(height: 8),
              const Divider(),
              Text(
                '✅ Successfully uploaded: $_successCount lecturers',
                style: const TextStyle(color: Colors.green),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Upload Lecturers'),
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
              _buildInfoCard(),
              if (_previewData.isNotEmpty) ...[
                const SizedBox(height: 16),
                _buildPreviewCard(),
              ],
              if (_uploadStatus.isNotEmpty) ...[
                const SizedBox(height: 16),
                _buildStatusCard(),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
