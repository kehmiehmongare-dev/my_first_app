import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:campus_flow/shared/constants/app_colors.dart';

class CoursesScreen extends StatefulWidget {
  const CoursesScreen({super.key});

  @override
  State<CoursesScreen> createState() => _CoursesScreenState();
}

class _CoursesScreenState extends State<CoursesScreen> {
  Map<String, dynamic> _studentData = {};
  List<String> _registeredUnits = [];
  List<Map<String, dynamic>> _allUnits = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final doc = await FirebaseFirestore.instance
            .collection('students')
            .doc(user.uid)
            .get();

        if (doc.exists) {
          _studentData = doc.data() as Map<String, dynamic>;

          // ✅ Handle both String and Map types for registeredUnits
          final unitsData = _studentData['registeredUnits'];
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
          }

          // ✅ Get units based on course
          final courseCode =
              _studentData['courseCode'] ?? _studentData['course'] ?? '';
          _allUnits = _getUnitsForCourse(courseCode);
        }
      }
    } catch (e) {
      debugPrint('Error loading courses: $e');
    }

    setState(() => _isLoading = false);
  }

  List<Map<String, dynamic>> _getUnitsForCourse(String courseCode) {
    // ✅ Define units based on course code
    final Map<String, List<Map<String, dynamic>>> courseUnits = {
      'BScIT': [
        {'code': 'IT301', 'name': 'Software Engineering', 'credits': 4},
        {'code': 'IT302', 'name': 'Database Systems', 'credits': 4},
        {'code': 'IT303', 'name': 'Web Development', 'credits': 3},
        {'code': 'IT304', 'name': 'Data Structures', 'credits': 4},
        {'code': 'IT305', 'name': 'Computer Networks', 'credits': 3},
        {'code': 'IT306', 'name': 'Operating Systems', 'credits': 3},
        {'code': 'IT307', 'name': 'Information Security', 'credits': 3},
        {'code': 'IT308', 'name': 'Project Management', 'credits': 3},
      ],
      'BScCS': [
        {'code': 'CS301', 'name': 'Software Engineering', 'credits': 4},
        {'code': 'CS302', 'name': 'Database Systems', 'credits': 4},
        {'code': 'CS303', 'name': 'Web Development', 'credits': 3},
        {'code': 'CS304', 'name': 'Data Structures', 'credits': 4},
        {'code': 'CS305', 'name': 'Computer Networks', 'credits': 3},
      ],
    };

    return courseUnits[courseCode] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    final courseName =
        _studentData['courseName'] ?? _studentData['course'] ?? 'Not enrolled';

    return Scaffold(
      appBar: AppBar(
        title: Text('My Courses - $courseName'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
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
            : courseName == 'Not enrolled' || courseName == 'Not Enrolled'
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.menu_book,
                            size: 64, color: Colors.white54),
                        const SizedBox(height: 16),
                        const Text(
                          'No Course Enrolled',
                          style: TextStyle(color: Colors.white, fontSize: 20),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Contact your department to enroll in a course',
                          style: TextStyle(color: Colors.white54),
                        ),
                      ],
                    ),
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Course Info
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Course: $courseName',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Semester: ${_studentData['semester'] ?? 1}',
                                  style: TextStyle(color: Colors.grey[600]),
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _registeredUnits.isNotEmpty
                                        ? Colors.green.withValues(alpha: 0.1)
                                        : Colors.orange.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    _registeredUnits.isNotEmpty
                                        ? '✅ ${_registeredUnits.length} Units Registered'
                                        : '⚠️ No Units Registered',
                                    style: TextStyle(
                                      color: _registeredUnits.isNotEmpty
                                          ? Colors.green
                                          : Colors.orange,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Units List
                        const Text(
                          'Units',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ..._allUnits.map((unit) {
                          final isRegistered =
                              _registeredUnits.contains(unit['code']);
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor:
                                    isRegistered ? Colors.green : Colors.grey,
                                child: Icon(
                                  isRegistered ? Icons.check : Icons.schedule,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                              title: Text(unit['name']!),
                              subtitle: Text(
                                  '${unit['code']} • ${unit['credits']} credits'),
                              trailing: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: isRegistered
                                      ? Colors.green.withValues(alpha: 0.1)
                                      : Colors.orange.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  isRegistered ? '✅ Done' : 'Pending',
                                  style: TextStyle(
                                    color: isRegistered
                                        ? Colors.green
                                        : Colors.orange,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }),

                        // Progress
                        const SizedBox(height: 16),
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Progress',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Expanded(
                                      child: LinearProgressIndicator(
                                        value: _allUnits.isEmpty
                                            ? 0
                                            : _registeredUnits.length /
                                                _allUnits.length,
                                        backgroundColor: Colors.grey[200],
                                        color: Colors.green,
                                        minHeight: 8,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      '${_allUnits.isEmpty ? 0 : (_registeredUnits.length / _allUnits.length * 100).toStringAsFixed(0)}%',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
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
}
