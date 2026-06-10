import 'package:flutter/material.dart';
import 'package:campus_flow/services/database_service.dart';
import 'package:campus_flow/models/student_model.dart';
import 'package:campus_flow/screens/login_screen.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

class LecturerDashboardScreen extends StatefulWidget {
  const LecturerDashboardScreen({super.key});

  @override
  State<LecturerDashboardScreen> createState() =>
      _LecturerDashboardScreenState();
}

class _LecturerDashboardScreenState extends State<LecturerDashboardScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [];

  @override
  void initState() {
    super.initState();
    _screens.addAll([
      const MarkAttendanceScreen(),
      const QRCodeAttendanceScreen(),
      const StudentListScreen(),
      const AttendanceHistoryScreen(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lecturer Dashboard'),
        backgroundColor: const Color(0xFF667eea),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
                (route) => false,
              );
            },
          ),
        ],
      ),
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (index) =>
                setState(() => _selectedIndex = index),
            labelType: NavigationRailLabelType.selected,
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.check_circle_outline),
                selectedIcon: Icon(Icons.check_circle),
                label: Text('Mark\nAttendance'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.qr_code_scanner),
                selectedIcon: Icon(Icons.qr_code),
                label: Text('QR Code'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.people_outline),
                selectedIcon: Icon(Icons.people),
                label: Text('Students'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.history),
                selectedIcon: Icon(Icons.history),
                label: Text('History'),
              ),
            ],
          ),
          Expanded(
            child: _screens[_selectedIndex],
          ),
        ],
      ),
    );
  }
}

// ==================== 1. MARK ATTENDANCE SCREEN (Multi-Student) ====================
class MarkAttendanceScreen extends StatefulWidget {
  const MarkAttendanceScreen({super.key});

  @override
  State<MarkAttendanceScreen> createState() => _MarkAttendanceScreenState();
}

class _MarkAttendanceScreenState extends State<MarkAttendanceScreen> {
  List<Student> _students = [];
  List<Student> _filteredStudents = [];
  final Map<String, String> _attendanceStatus = {};
  bool _isLoading = true;
  String? _selectedCourse;
  bool _selectAll = false;
  String _searchQuery = '';

  final List<String> _courses = [
    'BSc Computer Science',
    'BSc Information Technology',
    'BSc Software Engineering',
    'BSc Data Science',
    'BSc Cybersecurity',
  ];

  @override
  void initState() {
    super.initState();
    _loadStudents();
  }

  Future<void> _loadStudents() async {
    setState(() => _isLoading = true);

    if (_selectedCourse != null) {
      _students = await DatabaseService.getStudentsByCourse(_selectedCourse!);
      _filteredStudents = _students;
      for (var student in _students) {
        _attendanceStatus[student.regNumber] = 'absent';
      }
    }

    setState(() => _isLoading = false);
  }

