import 'package:flutter/material.dart';

class RecordManagementScreen extends StatefulWidget {
  const RecordManagementScreen({super.key});

  @override
  State<RecordManagementScreen> createState() => _RecordManagementScreenState();
}

class _RecordManagementScreenState extends State<RecordManagementScreen> {
  List<Map<String, dynamic>> _records = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRecords();
  }

  Future<void> _loadRecords() async {
    setState(() => _isLoading = true);
    // Simulate loading
    await Future.delayed(const Duration(seconds: 1));
    setState(() {
      _records = [
        {'id': 1, 'title': 'Sample Record 1', 'category': 'Academic'},
        {'id': 2, 'title': 'Sample Record 2', 'category': 'Personal'},
      ];
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Record Management'),
        backgroundColor: const Color(0xFF667eea),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _records.length,
              itemBuilder: (context, index) {
                final record = _records[index];
                return Card(
                  child: ListTile(
                    title: Text(record['title']),
                    subtitle: Text(record['category']),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: const Color(0xFF667eea),
        child: const Icon(Icons.add),
      ),
    );
  }
}
