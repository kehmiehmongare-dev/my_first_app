import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:campus_flow/firebase_options.dart';
import 'package:flutter/foundation.dart';

class CampusFirebaseService {
  static final CampusFirebaseService _instance =
      CampusFirebaseService._internal();
  factory CampusFirebaseService() => _instance;
  CampusFirebaseService._internal();

  late FirebaseAuth _auth;
  late FirebaseFirestore _firestore;
  late DatabaseReference _realtimeDb;
  bool _isInitialized = false;

  // In CampusFirebaseService class, add:

  static Future<List<Map<String, dynamic>>> getStudentsOnce() async {
    return await getStudents();
  }

  static Future<void> init() async {
    await _instance._init();
  }

  Future<void> _init() async {
    if (_isInitialized) return;

    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      _auth = FirebaseAuth.instance;
      _firestore = FirebaseFirestore.instance;
      _realtimeDb = FirebaseDatabase.instance.ref();

      _isInitialized = true;
      debugPrint('✅ Firebase initialized successfully');
    } catch (e) {
      debugPrint('❌ Firebase init error: $e');
      rethrow;
    }
  }

  bool get isInitialized => _isInitialized;

  // ==================== AUTHENTICATION ====================

  static Future<User?> registerWithEmail(String email, String password) async {
    try {
      UserCredential credential =
          await _instance._auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return credential.user;
    } catch (e) {
      debugPrint('Register error: $e');
      rethrow;
    }
  }

  static Future<User?> loginWithEmail(String email, String password) async {
    try {
      UserCredential credential =
          await _instance._auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return credential.user;
    } catch (e) {
      debugPrint('Login error: $e');
      rethrow;
    }
  }

  static Future<void> logout() async {
    await _instance._auth.signOut();
  }

  static User? getCurrentUser() => _instance._auth.currentUser;

  // ==================== FIRESTORE ====================

  // Create/Save student
  static Future<void> saveStudent(Map<String, dynamic> student) async {
    await _instance._firestore
        .collection('students')
        .doc(student['regNumber'])
        .set(student);
  }

  // Read all students (once)
  static Future<List<Map<String, dynamic>>> getStudents() async {
    final snapshot = await _instance._firestore.collection('students').get();
    return snapshot.docs.map((doc) => doc.data()).toList();
  }

  // Read specific student
  static Future<Map<String, dynamic>?> getStudent(String regNumber) async {
    final doc =
        await _instance._firestore.collection('students').doc(regNumber).get();
    return doc.exists ? doc.data() : null;
  }

  // Update student
  static Future<void> updateStudent(
      String regNumber, Map<String, dynamic> data) async {
    await _instance._firestore
        .collection('students')
        .doc(regNumber)
        .update(data);
  }

  // Delete student
  static Future<void> deleteStudent(String regNumber) async {
    await _instance._firestore.collection('students').doc(regNumber).delete();
  }

  // Real-time stream of students
  static Stream<QuerySnapshot> streamStudents() {
    return _instance._firestore.collection('students').snapshots();
  }

  // Search students
  static Future<List<Map<String, dynamic>>> searchStudents(String query) async {
    final snapshot = await _instance._firestore
        .collection('students')
        .where('name', isGreaterThanOrEqualTo: query)
        .where('name', isLessThan: '${query}z')
        .get();
    return snapshot.docs.map((doc) => doc.data()).toList();
  }

  // ==================== REALTIME DATABASE ====================

  // Write to Realtime Database
  static Future<void> saveStudentRealtime(Map<String, dynamic> student) async {
    await _instance._realtimeDb
        .child('students/${student['regNumber']}')
        .set(student);
  }

  // Read from Realtime Database (once)
  static Future<DataSnapshot> getStudentsRealtime() async {
    final event = await _instance._realtimeDb.child('students').once();
    return event.snapshot;
  }

  // Stream from Realtime Database
  static Stream<DatabaseEvent> streamStudentsRealtime() {
    return _instance._realtimeDb.child('students').onValue;
  }

  // Delete from Realtime Database
  static Future<void> deleteStudentRealtime(String regNumber) async {
    await _instance._realtimeDb.child('students/$regNumber').remove();
  }

  // ==================== ATTENDANCE ====================

  // Save attendance
  static Future<void> saveAttendance(Map<String, dynamic> attendance) async {
    await _instance._firestore.collection('attendance').add(attendance);
  }

  // Get attendance for a student
  static Future<List<Map<String, dynamic>>> getAttendance(
      String regNumber) async {
    final snapshot = await _instance._firestore
        .collection('attendance')
        .where('regNumber', isEqualTo: regNumber)
        .orderBy('date', descending: true)
        .get();
    return snapshot.docs.map((doc) => doc.data()).toList();
  }

  // Stream attendance (real-time)
  static Stream<QuerySnapshot> streamAttendance() {
    return _instance._firestore.collection('attendance').snapshots();
  }

  // ==================== SYNC METHODS ====================

  // Sync SQLite to Firebase
  static Future<void> syncLocalToFirebase() async {
    // This will be implemented with SQLite integration
    debugPrint('✅ Syncing local data to Firebase...');
  }

  // Sync Firebase to SQLite
  static Future<void> syncFirebaseToLocal() async {
    debugPrint('✅ Syncing Firebase data to local...');
  }

  // ==================== TEST METHODS ====================

  // Test write to Firestore
  static Future<void> testFirestore() async {
    await _instance._firestore.collection('test').add({
      'message': 'Hello from Campus Flow!',
      'timestamp': FieldValue.serverTimestamp(),
    });
    debugPrint('✅ Test data written to Firestore');
  }

  // Test read from Firestore
  static Future<List<Map<String, dynamic>>> testRead() async {
    final snapshot = await _instance._firestore.collection('test').get();
    return snapshot.docs.map((doc) => doc.data()).toList();
  }

  // Test Realtime Database
  static Future<void> testRealtime() async {
    await _instance._realtimeDb.child('test').set({
      'message': 'Hello from Realtime DB!',
      'timestamp': DateTime.now().toIso8601String(),
    });
    debugPrint('✅ Test data written to Realtime DB');
  }
}
