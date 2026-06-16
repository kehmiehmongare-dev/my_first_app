import 'package:flutter/material.dart';
import 'package:campus_flow/models/student_model.dart';
import 'package:campus_flow/services/database_service.dart';
import 'package:campus_flow/models/course_model.dart';

class CoursesScreen extends StatefulWidget {
  final Student student;
  const CoursesScreen({super.key, required this.student});

  @override
  State<CoursesScreen> createState() => _CoursesScreenState();
}

class _CoursesScreenState extends State<CoursesScreen> {
  List<Course> _courses = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCourses();
  }

  Future<void> _loadCourses() async {
    setState(() => _isLoading = true);
    _courses = await DatabaseService.getStudentCourses(widget.student.id);
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Courses'),
        backgroundColor: const Color(0xFF667eea),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadCourses,
              child: _courses.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.menu_book,
                              size: 64, color: Colors.grey),
                          const SizedBox(height: 16),
                          Text(
                            'No courses enrolled yet',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Contact your department to enroll in courses',
                            style: TextStyle(
                                color: Colors.grey[500], fontSize: 12),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _courses.length,
                      itemBuilder: (context, index) {
                        final course = _courses[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          child: ExpansionTile(
                            leading: CircleAvatar(
                              backgroundColor: const Color(0xFF667eea)
                                  .withValues(alpha: 0.1),
                              child: Text(
                                course.code.substring(0, 2),
                                style: const TextStyle(
                                  color: Color(0xFF667eea),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            title: Text(
                              '${course.code} - ${course.name}',
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text('${course.credits} credits'),
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _infoRow(Icons.person, 'Lecturer',
                                        course.lecturerName),
                                    const SizedBox(height: 8),
                                    _infoRow(Icons.schedule, 'Schedule',
                                        course.schedule),
                                    const SizedBox(height: 8),
                                    _infoRow(
                                        Icons.location_on, 'Room', course.room),
                                    const SizedBox(height: 8),
                                    _infoRow(Icons.book, 'Year',
                                        'Year ${course.year}'),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 8),
        SizedBox(
          width: 70,
          child: Text('$label:',
              style: TextStyle(color: Colors.grey[600], fontSize: 12)),
        ),
        Expanded(child: Text(value, style: const TextStyle(fontSize: 12))),
      ],
    );
  }
}
