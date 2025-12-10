import 'package:flutter/material.dart';
import 'database_helper.dart';

class AdminDatabaseView extends StatefulWidget {
  const AdminDatabaseView({super.key});

  @override
  State<AdminDatabaseView> createState() => _AdminDatabaseViewState();
}

class _AdminDatabaseViewState extends State<AdminDatabaseView> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  List<Map<String, dynamic>> _allUsers = [];
  List<Map<String, dynamic>> _allSessions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final users = await _dbHelper.getAllUsers();
      final sessions = await _getAllSessions();

      setState(() {
        _allUsers = users;
        _allSessions = sessions;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<List<Map<String, dynamic>>> _getAllSessions() async {
    try {
      final db = await _dbHelper.database;
      return await db.query('user_sessions', orderBy: 'login_time DESC');
    } catch (e) {
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Database Contents',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.deepPurple,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Registered Users (${_allUsers.length})',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          if (_allUsers.isEmpty)
                            const Text('No users found')
                          else
                            ..._allUsers.map((user) => _buildUserCard(user)),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Login Sessions (${_allSessions.length})',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          if (_allSessions.isEmpty)
                            const Text('No sessions found')
                          else
                            ..._allSessions
                                .take(10)
                                .map((session) => _buildSessionCard(session)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildUserCard(Map<String, dynamic> user) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                user['synced_with_firebase'] == 1
                    ? Icons.cloud_done
                    : Icons.storage,
                color: user['synced_with_firebase'] == 1
                    ? Colors.green
                    : Colors.blue,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  user['full_name'] ?? 'No name',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text('Email: ${user['email']}'),
          Text('Phone: ${user['phone_number'] ?? 'Not provided'}'),
          Text('Age: ${user['age'] ?? 'Not provided'}'),
          Text('Gender: ${user['gender'] ?? 'Not provided'}'),
          Text(
            'Screen Time Limit: ${user['screen_time_limit'] ?? 'Not set'} hrs',
          ),
          Text('Created: ${_formatDate(user['created_at'])}'),
          Text(
            'Sync Status: ${user['synced_with_firebase'] == 1 ? 'Synced with Firebase' : 'Local only'}',
            style: TextStyle(
              color: user['synced_with_firebase'] == 1
                  ? Colors.green
                  : Colors.blue,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionCard(Map<String, dynamic> session) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Row(
        children: [
          const Icon(Icons.login, color: Colors.blue, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${session['email']} - ${_formatDate(session['login_time'])}',
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) return 'Not available';

    try {
      DateTime date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateString;
    }
  }
}
