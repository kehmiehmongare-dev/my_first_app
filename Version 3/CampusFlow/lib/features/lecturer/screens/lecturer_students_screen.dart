import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:campus_flow/shared/constants/app_colors.dart';

class LecturerStudentsScreen extends StatefulWidget {
  const LecturerStudentsScreen({super.key});

  @override
  State<LecturerStudentsScreen> createState() => _LecturerStudentsScreenState();
}

class _LecturerStudentsScreenState extends State<LecturerStudentsScreen> {
  bool _isLoading = true;
  String? _lecturerId;
  List<String> _lecturerCourses = [];
  List<Map<String, dynamic>> _students = [];
  List<Map<String, dynamic>> _filteredStudents = [];
  String _searchQuery = '';
  String _selectedFilter = 'All';

  @override
  void initState() {
    super.initState();
    _loadStudents();
  }

  Future<void> _loadStudents() async {
    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _showError('Please login again');
        setState(() => _isLoading = false);
        return;
      }

      _lecturerId = user.uid;

      // ✅ STEP 1: Get lecturer's courses
      final lecturerDoc = await FirebaseFirestore.instance
          .collection('lecturers')
          .doc(user.uid)
          .get();

      if (!lecturerDoc.exists) {
        _showError('Lecturer profile not found');
        setState(() => _isLoading = false);
        return;
      }

      final lecturerData = lecturerDoc.data() as Map<String, dynamic>;
      _lecturerCourses = List<String>.from(lecturerData['courses'] ?? []);

      // If no courses assigned, get all students
      if (_lecturerCourses.isEmpty) {
        // ✅ Get ALL students (for demo/admin purposes)
        final allStudents =
            await FirebaseFirestore.instance.collection('students').get();

        _students = allStudents.docs.map((doc) {
          final data = doc.data();
          data['id'] = doc.id;
          return data;
        }).toList();
      } else {
        // ✅ STEP 2: Get students registered in lecturer's courses
        final studentsSnapshot =
            await FirebaseFirestore.instance.collection('students').get();

        _students = studentsSnapshot.docs.map((doc) {
          final data = doc.data();
          data['id'] = doc.id;
          return data;
        }).toList();

        // ✅ STEP 3: Filter students by lecturer's courses
        // A student belongs to lecturer if ANY of their registered units
        // match the lecturer's courses
        _students = _students.where((student) {
          final registeredUnits =
              List<String>.from(student['registeredUnits'] ?? []);
          // Check if any registered unit is taught by this lecturer
          return registeredUnits.any((unit) => _lecturerCourses.contains(unit));
        }).toList();
      }

      _filteredStudents = List.from(_students);

      // ✅ Print for debugging
      print('📊 Lecturer Courses: $_lecturerCourses');
      print('📊 Students found: ${_students.length}');

