import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:campus_flow/features/auth/screens/login_screen.dart';
import 'firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:campus_flow/services/preferences_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // ✅ Uncomment this line to run the update once
  // await syncFirestoreUsersToAuth();
  // await updateStudentData();

  final prefs = PreferencesService();
  await prefs.init();

  runApp(const CampusFlowApp());
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
      home: const LoginScreen(),
    );
  }
}

// ✅ Run this once to create Auth users for all Firestore students
Future<void> syncFirestoreUsersToAuth() async {
  try {
    final firestore = FirebaseFirestore.instance;
    final auth = FirebaseAuth.instance;

    // Get all students from Firestore
    final students = await firestore.collection('students').get();

    print('📊 Found ${students.docs.length} students in Firestore');

    for (var doc in students.docs) {
      final data = doc.data();
      final email = data['email'] as String?;
      final regNumber = data['regNumber'] as String?;
      final displayName = data['displayName'] as String? ?? 'Student';

      if (email == null || email.isEmpty) {
        print('⚠️ Skipping student with no email: $displayName');
        continue;
      }

      try {
        // Check if user already exists in Auth
        // We can try to get user by email using admin SDK, but from client side we'll try to create
        // If user exists, this will throw an error which we'll catch

        // ✅ Generate a temporary password using regNumber or default
        final tempPassword =
            regNumber != null ? '$regNumber@2024' : 'Student@2024';

        // Try to create the user
        await auth.createUserWithEmailAndPassword(
          email: email,
          password: tempPassword,
        );

        print('✅ Created Auth user: $email with password: $tempPassword');

        // Update Firestore with the temporary password
        await doc.reference.update({
          'temporaryPassword': tempPassword,
          'authCreated': true,
        });
      } catch (e) {
        if (e.toString().contains('email-already-in-use')) {
          print('⏭️ User already exists in Auth: $email');
        } else {
          print('❌ Error creating $email: $e');
        }
      }
    }

    print('✅ Sync complete!');
  } catch (e) {
    print('❌ Error syncing users: $e');
  }
}

// ✅ Update function to add missing fields to existing students
Future<void> updateStudentData() async {
  try {
    final firestore = FirebaseFirestore.instance;
    final students = await firestore.collection('students').get();

    print('📊 Found ${students.docs.length} students');

    for (var doc in students.docs) {
      final data = doc.data();
      bool needsUpdate = false;
      final updates = <String, dynamic>{};

      if (!data.containsKey('registeredUnits')) {
        updates['registeredUnits'] = [];
        needsUpdate = true;
      }
      if (!data.containsKey('totalFees')) {
        updates['totalFees'] = 60000;
        needsUpdate = true;
      }
      if (!data.containsKey('paidFees')) {
        updates['paidFees'] = 0;
        needsUpdate = true;
      }
      if (!data.containsKey('course')) {
        updates['course'] = 'Not Enrolled';
        needsUpdate = true;
      }
      if (!data.containsKey('department')) {
        updates['department'] = '';
        needsUpdate = true;
      }
      if (!data.containsKey('unitsRegistered')) {
        updates['unitsRegistered'] = false;
        needsUpdate = true;
      }

      if (needsUpdate) {
        await doc.reference.update(updates);
        print('✅ Updated student: ${data['displayName'] ?? 'Unknown'}');
      } else {
        print('⏭️ No update needed for: ${data['displayName'] ?? 'Unknown'}');
      }
    }
    print('✅ All students updated successfully!');
  } catch (e) {
    print('❌ Error updating students: $e');
  }
}
