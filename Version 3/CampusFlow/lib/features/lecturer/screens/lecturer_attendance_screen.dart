import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:campus_flow/shared/constants/app_colors.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'dart:convert';
import 'dart:async';

class LecturerAttendanceScreen extends StatefulWidget {
  const LecturerAttendanceScreen({super.key});

  @override
  State<LecturerAttendanceScreen> createState() =>
      _LecturerAttendanceScreenState();
}

class _LecturerAttendanceScreenState extends State<LecturerAttendanceScreen> {
  // ==================== STATE ====================
  bool _isLoading = true;
  bool _isGenerating = false;
  bool _showQR = false;
  String _qrData = '';
  String _qrSessionId = '';
  final int _qrExpirySeconds = 300;
  Timer? _qrTimer;
  int _timeLeft = 300;

  String _currentTime = '';
  Timer? _clockTimer;

  String _lecturerName = '';
  String? _selectedUnit;
  String? _selectedRoom;
  Map<String, String> _lecturerRooms = {};

  List<String> _lecturerUnits = [];
  List<Map<String, dynamic>> _students = [];
  final Map<String, String> _attendanceStatus = {};

  // ==================== INIT ====================
  @override
  void initState() {
    super.initState();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _currentTime = DateFormat('hh:mm a').format(DateTime.now());
        });
      }
    });
    _loadData();
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    _qrTimer?.cancel();
    super.dispose();
  }

  // ==================== LOAD DATA ====================
  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _showMessage('Please login again', Colors.red);
        setState(() => _isLoading = false);
        return;
      }

      final lecturerDoc = await FirebaseFirestore.instance
          .collection('lecturers')
          .doc(user.uid)
          .get();

      if (!lecturerDoc.exists) {
        _showMessage('Profile not found', Colors.red);
        setState(() => _isLoading = false);
        return;
      }

      final data = lecturerDoc.data() as Map<String, dynamic>;
      _lecturerName = data['displayName'] ?? 'Lecturer';
      _lecturerUnits = List<String>.from(data['units'] ?? []);

      // Load rooms map
      _lecturerRooms = {};
      final roomsData = data['rooms'];
      if (roomsData != null && roomsData is Map) {
        _lecturerRooms = Map<String, String>.from(roomsData);
      }

      if (_lecturerUnits.isNotEmpty) {
        _selectedUnit = _lecturerUnits.first;
        _selectedRoom = _lecturerRooms[_selectedUnit] ?? 'Not Assigned';
        await _loadStudentsForUnit(_selectedUnit!);
      }

      setState(() => _isLoading = false);
    } catch (e) {
      _showMessage('Error loading data', Colors.red);
      setState(() => _isLoading = false);
    }
  }

  // ==================== LOAD STUDENTS ====================
  Future<void> _loadStudentsForUnit(String unitCode) async {
    setState(() => _isLoading = true);

    try {
      final studentsSnapshot =
          await FirebaseFirestore.instance.collection('students').get();

      _students = studentsSnapshot.docs.where((doc) {
        final data = doc.data();
        final units = _getRegisteredUnits(data);
        return units.contains(unitCode);
      }).map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();

      _attendanceStatus.clear();
      for (var student in _students) {
        _attendanceStatus[student['id']] = 'absent';
      }

      setState(() => _isLoading = false);
    } catch (e) {
      _showMessage('Error loading students', Colors.red);
      setState(() => _isLoading = false);
    }
  }

  List<String> _getRegisteredUnits(Map<String, dynamic> data) {
    final units = data['registeredUnits'];
    if (units == null) return [];
    if (units is List) {
      if (units.isNotEmpty) {
        if (units[0] is String) return List<String>.from(units);
        if (units[0] is Map) {
          return units
              .map((e) => (e as Map<String, dynamic>)['code']?.toString() ?? '')
              .where((e) => e.isNotEmpty)
              .toList();
        }
      }
    }
    return [];
  }

  // ==================== GENERATE QR ====================
  Future<void> _generateQR() async {
    if (_selectedUnit == null) {
      _showMessage('Select a unit', Colors.orange);
      return;
    }

    if (_students.isEmpty) {
      _showMessage('No students registered', Colors.orange);
      return;
    }

    setState(() {
      _isGenerating = true;
      _showQR = false;
      _timeLeft = _qrExpirySeconds;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _showMessage('Please login again', Colors.red);
        setState(() => _isGenerating = false);
        return;
      }

      final now = DateTime.now();
      _qrSessionId = now.millisecondsSinceEpoch.toString();

      final qrData = {
        'sessionId': _qrSessionId,
        'unitCode': _selectedUnit,
        'lecturerId': user.uid,
        'room': _selectedRoom ?? 'Not Assigned',
        'timestamp': now.millisecondsSinceEpoch,
        'expiresAt':
            now.add(Duration(seconds: _qrExpirySeconds)).millisecondsSinceEpoch,
      };

      await FirebaseFirestore.instance
          .collection('attendance_sessions')
          .doc(_qrSessionId)
          .set({
        ...qrData,
        'students': [],
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
      });

      _qrData = json.encode(qrData);
      _showQR = true;

      _qrTimer?.cancel();
      _qrTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        setState(() {
          _timeLeft--;
          if (_timeLeft <= 0) {
            timer.cancel();
            _showQR = false;
            _showMessage('QR Expired', Colors.orange);
          }
        });
      });

      _showMessage('✅ QR Ready! 5 min', Colors.green);
    } catch (e) {
      _showMessage('Error generating QR', Colors.red);
    }

    setState(() => _isGenerating = false);
  }

  // ==================== SUBMIT ATTENDANCE ====================
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
            'unitCode': _selectedUnit,
            'room': _selectedRoom,
            'lecturerId': user?.uid,
            'date': today,
            'status': status,
            'timestamp': FieldValue.serverTimestamp(),
          });
          markedCount++;
        }
      }

      _showMessage('✅ $markedCount students marked!', Colors.green);
      await _loadStudentsForUnit(_selectedUnit!);
    } catch (e) {
      _showMessage('❌ Error submitting', Colors.red);
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
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  // ==================== BUILD ====================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
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
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // ==================== HEADER CARD ====================
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '👋 $_lecturerName',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.location_on,
                                      size: 14,
                                      color: Colors.grey[600],
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      _selectedRoom ?? 'Not Assigned',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              _currentTime,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.green.shade700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ==================== UNIT & QR CARD ====================
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          // Unit Dropdown
                          DropdownButtonFormField<String>(
                            initialValue: _selectedUnit,
                            decoration: const InputDecoration(
                              labelText: 'Select Unit',
                              border: OutlineInputBorder(),
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                            ),
                            items: _lecturerUnits.map((unit) {
                              return DropdownMenuItem(
                                value: unit,
                                child: Text(unit),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedUnit = value;
                                if (value != null) {
                                  _selectedRoom =
                                      _lecturerRooms[value] ?? 'Not Assigned';
                                  _loadStudentsForUnit(value);
                                }
                              });
                            },
                          ),
                          const SizedBox(height: 12),

                          // QR Button + Timer
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  '👥 ${_students.length} students',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              if (_showQR) ...[
                                Icon(
                                  Icons.timer,
                                  color: _timeLeft > 60
                                      ? Colors.green
                                      : Colors.red,
                                  size: 18,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${(_timeLeft / 60).floor()}:${(_timeLeft % 60).toString().padLeft(2, '0')}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: _timeLeft > 60
                                        ? Colors.green
                                        : Colors.red,
                                  ),
                                ),
                                const SizedBox(width: 8),
                              ],
                              ElevatedButton.icon(
                                onPressed: _isGenerating ? null : _generateQR,
                                icon: _isGenerating
                                    ? const SizedBox(
                                        height: 16,
                                        width: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Icon(Icons.qr_code, size: 18),
                                label:
                                    Text(_showQR ? 'Regenerate' : 'Generate'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 10,
                                  ),
                                  minimumSize: Size.zero,
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                              ),
                            ],
                          ),

                          // QR Display
                          if (_showQR) ...[
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Center(
                                child: QrImageView(
                                  data: _qrData,
                                  version: QrVersions.auto,
                                  size: 160,
                                  gapless: false,
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '📱 Students scan to mark attendance',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ==================== STUDENT LIST CARD ====================
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          // Select All
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Row(
                              children: [
                                Checkbox(
                                  value: _students.isNotEmpty &&
                                      _students.every((s) =>
                                          _attendanceStatus[s['id']] ==
                                          'present'),
                                  onChanged: _toggleSelectAll,
                                  activeColor: AppColors.primary,
                                  materialTapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                                const Text(
                                  'Select All',
                                  style: TextStyle(fontSize: 13),
                                ),
                                const Spacer(),
                                Text(
                                  '${_students.length} students',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Divider(height: 1),

                          // Students
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _students.length,
                            itemBuilder: (context, index) {
                              final student = _students[index];
                              final status =
                                  _attendanceStatus[student['id']] ?? 'absent';
                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 14,
                                      backgroundColor: AppColors.primary
                                          .withValues(alpha: 0.1),
                                      child: Text(
                                        (student['displayName'] ?? 'S')[0],
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            student['displayName'] ?? 'Student',
                                            style: const TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w500,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          Text(
                                            student['regNumber'] ?? 'N/A',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    DropdownButton<String>(
                                      value: status,
                                      underline: const SizedBox(),
                                      icon: const Icon(Icons.arrow_drop_down,
                                          size: 20),
                                      items: const [
                                        DropdownMenuItem(
                                          value: 'present',
                                          child: Row(
                                            children: [
                                              Icon(Icons.check_circle,
                                                  color: Colors.green,
                                                  size: 14),
                                              SizedBox(width: 4),
                                              Text('Present',
                                                  style:
                                                      TextStyle(fontSize: 12)),
                                            ],
                                          ),
                                        ),
                                        DropdownMenuItem(
                                          value: 'late',
                                          child: Row(
                                            children: [
                                              Icon(Icons.access_time,
                                                  color: Colors.orange,
                                                  size: 14),
                                              SizedBox(width: 4),
                                              Text('Late',
                                                  style:
                                                      TextStyle(fontSize: 12)),
                                            ],
                                          ),
                                        ),
                                        DropdownMenuItem(
                                          value: 'absent',
                                          child: Row(
                                            children: [
                                              Icon(Icons.cancel,
                                                  color: Colors.red, size: 14),
                                              SizedBox(width: 4),
                                              Text('Absent',
                                                  style:
                                                      TextStyle(fontSize: 12)),
                                            ],
                                          ),
                                        ),
                                      ],
                                      onChanged: (value) => setState(() {
                                        if (value != null) {
                                          _attendanceStatus[student['id']] =
                                              value;
                                        }
                                      }),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),

                          // Submit Button
                          if (_students.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.all(12),
                              child: SizedBox(
                                width: double.infinity,
                                height: 44,
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
                                    style: TextStyle(fontSize: 15),
                                  ),
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
    );
  }
}
