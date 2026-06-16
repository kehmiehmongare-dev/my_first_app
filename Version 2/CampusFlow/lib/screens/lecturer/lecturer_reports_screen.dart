import 'package:flutter/material.dart';
import 'package:campus_flow/models/lecturer_model.dart';
import 'package:campus_flow/services/database_service.dart';
import 'package:campus_flow/models/student_model.dart';

class LecturerReportsScreen extends StatefulWidget {
  final Lecturer lecturer;
  const LecturerReportsScreen({super.key, required this.lecturer});

  @override
  State<LecturerReportsScreen> createState() => _LecturerReportsScreenState();
}

class _LecturerReportsScreenState extends State<LecturerReportsScreen> {
  List<Student> _students = [];
  final Map<String, double> _attendanceData = {};
  bool _isLoading = true;
  String? _selectedCourse;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    _students = await DatabaseService.getStudentsByCourse(
        _selectedCourse ?? 'BSc Computer Science');
    for (var student in _students) {
      _attendanceData[student.fullName] =
          await DatabaseService.getOverallAttendance(student.id);
    }
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance Reports'),
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
              items: const [
                DropdownMenuItem(
                    value: 'BSc Computer Science',
                    child: Text('BSc Computer Science')),
                DropdownMenuItem(
                    value: 'BSc Information Technology',
                    child: Text('BSc Information Technology')),
                DropdownMenuItem(
                    value: 'BSc Software Engineering',
                    child: Text('BSc Software Engineering')),
              ],
              onChanged: (value) async {
                setState(() => _selectedCourse = value);
                await _loadData();
              },
            ),
          ),
          if (_isLoading)
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else if (_students.isEmpty)
            const Expanded(child: Center(child: Text('No data available')))
          else
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(8),
                itemCount: _students.length,
                itemBuilder: (context, index) {
                  final student = _students[index];
                  final attendance = _attendanceData[student.fullName] ?? 0;
                  return Card(
                    margin:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: attendance >= 75
                            ? Colors.green
                            : attendance >= 60
                                ? Colors.orange
                                : Colors.red,
                        child: Text('${attendance.toStringAsFixed(0)}%'),
                      ),
                      title: Text(student.fullName),
                      subtitle: Text(student.regNumber),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: attendance >= 75
                              ? Colors.green
                              : attendance >= 60
                                  ? Colors.orange
                                  : Colors.red,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          attendance >= 75
                              ? 'Good'
                              : attendance >= 60
                                  ? 'At Risk'
                                  : 'Critical',
                          style: const TextStyle(
                              color: Colors.white, fontSize: 12),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
