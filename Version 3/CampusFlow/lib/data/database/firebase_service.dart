import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:campus_flow/firebase_options.dart';
import 'package:flutter/foundation.dart';

class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  late FirebaseFirestore _firestore;
  bool _isInitialized = false;

  Future<void> init() async {
    if (_isInitialized) return;

    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      _firestore = FirebaseFirestore.instance;
      _isInitialized = true;
      debugPrint('✅ Firebase Service initialized');
    } catch (e) {
      debugPrint('❌ Firebase init error: $e');
      rethrow;
    }
  }

  // ✅ Get students from Firestore
  Future<List<Map<String, dynamic>>> getStudents() async {
    final snapshot = await _firestore.collection('students').get();
    return snapshot.docs.map((doc) => doc.data()).toList();
  }

  // ✅ Save student to Firestore
  Future<void> saveStudent(Map<String, dynamic> student) async {
    await _firestore
        .collection('students')
        .doc(student['regNumber'])
        .set(student);
  }

  // ✅ Get attendance from Firestore
  Future<List<Map<String, dynamic>>> getAttendance(String regNumber) async {
    final snapshot = await _firestore
        .collection('attendance')
        .where('regNumber', isEqualTo: regNumber)
        .orderBy('date', descending: true)
        .get();
    return snapshot.docs.map((doc) => doc.data()).toList();
  }

  // ✅ Save attendance to Firestore
  Future<void> saveAttendance(Map<String, dynamic> attendance) async {
    await _firestore.collection('attendance').add(attendance);
  }
}
