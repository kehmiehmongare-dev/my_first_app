import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:campus_flow/shared/constants/app_colors.dart';
import 'package:campus_flow/features/student/models/course_data.dart';

class UnitRegistrationScreen extends StatefulWidget {
  const UnitRegistrationScreen({super.key});

  @override
  State<UnitRegistrationScreen> createState() => _UnitRegistrationScreenState();
}

class _UnitRegistrationScreenState extends State<UnitRegistrationScreen> {
  String? _selectedFaculty;
  String? _selectedCourse;
  List<Map<String, dynamic>> _availableUnits = [];
  List<Map<String, dynamic>> _selectedUnits = [];
  bool _isLoading = true;
  bool _isSubmitting = false;
  bool _isRegistered = false;
  String _studentName = '';
  String _studentRegNumber = '';

  @override
  void initState() {
    super.initState();
    _checkRegistrationStatus();
  }

  Future<void> _checkRegistrationStatus() async {
    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final doc = await FirebaseFirestore.instance
            .collection('students')
            .doc(user.uid)
            .get();

        if (doc.exists) {
          final data = doc.data() as Map<String, dynamic>;
          _studentName = data['displayName'] ?? 'Student';
          _studentRegNumber = data['regNumber'] ?? 'STU001';

          final registeredUnits =
              List<Map<String, dynamic>>.from(data['registeredUnits'] ?? []);
          _selectedCourse = data['courseCode'] ?? data['course'] ?? '';

          if (registeredUnits.isNotEmpty) {
            _isRegistered = true;
            _selectedUnits = registeredUnits;
          }
        }
      }
    } catch (e) {
      debugPrint('Error checking registration: $e');
    }

    setState(() => _isLoading = false);
  }

  void _loadUnits() {
    if (_selectedCourse != null) {
      _availableUnits = CourseData.getUnitsByCourse(_selectedCourse!);
    } else {
      _availableUnits = [];
    }
  }

  Future<void> _registerUnits() async {
    if (_selectedUnits.isEmpty) {
      _showMessage('Please select at least one unit', Colors.orange);
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _showMessage('User not logged in', Colors.red);
        setState(() => _isSubmitting = false);
        return;
      }

      final courseName = CourseData.getCourseName(_selectedCourse!);
      final totalCredits = _selectedUnits.fold(0, (sum, unit) {
        return sum + (unit['credits'] as int? ?? 0);
      });

      // Calculate fees based on credits (e.g., 5000 per credit)
      final semesterFee = totalCredits * 5000;
      final minimumPayment = semesterFee * 0.3; // 30% minimum

      // Update student document
      final studentRef =
          FirebaseFirestore.instance.collection('students').doc(user.uid);

      await studentRef.set({
        'displayName': _studentName,
        'regNumber': _studentRegNumber,
        'faculty': _selectedFaculty,
        'courseCode': _selectedCourse,
        'course': courseName,
        'registeredUnits': _selectedUnits,
        'unitsRegistered': true,
        'totalCredits': totalCredits,
        'totalFees': semesterFee,
        'paidFees': 0,
        'pendingFees': semesterFee,
        'minimumPayment': minimumPayment,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // Create fees document
      await FirebaseFirestore.instance.collection('fees').doc(user.uid).set({
        'studentId': user.uid,
        'studentName': _studentName,
        'studentRegNumber': _studentRegNumber,
        'semester': '1',
        'academicYear': '2024/2025',
        'courseCode': _selectedCourse,
        'courseName': courseName,
        'unitsRegistered': _selectedUnits,
        'totalCredits': totalCredits,
        'totalFee': semesterFee,
        'amountPaid': 0,
        'pendingBalance': semesterFee,
        'minimumPayment': minimumPayment,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      setState(() {
        _isRegistered = true;
        _isSubmitting = false;
      });

      _showMessage(
        '✅ Registered ${_selectedUnits.length} units successfully!',
        Colors.green,
      );

      if (!mounted) return;
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          Navigator.pop(context, true);
        }
      });
    } catch (e) {
      setState(() => _isSubmitting = false);
      _showMessage('❌ Error: ${e.toString()}', Colors.red);
      debugPrint('Registration error: $e');
    }
  }

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
        title: const Text('Course & Unit Registration'),
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
            : _isRegistered
                ? _buildRegisteredView()
                : _buildRegistrationForm(),
      ),
    );
  }

  Widget _buildRegisteredView() {
    final courseName = CourseData.getCourseName(_selectedCourse!);
    final totalCredits = _selectedUnits.fold(0, (sum, unit) {
      return sum + (unit['credits'] as int? ?? 0);
    });
    final semesterFee = totalCredits * 5000;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle, size: 80, color: Colors.green),
            const SizedBox(height: 16),
            const Text(
              'Registration Complete!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Student: $_studentName',
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 8),
            Text(
              'Course: ${courseName ?? _selectedCourse}',
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 8),
            Text(
              'Units: ${_selectedUnits.length} units registered',
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 8),
            Text(
              'Total Credits: $totalCredits',
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 8),
            Text(
              'Semester Fee: KSh ${semesterFee.toStringAsFixed(0)}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Minimum Payment: KSh ${(semesterFee * 0.3).toStringAsFixed(0)} (30%)',
              style: TextStyle(
                fontSize: 14,
                color: Colors.yellow.shade300,
              ),
            ),
            const SizedBox(height: 24),
            Column(
              children: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context, true);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 40,
                      vertical: 16,
                    ),
                  ),
                  child: const Text('Go to Dashboard'),
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: () {
                    Navigator.pop(context, true);
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 40,
                      vertical: 16,
                    ),
                  ),
                  child: const Text('Make Payment Now'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRegistrationForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Student Info Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Student Information',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Name:'),
                      Text(_studentName,
                          style: const TextStyle(fontWeight: FontWeight.w500)),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Reg Number:'),
                      Text(_studentRegNumber,
                          style: const TextStyle(fontWeight: FontWeight.w500)),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Step 1: Faculty Selection
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Step 1: Select Faculty',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedFaculty,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                    ),
                    hint: const Text('Choose your faculty'),
                    items: CourseData.getFaculties()
                        .map<DropdownMenuItem<String>>((faculty) {
                      return DropdownMenuItem<String>(
                        value: faculty,
                        child: Text(faculty),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedFaculty = value;
                        _selectedCourse = null;
                        _selectedUnits.clear();
                        _availableUnits = [];
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Step 2: Course Selection
          if (_selectedFaculty != null) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Step 2: Select Course',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedCourse,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                      ),
                      hint: const Text('Choose your course'),
                      items: CourseData.getCoursesByFaculty(_selectedFaculty!)
                          .map<DropdownMenuItem<String>>((course) {
                        return DropdownMenuItem<String>(
                          value: course['code'] as String,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(course['name'] as String),
                              Text(
                                '${course['code']} • ${course['credits']} credits',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedCourse = value;
                          _selectedUnits.clear();
                          _loadUnits();
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),

          // Step 3: Unit Selection
          if (_selectedCourse != null && _availableUnits.isNotEmpty) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Step 3: Select Units ($_selectedCourse)',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Select the units you want to register for this semester',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 12),
                    ..._availableUnits.map((unit) {
                      final isSelected = _selectedUnits.contains(unit);
                      return CheckboxListTile(
                        value: isSelected,
                        onChanged: (value) {
                          setState(() {
                            if (value == true) {
                              _selectedUnits.add(unit);
                            } else {
                              _selectedUnits.remove(unit);
                            }
                          });
                        },
                        title: Text(unit['name']!),
                        subtitle: Text(
                          '${unit['code']} • ${unit['credits']} credits',
                        ),
                        secondary: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${unit['credits']} credits',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Summary
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Course:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(_selectedCourse!),
                      ],
                    ),
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Selected Units:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text('${_selectedUnits.length}'),
                      ],
                    ),
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Total Credits:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '${_selectedUnits.fold(0, (sum, unit) {
                            return sum + (unit['credits'] as int? ?? 0);
                          })}',
                        ),
                      ],
                    ),
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Semester Fee:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          'KSh ${(_selectedUnits.fold(0, (sum, unit) {
                                return sum + (unit['credits'] as int? ?? 0);
                              }) * 5000).toStringAsFixed(0)}',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Minimum Payment (30%):',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          'KSh ${((_selectedUnits.fold(0, (sum, unit) {
                                return sum + (unit['credits'] as int? ?? 0);
                              }) * 5000) * 0.3).toStringAsFixed(0)}',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Register Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isSubmitting || _selectedUnits.isEmpty
                    ? null
                    : _registerUnits,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isSubmitting
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                        'Register ${_selectedUnits.length} Units',
                        style: const TextStyle(fontSize: 16),
                      ),
              ),
            ),
            if (_selectedUnits.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text(
                  'Please select at least one unit',
                  style: TextStyle(color: Colors.orange, fontSize: 12),
                ),
              ),
          ],
        ],
      ),
    );
  }
}
