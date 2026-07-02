import 'package:flutter/material.dart';
import 'package:campus_flow/models/lecturer_model.dart';
import 'package:campus_flow/services/database_service.dart';
import 'package:campus_flow/models/student_model.dart';

class LecturerStudentsScreen extends StatefulWidget {
  final Lecturer lecturer;
  const LecturerStudentsScreen({super.key, required this.lecturer});

  @override
  State<LecturerStudentsScreen> createState() => _LecturerStudentsScreenState();
}

class _LecturerStudentsScreenState extends State<LecturerStudentsScreen> {
  List<Student> _students = [];
  bool _isLoading = true;
  String? _selectedCourse;

  @override
  void initState() {
    super.initState();
    _loadStudents();
  }

  Future<void> _loadStudents() async {
    setState(() => _isLoading = true);
    try {
      // Get student data as List<Map<String, dynamic>>
      List<Map<String, dynamic>> studentMaps =
          await DatabaseService.getStudentsByCourse(
              _selectedCourse ?? 'BSc Computer Science');

      // ✅ FIX: Changed from fromMap to fromJson
      _students = studentMaps.map((map) => Student.fromJson(map)).toList();
    } catch (e) {
      debugPrint('Error loading students: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading students: $e')),
      );
    }
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Students'),
        backgroundColor: const Color(0xFF667eea),
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: DropdownButtonFormField<String>(
              initialValue: _selectedCourse,
              decoration: const InputDecoration(
                labelText: 'Select Course',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(
                  value: 'BSc Computer Science',
                  child: Text('BSc Computer Science'),
                ),
                DropdownMenuItem(
                  value: 'BSc Information Technology',
                  child: Text('BSc Information Technology'),
                ),
                DropdownMenuItem(
                  value: 'BSc Software Engineering',
                  child: Text('BSc Software Engineering'),
                ),
              ],
              onChanged: (value) async {
                setState(() => _selectedCourse = value);
                await _loadStudents();
              },
            ),
          ),
          if (_isLoading)
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else if (_students.isEmpty)
            const Expanded(
                child:
                    Center(child: Text('No students enrolled in this course')))
          else
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(8),
                itemCount: _students.length,
                itemBuilder: (context, index) {
                  final student = _students[index];
                  return Card(
                    margin:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: ExpansionTile(
                      leading: CircleAvatar(
                        child: Text(student.firstName.isNotEmpty
                            ? student.firstName[0]
                            : '?'),
                      ),
                      title: Text(student.fullName),
                      subtitle: Text(student.regNumber),
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              _infoRow('Email', student.email),
                              _infoRow('Phone', student.phone),
                              _infoRow('Course', student.course),
                              _infoRow(
                                  'Semester', 'Semester ${student.semester}'),
                              _infoRow('Year', 'Year ${student.yearOfStudy}'),
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
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
              width: 80,
              child: Text('$label:',
                  style: const TextStyle(fontWeight: FontWeight.bold))),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
