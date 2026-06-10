import 'package:flutter/material.dart';
import 'package:campus_flow/models/student_model.dart';
import 'package:campus_flow/services/database_service.dart';

class CoursesScreen extends StatefulWidget {
  final Student student;
  const CoursesScreen({super.key, required this.student});

  @override
  State<CoursesScreen> createState() => _CoursesScreenState();
}

class _CoursesScreenState extends State<CoursesScreen> {
  List<Map<String, dynamic>> _courses = [];
  bool _isLoading = true;
  bool _isAdding = false;

  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  final _nameController = TextEditingController();
  final _creditsController = TextEditingController();
  final _instructorController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadCourses();
  }

  Future<void> _loadCourses() async {
    final courses = await DatabaseService.getCourses(widget.student.regNumber);
    setState(() {
      _courses = courses;
      _isLoading = false;
    });
  }

  Future<void> _addCourse() async {
    if (_formKey.currentState!.validate()) {
      final course = {
        'code': _codeController.text,
        'name': _nameController.text,
        'credits': int.parse(_creditsController.text),
        'instructor': _instructorController.text,
      };

      await DatabaseService.enrollCourse(widget.student.regNumber, course);
      _clearControllers();
      await _loadCourses(); // Refresh the list
      setState(() => _isAdding = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Course added!'), backgroundColor: Colors.green),
        );
      }
    }
  }

  void _clearControllers() {
    _codeController.clear();
    _nameController.clear();
    _creditsController.clear();
    _instructorController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('My Courses', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon:
                Icon(_isAdding ? Icons.close : Icons.add, color: Colors.white),
            onPressed: () => setState(() => _isAdding = !_isAdding),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : Column(
              children: [
                if (_isAdding) _buildAddCourseForm(),
                Expanded(
                  child: _courses.isEmpty
                      ? const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.menu_book,
                                  size: 64, color: Colors.white54),
                              SizedBox(height: 16),
                              Text('No courses enrolled yet',
                                  style: TextStyle(color: Colors.white70)),
                              SizedBox(height: 8),
                              Text('Tap + to add your first course',
                                  style: TextStyle(
                                      color: Colors.white54, fontSize: 12)),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _courses.length,
                          itemBuilder: (context, index) {
                            final course = _courses[index];
                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 50,
                                    height: 50,
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [
                                          Color(0xFF667eea),
                                          Color(0xFF764ba2)
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Center(
                                      child: Text(
                                        course['code'].substring(0, 2),
                                        style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '${course['code']} - ${course['name']}',
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '${course['credits']} credits • ${course['instructor']}',
                                          style: TextStyle(
                                              color: Colors.grey[600],
                                              fontSize: 12),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color:
                                          Colors.green.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: const Text('Active',
                                        style: TextStyle(
                                            color: Colors.green, fontSize: 10)),
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

  Widget _buildAddCourseForm() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            const Text('Add New Course',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextFormField(
              controller: _codeController,
              decoration: const InputDecoration(
                  labelText: 'Course Code', border: OutlineInputBorder()),
              validator: (v) => v!.isEmpty ? 'Enter course code' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                  labelText: 'Course Name', border: OutlineInputBorder()),
              validator: (v) => v!.isEmpty ? 'Enter course name' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _creditsController,
              decoration: const InputDecoration(
                  labelText: 'Credits', border: OutlineInputBorder()),
              keyboardType: TextInputType.number,
              validator: (v) => v!.isEmpty ? 'Enter credits' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _instructorController,
              decoration: const InputDecoration(
                  labelText: 'Instructor', border: OutlineInputBorder()),
              validator: (v) => v!.isEmpty ? 'Enter instructor name' : null,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _addCourse,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF667eea),
                minimumSize: const Size(double.infinity, 45),
              ),
              child: const Text('Add Course'),
            ),
          ],
        ),
      ),
    );
  }
}
