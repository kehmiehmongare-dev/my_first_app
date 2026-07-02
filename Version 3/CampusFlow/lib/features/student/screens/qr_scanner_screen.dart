import 'package:flutter/material.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import 'package:campus_flow/shared/constants/app_colors.dart';
import 'package:campus_flow/services/offline_attendance_db.dart';
import 'package:campus_flow/services/sync_service.dart';

class QRScannerScreen extends StatefulWidget {
  final Function(Map<String, dynamic>) onScanComplete;
  final String studentName;
  final String studentRegNumber;

  const QRScannerScreen({
    super.key,
    required this.onScanComplete,
    required this.studentName,
    required this.studentRegNumber,
  });

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  QRViewController? controller;
  bool _isScanning = true;
  bool _isProcessing = false;

  final OfflineAttendanceDB _db = OfflineAttendanceDB();
  final SyncService _syncService = SyncService();

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  void _onQRViewCreated(QRViewController controller) {
    this.controller = controller;

    controller.scannedDataStream.listen((scanData) {
      if (_isScanning && !_isProcessing) {
        _isScanning = false;
        _handleQRCode(scanData.code ?? '');
      }
    });
  }

  Future<void> _handleQRCode(String code) async {
    setState(() => _isProcessing = true);

    try {
      final data = json.decode(code) as Map<String, dynamic>;

      // ✅ Validate QR data
      if (!data.containsKey('sessionId') || !data.containsKey('unitCode')) {
        _showMessage('Invalid QR Code', Colors.red);
        setState(() => _isProcessing = false);
        return;
      }

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _showMessage('Please login again', Colors.red);
        setState(() => _isProcessing = false);
        return;
      }

      // ✅ Check internet
      final hasInternet = await _syncService.hasInternet();

      if (hasInternet) {
        // ✅ ONLINE: Mark directly
        await _markOnline(data, user);
      } else {
        // ✅ OFFLINE: Save to SQLite
        await _markOffline(data, user);
      }
    } catch (e) {
      _showMessage('Error: $e', Colors.red);
      setState(() => _isProcessing = false);
    }
  }

  // ✅ Online marking
  Future<void> _markOnline(Map<String, dynamic> data, User user) async {
    try {
      // ✅ Check session
      final sessionDoc = await FirebaseFirestore.instance
          .collection('attendance_sessions')
          .doc(data['sessionId'])
          .get();

      if (!sessionDoc.exists) {
        _showMessage('Session expired or invalid', Colors.red);
        setState(() => _isProcessing = false);
        return;
      }

      final sessionData = sessionDoc.data() as Map<String, dynamic>;

      // ✅ Check if session is active
      if (sessionData['isActive'] != true) {
        _showMessage('This QR Code has expired', Colors.red);
        setState(() => _isProcessing = false);
        return;
      }

      // ✅ Check if already marked
      final students = List<String>.from(sessionData['students'] ?? []);
      if (students.contains(user.uid)) {
        _showMessage('✅ You already marked attendance!', Colors.orange);
        widget.onScanComplete(data);
        Navigator.pop(context, data);
        return;
      }

      // ✅ Calculate week number
      final week = await _calculateWeek();

      // ✅ Mark attendance
      await sessionDoc.reference.update({
        'students': FieldValue.arrayUnion([user.uid]),
      });

      await FirebaseFirestore.instance.collection('attendance').add({
        'studentId': user.uid,
        'studentName': widget.studentName,
        'studentRegNumber': widget.studentRegNumber,
        'unitCode': data['unitCode'],
        'unitName': data['unitName'] ?? '',
        'sessionId': data['sessionId'],
        'lecturerId': sessionData['lecturerId'],
        'week': week,
        'date': DateTime.now().toIso8601String(),
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'present',
        'source': 'online',
      });

      // ✅ Update attendance progress
      await _syncService.syncAttendance();

      _showMessage('✅ Attendance marked online!', Colors.green);
      widget.onScanComplete(data);
      Navigator.pop(context, data);
    } catch (e) {
      _showMessage('Error: $e', Colors.red);
      setState(() => _isProcessing = false);
    }
  }

  // ✅ Offline marking
  Future<void> _markOffline(Map<String, dynamic> data, User user) async {
    try {
      // ✅ Calculate week
      final week = await _calculateWeek();

      // ✅ Save to SQLite
      await _db.saveAttendance({
        'studentId': user.uid,
        'studentName': widget.studentName,
        'regNumber': widget.studentRegNumber,
        'unitCode': data['unitCode'],
        'unitName': data['unitName'] ?? '',
        'sessionId': data['sessionId'],
        'lecturerId': data['lecturerId'] ?? '',
        'week': week,
        'qrData': json.encode(data),
      });

      _showMessage(
          '📴 Attendance saved offline! Will sync when online.', Colors.orange);
      widget.onScanComplete(data);
      Navigator.pop(context, data);
    } catch (e) {
      _showMessage('Error: $e', Colors.red);
      setState(() => _isProcessing = false);
    }
  }

  // ✅ Calculate week number
  Future<int> _calculateWeek() async {
    // ✅ Semester start date (can be configured)
    final semesterStart = DateTime(2024, 1, 15);
    final now = DateTime.now();
    final difference = now.difference(semesterStart);
    final week = (difference.inDays / 7).floor() + 1;
    return week.clamp(1, 14);
  }

  void _showMessage(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 3),
      ),
    );
    setState(() => _isProcessing = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan QR Code'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.flash_on),
            onPressed: () => controller?.toggleFlash(),
          ),
        ],
      ),
      body: _isProcessing
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Processing attendance...'),
                ],
              ),
            )
          : Column(
              children: [
                Expanded(
                  flex: 4,
                  child: QRView(
                    key: qrKey,
                    onQRViewCreated: _onQRViewCreated,
                    overlay: QrScannerOverlayShape(
                      borderColor: AppColors.primary,
                      borderRadius: 10,
                      borderLength: 30,
                      borderWidth: 10,
                      cutOutSize: 250,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Colors.white,
                  child: Column(
                    children: [
                      const Icon(
                        Icons.qr_code_scanner,
                        size: 40,
                        color: AppColors.primary,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Scan the QR Code from your lecturer',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Works online and offline!',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                        label: const Text('Cancel'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
