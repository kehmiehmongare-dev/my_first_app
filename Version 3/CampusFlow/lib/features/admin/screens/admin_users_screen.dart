import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:campus_flow/shared/constants/app_colors.dart';
import 'package:campus_flow/services/delete_service.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  String _selectedFilter = 'all';
  String _searchQuery = '';
  bool _isLoading = true;
  List<Map<String, dynamic>> _users = [];
  final List<String> _filters = ['all', 'student', 'lecturer', 'admin'];
  final DeleteService _deleteService = DeleteService();

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  // ==================== LOAD USERS ====================
  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);

    try {
      QuerySnapshot snapshot;
      if (_selectedFilter == 'all') {
        snapshot = await FirebaseFirestore.instance.collection('users').get();
      } else {
        snapshot = await FirebaseFirestore.instance
            .collection('users')
            .where('role', isEqualTo: _selectedFilter)
            .get();
      }

      _users = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['uid'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      debugPrint('Error loading users: $e');
    }

    setState(() => _isLoading = false);
  }

  // ==================== GET FILTERED USERS ====================
  List<Map<String, dynamic>> get _filteredUsers {
    if (_searchQuery.isEmpty) return _users;
    return _users.where((user) {
      final name = (user['displayName'] ?? '').toLowerCase();
      final email = (user['email'] ?? '').toLowerCase();
      final query = _searchQuery.toLowerCase();
      return name.contains(query) || email.contains(query);
    }).toList();
  }

  // ==================== CHANGE USER ROLE ====================
  Future<void> _changeUserRole(String uid, String newRole) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .update({'role': newRole});

      _showMessage('✅ User role updated to $newRole', Colors.green);
      await _loadUsers();
    } catch (e) {
      _showMessage('❌ Error: $e', Colors.red);
    }
  }

  // ==================== TOGGLE USER STATUS ====================
  Future<void> _toggleUserStatus(String uid, bool currentStatus) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .update({'isActive': !currentStatus});

      _showMessage(
        '✅ User ${currentStatus ? 'deactivated' : 'activated'}',
        Colors.green,
      );
      await _loadUsers();
    } catch (e) {
      _showMessage('❌ Error: $e', Colors.red);
    }
  }

  // ==================== DELETE USER ====================
  Future<void> _deleteUser(String uid, String name, String role) async {
    // ✅ Show confirmation dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete User'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Are you sure you want to delete $name?'),
            const SizedBox(height: 8),
            const Text(
              '⚠️ This action is permanent and cannot be undone.',
              style: TextStyle(color: Colors.red, fontSize: 12),
            ),
            const SizedBox(height: 8),
            Text(
              'This will delete all related data including attendance, payments, and courses.',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete Permanently'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    // ✅ Show loading
    setState(() => _isLoading = true);

    try {
      DeleteResult result;
      if (role == 'student') {
        result = await _deleteService.deleteStudent(uid: uid, email: '');
      } else if (role == 'lecturer') {
        result = await _deleteService.deleteLecturer(uid: uid, email: '');
      } else {
        _showMessage('Cannot delete admin users.', Colors.orange);
        setState(() => _isLoading = false);
        return;
      }

      if (result.isSuccess) {
        _showMessage('✅ $name deleted successfully!', Colors.green);
        await _loadUsers();
      } else {
        _showMessage('❌ ${result.message}', Colors.red);
      }
    } catch (e) {
      _showMessage('❌ Error: $e', Colors.red);
    }

    setState(() => _isLoading = false);
  }

  // ==================== ASSIGN COURSE TO LECTURER ====================
  Future<void> _assignCourseToLecturer(
      String lecturerId, String courseCode) async {
    try {
      await FirebaseFirestore.instance
          .collection('lecturers')
          .doc(lecturerId)
          .update({
        'courses': FieldValue.arrayUnion([courseCode]),
      });
      _showMessage('✅ Course assigned successfully!', Colors.green);
    } catch (e) {
      _showMessage('❌ Error: $e', Colors.red);
    }
  }

  // ==================== SHOW MESSAGE ====================
  void _showMessage(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // ==================== INFO ROW WIDGET ====================
  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  // ==================== BUILD ====================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Management'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              _showMessage('Add user feature coming soon!', Colors.orange);
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadUsers,
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
            // ✅ Filter Tabs
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Colors.white,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _filters.map((filter) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(filter.toUpperCase()),
                        selected: _selectedFilter == filter,
                        onSelected: (selected) {
                          setState(() {
                            _selectedFilter = filter;
                          });
                          _loadUsers();
                        },
                        selectedColor: AppColors.primary,
                        labelStyle: TextStyle(
                          color: _selectedFilter == filter
                              ? Colors.white
                              : Colors.grey,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),

            // ✅ Search Bar
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search users...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () => setState(() => _searchQuery = ''),
                        )
                      : null,
                ),
                onChanged: (value) => setState(() => _searchQuery = value),
              ),
            ),

            // ✅ User List
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _filteredUsers.isEmpty
                      ? const Center(
                          child: Text(
                            'No users found',
                            style: TextStyle(color: Colors.white),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(8),
                          itemCount: _filteredUsers.length,
                          itemBuilder: (context, index) {
                            final user = _filteredUsers[index];
                            return Card(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              child: ExpansionTile(
                                leading: CircleAvatar(
                                  backgroundColor: AppColors.primary,
                                  child: Text(
                                    (user['displayName'] ?? 'U')[0],
                                    style: const TextStyle(
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                                title: Text(user['displayName'] ?? 'Unknown'),
                                subtitle: Text(user['email'] ?? ''),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: user['isActive'] == false
                                            ? Colors.red
                                            : (user['role'] == 'student'
                                                ? Colors.blue
                                                : Colors.green),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        user['role'] ?? 'student',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                        ),
                                      ),
                                    ),
                                    // ✅ Delete Button
                                    IconButton(
                                      icon: const Icon(
                                        Icons.delete,
                                        color: Colors.red,
                                      ),
                                      onPressed: () => _deleteUser(
                                        user['uid'],
                                        user['displayName'] ?? 'User',
                                        user['role'] ?? 'student',
                                      ),
                                      tooltip: 'Delete User',
                                      iconSize: 20,
                                    ),
                                  ],
                                ),
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      children: [
                                        _infoRow('UID', user['uid'] ?? 'N/A'),
                                        _infoRow(
                                            'Role', user['role'] ?? 'student'),
                                        _infoRow(
                                          'Status',
                                          user['isActive'] == false
                                              ? 'Inactive'
                                              : 'Active',
                                        ),
                                        _infoRow(
                                          'Created',
                                          (user['createdAt'] as Timestamp?)
                                                  ?.toDate()
                                                  .toString() ??
                                              'N/A',
                                        ),
                                        const SizedBox(height: 16),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceEvenly,
                                          children: [
                                            DropdownButton<String>(
                                              value: user['role'] ?? 'student',
                                              items: const [
                                                DropdownMenuItem(
                                                  value: 'student',
                                                  child: Text('Student'),
                                                ),
                                                DropdownMenuItem(
                                                  value: 'lecturer',
                                                  child: Text('Lecturer'),
                                                ),
                                                DropdownMenuItem(
                                                  value: 'admin',
                                                  child: Text('Admin'),
                                                ),
                                              ],
                                              onChanged: (value) {
                                                if (value != null) {
                                                  _changeUserRole(
                                                    user['uid'],
                                                    value,
                                                  );
                                                }
                                              },
                                            ),
                                            ElevatedButton(
                                              onPressed: () =>
                                                  _toggleUserStatus(
                                                user['uid'],
                                                user['isActive'] ?? true,
                                              ),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor:
                                                    user['isActive'] == false
                                                        ? Colors.green
                                                        : Colors.red,
                                                foregroundColor: Colors.white,
                                              ),
                                              child: Text(
                                                user['isActive'] == false
                                                    ? 'Activate'
                                                    : 'Deactivate',
                                              ),
                                            ),
                                          ],
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
