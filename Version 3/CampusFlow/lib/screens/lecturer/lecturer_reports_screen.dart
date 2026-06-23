import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:campus_flow/shared/constants/app_colors.dart';

class LecturerReportsScreen extends StatefulWidget {
  const LecturerReportsScreen({super.key});

  @override
  State<LecturerReportsScreen> createState() => _LecturerReportsScreenState();
}

class _LecturerReportsScreenState extends State<LecturerReportsScreen> {
  List<Map<String, dynamic>> _students = [];
  final Map<String, double> _attendanceData = {};
  bool _isLoading = true;
  String? _selectedCourse;
  String _searchQuery = '';

  final List<String> _courses = [
    'Computer Science',
    'Information Technology',
    'Software Engineering',
    'Data Science',
    'Cybersecurity',
  ];

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
        // Get students assigned to this lecturer
        final studentsSnapshot = await FirebaseFirestore.instance
            .collection('students')
            .where('lecturerId', isEqualTo: user.uid)
            .get();

        _students = studentsSnapshot.docs.map((doc) {
          final data = doc.data();
          data['id'] = doc.id;
          return data;
        }).toList();

        // Calculate attendance for each student
        for (var student in _students) {
          final attendanceSnapshot = await FirebaseFirestore.instance
              .collection('attendance')
              .where('studentId', isEqualTo: student['id'])
              .get();

          final records = attendanceSnapshot.docs;
          if (records.isNotEmpty) {
            final present =
                records.where((doc) => doc['status'] == 'present').length;
            _attendanceData[student['id']] = (present / records.length) * 100;
          } else {
            _attendanceData[student['id']] = 0.0;
          }
        }
      }
    } catch (e) {
      debugPrint('Error loading reports: $e');
    }

    setState(() => _isLoading = false);
  }

  List<Map<String, dynamic>> get _filteredStudents {
    if (_searchQuery.isEmpty) return _students;
    return _students.where((student) {
      final name = (student['displayName'] ?? '').toLowerCase();
      final reg = (student['regNumber'] ?? '').toLowerCase();
      final query = _searchQuery.toLowerCase();
      return name.contains(query) || reg.contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance Reports'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
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
        child: Column(
          children: [
            // Search Bar
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.white,
              child: Column(
                children: [
                  TextField(
                    decoration: InputDecoration(
                      hintText: 'Search students...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () =>
                                  setState(() => _searchQuery = ''),
                            )
                          : null,
                    ),
                    onChanged: (value) => setState(() => _searchQuery = value),
                  ),
                ],
              ),
            ),

            // Student List
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _filteredStudents.isEmpty
                      ? const Center(
                          child: Text(
                            'No students found',
                            style: TextStyle(color: Colors.white),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(8),
                          itemCount: _filteredStudents.length,
                          itemBuilder: (context, index) {
                            final student = _filteredStudents[index];
                            final attendance =
                                _attendanceData[student['id']] ?? 0;
                            final status = attendance >= 75
                                ? 'Good'
                                : attendance >= 60
                                    ? 'At Risk'
                                    : 'Critical';
                            final color = attendance >= 75
                                ? Colors.green
                                : attendance >= 60
                                    ? Colors.orange
                                    : Colors.red;

                            return Card(
                              margin: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              child: ExpansionTile(
                                leading: CircleAvatar(
                                  backgroundColor: color.withValues(alpha: 0.1),
                                  child: Text(
                                    (student['displayName'] ?? 'S')[0],
                                    style: TextStyle(color: color),
                                  ),
                                ),
                                title:
                                    Text(student['displayName'] ?? 'Student'),
                                subtitle: Text(student['regNumber'] ?? 'N/A'),
                                trailing: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: color,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    '${attendance.toStringAsFixed(0)}%',
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ),
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      children: [
                                        _infoRow('Name',
                                            student['displayName'] ?? 'N/A'),
                                        _infoRow('Registration',
                                            student['regNumber'] ?? 'N/A'),
                                        _infoRow(
                                            'Email', student['email'] ?? 'N/A'),
                                        _infoRow('Course',
                                            student['course'] ?? 'N/A'),
                                        _infoRow('Attendance',
                                            '${attendance.toStringAsFixed(1)}%'),
                                        _infoRow('Status', status),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text('$label:',
                style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