      setState(() => _isLoading = false);
    } catch (e) {
      debugPrint('Error loading students: $e');
      _showError('Error loading students: $e');
      setState(() => _isLoading = false);
    }
  }

  void _filterStudents() {
    setState(() {
      _filteredStudents = _students.where((student) {
        final name = student['displayName']?.toString().toLowerCase() ?? '';
        final regNumber = student['regNumber']?.toString().toLowerCase() ?? '';
        final query = _searchQuery.toLowerCase();

        // Search by name or registration number
        final matchesSearch = name.contains(query) || regNumber.contains(query);

        // Filter by course if not 'All'
        if (_selectedFilter != 'All') {
          final units = List<String>.from(student['registeredUnits'] ?? []);
          return matchesSearch && units.contains(_selectedFilter);
        }

        return matchesSearch;
      }).toList();
    });
  }

  Future<void> _generateQRCode(String studentId, String studentName) async {
    // ✅ This will be implemented in the QR Code feature
    // For now, show a dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Generate QR Code'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.qr_code, size: 80, color: AppColors.primary),
            const SizedBox(height: 16),
            Text('Generate QR Code for:'),
            Text(
              studentName,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text(
              'This QR code will be shared with the student for attendance.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showMessage('QR Code generated for $studentName');
            },
            child: const Text('Generate'),
          ),
        ],
      ),
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Students'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadStudents,
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
            // ✅ Filter and Search Bar
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Search
                  TextField(
                    decoration: InputDecoration(
                      hintText: 'Search students...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      fillColor: Colors.white,
                      filled: true,
                    ),
                    onChanged: (value) {
                      _searchQuery = value;
                      _filterStudents();
                    },
                  ),
                  const SizedBox(height: 8),
                  // Course Filter
                  if (_lecturerCourses.isNotEmpty) ...[
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          FilterChip(
                            label: const Text('All'),
                            selected: _selectedFilter == 'All',
                            onSelected: (selected) {
                              setState(() {
                                _selectedFilter = 'All';
                                _filterStudents();
                              });
                            },
                          ),
                          const SizedBox(width: 8),
                          ..._lecturerCourses.map((course) {
                            return FilterChip(
                              label: Text(course),
                              selected: _selectedFilter == course,
                              onSelected: (selected) {
                                setState(() {
                                  _selectedFilter = selected ? course : 'All';
                                  _filterStudents();
                                });
                              },
                            );
                          }),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // ✅ Student Count
            if (!_isLoading) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  '${_filteredStudents.length} students found',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],

            // ✅ Student List
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _filteredStudents.isEmpty
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
                                    ? 'No courses assigned to you'
                                    : 'No students registered in your courses',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.8),
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 8),
                              if (_lecturerCourses.isEmpty)
                                Text(
                                  'Contact admin to assign courses to you',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.6),
                                    fontSize: 12,
                                  ),
                                ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _filteredStudents.length,
                          itemBuilder: (context, index) {
                            final student = _filteredStudents[index];
                            final units = List<String>.from(
                                student['registeredUnits'] ?? []);

                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: ExpansionTile(
                                leading: CircleAvatar(
                                  backgroundColor:
                                      AppColors.primary.withValues(alpha: 0.1),
                                  child: Text(
                                    student['displayName']?.substring(0, 1) ??
                                        'S',
                                    style: const TextStyle(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                title: Text(
                                  student['displayName'] ?? 'Unknown',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Reg: ${student['regNumber'] ?? 'N/A'}',
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                    if (student['course'] != null)
                                      Text(
                                        'Course: ${student['course']}',
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                  ],
                                ),
                                trailing: IconButton(
                                  icon: const Icon(Icons.qr_code,
                                      color: Colors.blue),
                                  onPressed: () => _generateQRCode(
                                    student['id'],
                                    student['displayName'] ?? 'Student',
                                  ),
                                  tooltip: 'Generate QR Code',
                                ),
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Registered Units:',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        if (units.isNotEmpty)
                                          Wrap(
                                            spacing: 8,
                                            runSpacing: 8,
                                            children: units.map((unit) {
                                              final isTaughtByLecturer =
                                                  _lecturerCourses
                                                      .contains(unit);
                                              return Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                  horizontal: 12,
                                                  vertical: 4,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: isTaughtByLecturer
                                                      ? Colors.green.shade100
                                                      : Colors.grey.shade200,
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                  border: Border.all(
                                                    color: isTaughtByLecturer
                                                        ? Colors.green
                                                        : Colors.grey,
                                                  ),
                                                ),
                                                child: Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    Text(
                                                      unit,
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        color:
                                                            isTaughtByLecturer
                                                                ? Colors.green
                                                                    .shade700
                                                                : Colors.grey
                                                                    .shade700,
                                                      ),
                                                    ),
                                                    if (isTaughtByLecturer) ...[
                                                      const SizedBox(width: 4),
                                                      Icon(
                                                        Icons.check_circle,
                                                        size: 14,
                                                        color: Colors
                                                            .green.shade700,
                                                      ),
                                                    ],
                                                  ],
                                                ),
                                              );
                                            }).toList(),
                                          )
                                        else
                                          const Text(
                                            'No units registered',
                                            style: TextStyle(
                                              color: Colors.grey,
                                              fontSize: 12,
                                            ),
                                          ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'Status: ${student['unitsRegistered'] == true ? "✅ Registered" : "❌ Not Registered"}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: student['unitsRegistered'] ==
                                                    true
                                                ? Colors.green
                                                : Colors.red,
                                          ),
                                        ),
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
}
