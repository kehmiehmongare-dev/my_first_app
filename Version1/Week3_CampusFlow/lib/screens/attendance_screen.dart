import 'package:flutter/material.dart';
import 'package:campus_flow/models/student_model.dart';
import 'package:campus_flow/services/database_service.dart';
import 'package:intl/intl.dart';

class AttendanceScreen extends StatefulWidget {
  final Student student;
  const AttendanceScreen({super.key, required this.student});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  List<Map<String, dynamic>> _attendance = [];
  bool _isLoading = true;
  final List<String> _statusOptions = ['present', 'absent', 'late'];
  String _selectedStatus = 'present';

  @override
  void initState() {
    super.initState();
    _loadAttendance();
  }

  Future<void> _loadAttendance() async {
    final attendance =
        await DatabaseService.getAttendance(widget.student.regNumber);
    setState(() {
      _attendance = attendance;
      _isLoading = false;
    });
  }

  Future<void> _markAttendance() async {
    final date = DateFormat('yyyy-MM-dd').format(DateTime.now());
    await DatabaseService.markAttendance(
      regNumber: widget.student.regNumber,
      date: date,
      status: _selectedStatus,
      unitName: 'General',
    );
    await _loadAttendance();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Attendance marked!'), backgroundColor: Colors.green),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Attendance', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${(_attendance.where((a) => a['status'] == 'present').length / (_attendance.isEmpty ? 1 : _attendance.length) * 100).toStringAsFixed(1)}%',
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Today's attendance card
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                const Text('Mark Today\'s Attendance',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ..._statusOptions.map((status) => Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: ChoiceChip(
                            label: Text(status.toUpperCase()),
                            selected: _selectedStatus == status,
                            onSelected: (selected) {
                              if (selected) {
                                setState(() => _selectedStatus = status);
                              }
                            },
                            selectedColor: status == 'present'
                                ? Colors.green
                                : status == 'absent'
                                    ? Colors.red
                                    : Colors.orange,
                            labelStyle: TextStyle(
                                color: _selectedStatus == status
                                    ? Colors.white
                                    : Colors.grey),
                          ),
                        )),
                  ],
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _markAttendance,
                  icon: const Icon(Icons.check_circle),
                  label: const Text('Mark Attendance'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF667eea),
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 45),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
          ),
          // History
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Recent History',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white)),
                Text('${_attendance.length} records',
                    style: TextStyle(color: Colors.white70)),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Colors.white))
                : _attendance.isEmpty
                    ? const Center(
                        child: Text('No attendance records yet',
                            style: TextStyle(color: Colors.white70)))
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _attendance.length,
                        itemBuilder: (context, index) {
                          final record = _attendance[index];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: record['status'] == 'present'
                                        ? Colors.green.withValues(alpha: 0.1)
                                        : record['status'] == 'absent'
                                            ? Colors.red.withValues(alpha: 0.1)
                                            : Colors.orange
                                                .withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    record['status'] == 'present'
                                        ? Icons.check_circle
                                        : record['status'] == 'absent'
                                            ? Icons.cancel
                                            : Icons.access_time,
                                    color: record['status'] == 'present'
                                        ? Colors.green
                                        : record['status'] == 'absent'
                                            ? Colors.red
                                            : Colors.orange,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(record['date'],
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold)),
                                      Text(record['unitName'],
                                          style: TextStyle(
                                              color: Colors.grey[600],
                                              fontSize: 12)),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: record['status'] == 'present'
                                        ? Colors.green
                                        : record['status'] == 'absent'
                                            ? Colors.red
                                            : Colors.orange,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    record['status'].toUpperCase(),
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold),
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
}
