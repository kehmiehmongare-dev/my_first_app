import 'package:flutter/material.dart';
import 'package:campus_flow/models/lecturer_model.dart';
import 'package:campus_flow/services/database_service.dart';
import 'package:campus_flow/models/student_model.dart';

class LecturerAttendanceScreen extends StatefulWidget {
  final Lecturer lecturer;
  const LecturerAttendanceScreen({super.key, required this.lecturer});

  @override
  State<LecturerAttendanceScreen> createState() =>
      _LecturerAttendanceScreenState();
}

class _LecturerAttendanceScreenState extends State<LecturerAttendanceScreen> {
  List<Student> _students = [];
  final Map<String, String> _attendanceStatus = {};
  bool _isLoading = true;
  bool _isSubmitting = false;
  String? _selectedCourse;
  final List<String> _courses = [
    'BSc Computer Science',
    'BSc Information Technology',
    'BSc Software Engineering'
  ];

  @override
  void initState() {
    super.initState();
    _loadStudents();
  }

  Future<void> _loadStudents() async {
    setState(() => _isLoading = true);
    _students = await DatabaseService.getStudentsByCourse(
        _selectedCourse ?? 'BSc Computer Science');
    for (var student in _students) {
      _attendanceStatus[student.regNumber] = 'absent';
    }
    setState(() => _isLoading = false);
  }

  Future<void> _submitAttendance() async {
    setState(() => _isSubmitting = true);
    final today = DateTime.now().toIso8601String().split('T')[0];
    int markedCount = 0;

    for (var student in _students) {
      final status = _attendanceStatus[student.regNumber];
      if (status != null && status != 'absent') {
        await DatabaseService.markAttendanceManual(
          studentId: student.id,
          studentName: student.fullName,
          courseId: _selectedCourse ?? 'CS001',
          courseCode: _selectedCourse?.substring(0, 5) ?? 'CS001',
          date: today,
          status: status,
        );
        markedCount++;
      }
    }

    setState(() => _isSubmitting = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('✅ Attendance marked for $markedCount students!'),
            backgroundColor: Colors.green),
      );
      _loadStudents();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mark Attendance'),
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
                  labelText: 'Select Course', border: OutlineInputBorder()),
              items: _courses
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
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
                    child: ListTile(
                      leading: CircleAvatar(child: Text(student.firstName[0])),
                      title: Text(student.fullName),
                      subtitle: Text(student.regNumber),
                      trailing: DropdownButton<String>(
                        value: _attendanceStatus[student.regNumber],
                        items: const [
                          DropdownMenuItem(
                              value: 'present',
                              child: Text('Present',
                                  style: TextStyle(color: Colors.green))),
                          DropdownMenuItem(
                              value: 'late',
                              child: Text('Late',
                                  style: TextStyle(color: Colors.orange))),
                          DropdownMenuItem(
                              value: 'absent',
                              child: Text('Absent',
                                  style: TextStyle(color: Colors.red))),
                        ],
                        onChanged: (value) => setState(() =>
                            _attendanceStatus[student.regNumber] = value!),
                      ),
                    ),
                  );
                },
              ),
            ),
          if (_students.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitAttendance,
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    minimumSize: const Size(double.infinity, 50)),
                child: _isSubmitting
                    ? const CircularProgressIndicator()
                    : const Text('Submit Attendance'),
              ),
            ),
        ],
      ),
    );
  }
}