  void _filterStudents(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredStudents = _students;
      } else {
        _filteredStudents = _students
            .where((student) =>
                student.name.toLowerCase().contains(query.toLowerCase()) ||
                student.regNumber.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  void _toggleSelectAll() {
    setState(() {
      _selectAll = !_selectAll;
      for (var student in _filteredStudents) {
        _attendanceStatus[student.regNumber] =
            _selectAll ? 'present' : 'absent';
      }
    });
  }

  Future<void> _submitAttendance() async {
    final today = DateTime.now().toString().split(' ')[0];
    int markedCount = 0;

    for (var student in _filteredStudents) {
      if (_attendanceStatus[student.regNumber] != 'absent') {
        await DatabaseService.markAttendance(
          regNumber: student.regNumber,
          date: today,
          status: _attendanceStatus[student.regNumber]!,
          unitName: _selectedCourse!,
        );
        markedCount++;
      }
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Attendance marked for $markedCount students!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Mark Attendance'),
        backgroundColor: const Color(0xFF667eea),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Course Selection
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Column(
              children: [
                DropdownButtonFormField<String>(
                  initialValue: _selectedCourse,
                  decoration: const InputDecoration(
                    labelText: 'Select Course',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.school),
                  ),
                  items: _courses.map((course) {
                    return DropdownMenuItem(value: course, child: Text(course));
                  }).toList(),
                  onChanged: (value) async {
                    setState(() {
                      _selectedCourse = value;
                      _attendanceStatus.clear();
                    });
                    await _loadStudents();
                  },
                ),
                const SizedBox(height: 12),
                // Search Bar
                TextField(
                  decoration: InputDecoration(
                    labelText: 'Search Student',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () => _filterStudents(''),
                          )
                        : null,
                  ),
                  onChanged: _filterStudents,
                ),
              ],
            ),
          ),

          // Select All Row
          if (_filteredStudents.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Colors.grey.shade100,
              child: Row(
                children: [
                  Checkbox(
                    value: _selectAll,
                    onChanged: (_) => _toggleSelectAll(),
                    activeColor: Colors.green,
                  ),
                  const Text('Select All Students'),
                  const Spacer(),
                  Text(
                    '${_filteredStudents.length} students',
                    style: const TextStyle(color: Colors.grey),
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
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.people_outline,
                                size: 64, color: Colors.grey),
                            SizedBox(height: 16),
                            Text('No students found',
                                style: TextStyle(color: Colors.grey)),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(8),
                        itemCount: _filteredStudents.length,
                        itemBuilder: (context, index) {
                          final student = _filteredStudents[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: const Color(0xFF667eea),
                                child: Text(
                                  student.name[0].toUpperCase(),
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                              title: Text(student.name),
                              subtitle: Text(
                                  '${student.regNumber} • ${student.course}'),
                              trailing: DropdownButton<String>(
                                value: _attendanceStatus[student.regNumber],
                                items: const [
                                  DropdownMenuItem(
                                    value: 'present',
                                    child: Text('Present',
                                        style: TextStyle(color: Colors.green)),
                                  ),
                                  DropdownMenuItem(
                                    value: 'late',
                                    child: Text('Late',
                                        style: TextStyle(color: Colors.orange)),
                                  ),
                                  DropdownMenuItem(
                                    value: 'absent',
                                    child: Text('Absent',
                                        style: TextStyle(color: Colors.red)),
                                  ),
                                ],
                                onChanged: (value) {
                                  setState(() {
                                    _attendanceStatus[student.regNumber] =
                                        value!;
                                  });
                                },
                              ),
                            ),
                          );
                        },
                      ),
          ),

          // Submit Button
          if (_selectedCourse != null && _filteredStudents.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.white,
              child: ElevatedButton(
                onPressed: _submitAttendance,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'Submit Attendance',
                  style: TextStyle(fontSize: 18),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ==================== 2. QR CODE ATTENDANCE ====================
class QRCodeAttendanceScreen extends StatefulWidget {
  const QRCodeAttendanceScreen({super.key});

  @override
  State<QRCodeAttendanceScreen> createState() => _QRCodeAttendanceScreenState();
}

class _QRCodeAttendanceScreenState extends State<QRCodeAttendanceScreen> {
  String? _selectedCourse;
  bool _showQR = false;
  String _sessionId = '';
  final List<String> _scannedStudents = [];
  final bool _isScanning = false; // ignore: unused_field
  // Add these methods inside the _QRCodeAttendanceScreenState class

  Future<bool> _checkLocationPermission() async {
    PermissionStatus permission = await Permission.location.status;
    if (permission.isDenied) {
      permission = await Permission.location.request();
    }
    if (permission.isDenied || permission.isRestricted) {
      return false;
    }
    return true;
  }

  Future<bool> _isWithinClassroom() async {
    // Check permissions
    bool hasPermission = await _checkLocationPermission();
    if (!hasPermission) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location permission required!')),
        );
      }
      return false;
    }

    try {
      // REMOVED the 'locationSettings' parameter - this was causing the error
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      ).timeout(const Duration(seconds: 10));

      // CLASSROOM COORDINATES - CHANGE THESE TO YOUR ACTUAL CLASSROOM LOCATION
      final classroomLat = -1.123456; // Replace with actual latitude
      final classroomLng = 36.123456; // Replace with actual longitude

      double distance = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        classroomLat,
        classroomLng,
      );

      // Allow only if within 50 meters of classroom
      return distance < 50;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Location error: $e')),
        );
      }
      return false;
    }
  }

  Future<String> _getCurrentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition();
      return '${position.latitude},${position.longitude}';
    } catch (e) {
      return 'unknown';
    }
  }

  final List<String> _courses = [
    'BSc Computer Science',
    'BSc Information Technology',
    'BSc Software Engineering',
  ];

  void _generateQRCode() {
    setState(() {
      _sessionId = DateTime.now().millisecondsSinceEpoch.toString();
      _showQR = true;
      _scannedStudents.clear();
    });

    // Auto-hide QR after 5 minutes
    Future.delayed(const Duration(minutes: 5), () {
      if (mounted && _showQR) {
        setState(() => _showQR = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('QR Code expired')),
        );
      }
    });
  }

  void _addScannedStudent(String regNumber) async {
    if (_scannedStudents.contains(regNumber)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('⚠️ Student $regNumber already scanned')),
      );
      return;
    }

    // LOCATION CHECK - ADDED HERE
    bool withinClassroom = await _isWithinClassroom();

    if (!withinClassroom) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('❌ Location Error'),
            content: const Text(
              'You must be inside the classroom to mark attendance!\n\n'
              'Please go to the classroom and try again.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
      return;
    }

    // Also log the location for verification
    String location = await _getCurrentLocation();
    await DatabaseService.logAttendanceAttempt(
      regNumber: regNumber,
      timestamp: DateTime.now(),
      location: location,
    );

    setState(() {
      _scannedStudents.add(regNumber);
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                '✅ Student $regNumber marked present (Location verified)')),
      );
    }
  }

  Future<void> _saveQRCAttendance() async {
    final today = DateTime.now().toString().split(' ')[0];

    for (var regNumber in _scannedStudents) {
      await DatabaseService.markAttendance(
        regNumber: regNumber,
        date: today,
        status: 'present',
        unitName: _selectedCourse!,
      );
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content:
              Text('✅ Saved ${_scannedStudents.length} attendance records')),
    );
    setState(() {
      _showQR = false;
      _scannedStudents.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('QR Code Attendance'),
        backgroundColor: const Color(0xFF667eea),
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (!_showQR) ...[
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        const Icon(Icons.qr_code,
                            size: 80, color: Color(0xFF667eea)),
                        const SizedBox(height: 20),
                        const Text(
                          'Generate QR Code',
                          style: TextStyle(
                              fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'Students scan this QR code to mark attendance',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey),
                        ),
                        const SizedBox(height: 20),
                        DropdownButtonFormField<String>(
                          initialValue: _selectedCourse,
                          decoration: const InputDecoration(
                            labelText: 'Select Course',
                            border: OutlineInputBorder(),
                          ),
                          items: _courses.map((course) {
                            return DropdownMenuItem(
                                value: course, child: Text(course));
                          }).toList(),
                          onChanged: (value) =>
                              setState(() => _selectedCourse = value),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton.icon(
                          onPressed:
                              _selectedCourse == null ? null : _generateQRCode,
                          icon: const Icon(Icons.qr_code),
                          label: const Text('Generate QR Code'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF667eea),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 32, vertical: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              if (_showQR) ...[
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        const Icon(Icons.qr_code_scanner,
                            size: 50, color: Colors.green),
                        const SizedBox(height: 10),
                        const Text(
                          'QR Code Active',
                          style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.green),
                        ),
                        const SizedBox(height: 20),
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.1),
                                  blurRadius: 10),
                            ],
                          ),
                          child: QrImageView(
                            data:
                                'campus_flow_attendance_${_selectedCourse}_$_sessionId',
                            version: QrVersions.auto,
                            size: 200,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Course: $_selectedCourse',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Scanned: ${_scannedStudents.length} students',
                          style: const TextStyle(color: Colors.green),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () =>
                                    setState(() => _showQR = false),
                                icon: const Icon(Icons.close),
                                label: const Text('Close'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: _saveQRCAttendance,
                                icon: const Icon(Icons.save),
                                label: const Text('Save'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // Student Scanner View (for lecturer to test)
                const SizedBox(height: 20),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        const Text('Test Scanner (Demo)',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 10),
                        SizedBox(
                          height: 200,
                          child: MobileScanner(
                            onDetect: (capture) {
                              final List<Barcode> barcodes = capture.barcodes;
                              for (var barcode in barcodes) {
                                if (barcode.rawValue != null) {
                                  _addScannedStudent(barcode.rawValue!);
                                }
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ==================== 3. STUDENT LIST SCREEN ====================
class StudentListScreen extends StatefulWidget {
  const StudentListScreen({super.key});

  @override
  State<StudentListScreen> createState() => _StudentListScreenState();
}

class _StudentListScreenState extends State<StudentListScreen> {
  List<Student> _students = [];
  bool _isLoading = true;
  String? _selectedCourse;
  String _searchQuery = '';

  final List<String> _courses = [
    'BSc Computer Science',
    'BSc Information Technology',
    'BSc Software Engineering',
    'BSc Data Science',
    'BSc Cybersecurity',
  ];

  @override
  void initState() {
    super.initState();
    _loadStudents();
  }

  Future<void> _loadStudents() async {
    setState(() => _isLoading = true);

    if (_selectedCourse != null) {
      _students = await DatabaseService.getStudentsByCourse(_selectedCourse!);
    }

    setState(() => _isLoading = false);
  }

  List<Student> get _filteredStudents {
    if (_searchQuery.isEmpty) return _students;
    return _students
        .where((student) =>
            student.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            student.regNumber
                .toLowerCase()
                .contains(_searchQuery.toLowerCase()))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Student List'),
        backgroundColor: const Color(0xFF667eea),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Column(
              children: [
                DropdownButtonFormField<String>(
                  initialValue: _selectedCourse,
                  decoration: const InputDecoration(
                    labelText: 'Select Course',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.school),
                  ),
                  items: _courses.map((course) {
                    return DropdownMenuItem(value: course, child: Text(course));
                  }).toList(),
                  onChanged: (value) async {
                    setState(() => _selectedCourse = value);
                    await _loadStudents();
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  decoration: InputDecoration(
                    labelText: 'Search Student',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onChanged: (value) => setState(() => _searchQuery = value),
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredStudents.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.people_outline,
                                size: 64, color: Colors.grey),
                            SizedBox(height: 16),
                            Text('No students found',
                                style: TextStyle(color: Colors.grey)),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(8),
                        itemCount: _filteredStudents.length,
                        itemBuilder: (context, index) {
                          final student = _filteredStudents[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            child: ExpansionTile(
                              leading: CircleAvatar(
                                backgroundColor: const Color(0xFF667eea),
                                child: Text(
                                  student.name[0].toUpperCase(),
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                              title: Text(student.name),
                              subtitle: Text(student.regNumber),
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      _infoRow(
                                          Icons.email, 'Email', student.email),
                                      const SizedBox(height: 8),
                                      _infoRow(
                                          Icons.phone, 'Phone', student.phone),
                                      const SizedBox(height: 8),
                                      _infoRow(Icons.book, 'Semester',
                                          '${student.semester}'),
                                      const SizedBox(height: 8),
                                      _infoRow(
                                          Icons.calendar_today,
                                          'Registered',
                                          '${student.registrationDate.day}/${student.registrationDate.month}/${student.registrationDate.year}'),
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

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey),
        const SizedBox(width: 8),
        Text('$label:', style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(width: 8),
        Text(value),
      ],
    );
  }
}

// ==================== 4. ATTENDANCE HISTORY SCREEN ====================
class AttendanceHistoryScreen extends StatefulWidget {
  const AttendanceHistoryScreen({super.key});

  @override
  State<AttendanceHistoryScreen> createState() =>
      _AttendanceHistoryScreenState();
}

class _AttendanceHistoryScreenState extends State<AttendanceHistoryScreen> {
  List<Map<String, dynamic>> _attendanceRecords = [];
  bool _isLoading = true;
  String? _selectedCourse;
  DateTime _selectedDate = DateTime.now();

  final List<String> _courses = [
    'BSc Computer Science',
    'BSc Information Technology',
    'BSc Software Engineering',
  ];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() => _isLoading = true);

    // Get all students and their attendance
    if (_selectedCourse != null) {
      final students =
          await DatabaseService.getStudentsByCourse(_selectedCourse!);
      List<Map<String, dynamic>> allRecords = [];

      for (var student in students) {
        final attendance =
            await DatabaseService.getAttendance(student.regNumber);
        for (var record in attendance) {
          record['studentName'] = student.name;
          record['regNumber'] = student.regNumber;
          allRecords.add(record);
        }
      }

      // Filter by selected date
      final dateStr =
          '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}';
      allRecords = allRecords.where((r) => r['date'] == dateStr).toList();

      setState(() {
        _attendanceRecords = allRecords;
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Attendance History'),
        backgroundColor: const Color(0xFF667eea),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Column(
              children: [
                DropdownButtonFormField<String>(
                  initialValue: _selectedCourse,
                  decoration: const InputDecoration(
                    labelText: 'Select Course',
                    border: OutlineInputBorder(),
                  ),
                  items: _courses.map((course) {
                    return DropdownMenuItem(value: course, child: Text(course));
                  }).toList(),
                  onChanged: (value) async {
                    setState(() => _selectedCourse = value);
                    await _loadHistory();
                  },
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: _selectedDate,
                            firstDate: DateTime(2024),
                            lastDate: DateTime.now(),
                          );
                          if (date != null) {
                            setState(() => _selectedDate = date);
                            await _loadHistory();
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_today),
                              const SizedBox(width: 8),
                              Text(
                                  '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}'),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _attendanceRecords.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.history, size: 64, color: Colors.grey),
                            SizedBox(height: 16),
                            Text('No attendance records found',
                                style: TextStyle(color: Colors.grey)),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(8),
                        itemCount: _attendanceRecords.length,
                        itemBuilder: (context, index) {
                          final record = _attendanceRecords[index];
                          Color statusColor;
                          IconData statusIcon;

                          switch (record['status']) {
                            case 'present':
                              statusColor = Colors.green;
                              statusIcon = Icons.check_circle;
                              break;
                            case 'late':
                              statusColor = Colors.orange;
                              statusIcon = Icons.access_time;
                              break;
                            default:
                              statusColor = Colors.red;
                              statusIcon = Icons.cancel;
                          }

                          return Card(
                            margin: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor:
                                    statusColor.withValues(alpha: 0.1),
                                child: Icon(statusIcon, color: statusColor),
                              ),
                              title: Text(record['studentName']),
                              subtitle: Text(record['regNumber']),
                              trailing: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 4),
                                decoration: BoxDecoration(
                                  color: statusColor.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  record['status'].toUpperCase(),
                                  style: TextStyle(
                                      color: statusColor,
                                      fontWeight: FontWeight.bold),
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
