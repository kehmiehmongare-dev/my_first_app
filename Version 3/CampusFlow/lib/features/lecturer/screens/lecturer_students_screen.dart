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
  // ==================== STATE VARIABLES ====================
  bool _isLoading = true;
  String _searchQuery = '';
  String _selectedFilter = 'All';
  String _unitName = '';
  String _unitCode = '';
  String _lecturerName = '';

  List<String> _lecturerUnits = [];
  List<Map<String, dynamic>> _allStudents = [];
  List<Map<String, dynamic>> _filteredStudents = [];
  List<String> _availableFilters = [];

  // ==================== INIT ====================
  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // ==================== LOAD DATA ====================
  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _showError('Please login again');
        setState(() => _isLoading = false);
        return;
      }

      // ✅ Get lecturer details
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
      _lecturerName = lecturerData['displayName'] ?? 'Lecturer';
      _lecturerUnits = List<String>.from(lecturerData['units'] ?? []);

      // ✅ Get unit name from first unit (for display)
      if (_lecturerUnits.isNotEmpty) {
        _unitCode = _lecturerUnits.first;
        final unitDoc = await FirebaseFirestore.instance
            .collection('units')
            .doc(_unitCode)
            .get();
        if (unitDoc.exists) {
          final unitData = unitDoc.data() as Map<String, dynamic>;
          _unitName = unitData['name'] ?? _unitCode;
        } else {
          _unitName = _unitCode;
        }
      }

      // ✅ Get all students
      final studentsSnapshot =
          await FirebaseFirestore.instance.collection('students').get();

      _allStudents = studentsSnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();

      // ✅ Filter students by lecturer's units
      if (_lecturerUnits.isNotEmpty) {
        _allStudents = _allStudents.where((student) {
          final registeredUnits = _getRegisteredUnits(student);
          return registeredUnits.any((unit) => _lecturerUnits.contains(unit));
        }).toList();
      }

      // ✅ Build available filters from student courses
      final courseCodes = _allStudents
          .map((s) => s['courseCode']?.toString() ?? '')
          .where((c) => c.isNotEmpty)
          .toSet();
      _availableFilters = ['All', ...courseCodes];

      _filteredStudents = List.from(_allStudents);
      setState(() => _isLoading = false);
    } catch (e) {
      debugPrint('Error loading data: $e');
      _showError('Error loading data: $e');
      setState(() => _isLoading = false);
    }
  }

  // ==================== HELPERS ====================
  List<String> _getRegisteredUnits(Map<String, dynamic> student) {
    final units = student['registeredUnits'];
    if (units == null) return [];

    if (units is List) {
      if (units.isNotEmpty) {
        if (units[0] is String) {
          return List<String>.from(units);
        } else if (units[0] is Map) {
          return units
              .map((e) => (e as Map<String, dynamic>)['code']?.toString() ?? '')
              .where((e) => e.isNotEmpty)
              .toList();
        }
      }
    }
    return [];
  }

  void _applyFilters() {
    setState(() {
      // ✅ Apply filter (All / Course)
      if (_selectedFilter == 'All') {
        _filteredStudents = List.from(_allStudents);
      } else {
        _filteredStudents = _allStudents.where((student) {
          final studentCourse = student['courseCode']?.toString() ?? '';
          return studentCourse == _selectedFilter;
        }).toList();
      }

      // ✅ Apply search (Name / Reg Number)
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        _filteredStudents = _filteredStudents.where((student) {
          final name = student['displayName']?.toString().toLowerCase() ?? '';
          final regNumber =
              student['regNumber']?.toString().toLowerCase() ?? '';
          return name.contains(query) || regNumber.contains(query);
        }).toList();
      }
    });
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

  // ==================== BUILD ====================
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
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  // ✅ Unit Header
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    color: Colors.white,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '📚 $_unitCode - $_unitName',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _lecturerName,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ✅ Search Bar
                  Container(
                    padding: const EdgeInsets.all(16),
                    color: Colors.white,
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: '🔍 Search by Name or Registration Number...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  setState(() {
                                    _searchQuery = '';
                                    _applyFilters();
                                  });
                                },
                              )
                            : null,
                        filled: true,
                        fillColor: Colors.grey.shade50,
                      ),
                      onChanged: (value) {
                        _searchQuery = value;
                        _applyFilters();
                      },
                    ),
                  ),

                  // ✅ Filter Buttons
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    color: Colors.white,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: _availableFilters.map((filter) {
                          final isSelected = _selectedFilter == filter;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: FilterChip(
                              label: Text(filter),
                              selected: isSelected,
                              onSelected: (selected) {
                                setState(() {
                                  _selectedFilter = selected ? filter : 'All';
                                  _applyFilters();
                                });
                              },
                              selectedColor: AppColors.primary,
                              backgroundColor: Colors.grey.shade100,
                              labelStyle: TextStyle(
                                color: isSelected
                                    ? Colors.white
                                    : Colors.grey[800],
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),

                  // ✅ Student Count
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${_filteredStudents.length} students found',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                        ),
                        if (_selectedFilter != 'All')
                          Text(
                            'Filter: $_selectedFilter',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                      ],
                    ),
                  ),

                  // ✅ Student List
                  Expanded(
                    child: _filteredStudents.isEmpty
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
                                  _allStudents.isEmpty
                                      ? 'No students registered for this unit'
                                      : 'No students match your search',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.8),
                                    fontSize: 16,
                                  ),
                                ),
                                if (_searchQuery.isNotEmpty)
                                  TextButton(
                                    onPressed: () {
                                      setState(() {
                                        _searchQuery = '';
                                        _applyFilters();
                                      });
                                    },
                                    child: const Text(
                                      'Clear Search',
                                      style: TextStyle(color: Colors.white70),
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
                              final courseCode =
                                  student['courseCode']?.toString() ?? 'N/A';
                              final regNumber =
                                  student['regNumber']?.toString() ?? 'N/A';
                              final name = student['displayName']?.toString() ??
                                  'Unknown';

                              return Card(
                                margin: const EdgeInsets.only(bottom: 8),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: AppColors.primary
                                        .withValues(alpha: 0.1),
                                    child: Text(
                                      name.isNotEmpty
                                          ? name[0].toUpperCase()
                                          : 'S',
                                      style: const TextStyle(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  title: Text(
                                    name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  subtitle: Text(
                                    'Reg: $regNumber',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  trailing: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary
                                          .withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      courseCode,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
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
