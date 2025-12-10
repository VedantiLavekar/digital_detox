import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'database_helper.dart';

class UserStatusWidget extends StatefulWidget {
  const UserStatusWidget({super.key});

  @override
  State<UserStatusWidget> createState() => _UserStatusWidgetState();
}

class _UserStatusWidgetState extends State<UserStatusWidget> {
  String _userStatus = 'Checking...';
  String _userInfo = '';

  @override
  void initState() {
    super.initState();
    _checkUserStatus();
  }

  Future<void> _checkUserStatus() async {
    try {
      // Check Firebase user
      User? firebaseUser = FirebaseAuth.instance.currentUser;

      if (firebaseUser != null) {
        setState(() {
          _userStatus = 'Firebase User';
          _userInfo = 'Email: ${firebaseUser.email}\nUID: ${firebaseUser.uid}';
        });
        return;
      }

      // Check local database user
      final dbHelper = DatabaseHelper();
      Map<String, dynamic>? localUser = await dbHelper.getCurrentUser();

      if (localUser != null) {
        setState(() {
          _userStatus = 'Local Database User';
          _userInfo =
              'Email: ${localUser['email']}\nName: ${localUser['full_name']}';
        });
        return;
      }

      setState(() {
        _userStatus = 'No User Logged In';
        _userInfo = 'Please log in';
      });
    } catch (e) {
      setState(() {
        _userStatus = 'Error';
        _userInfo = 'Error checking user status: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _userStatus.contains('Firebase')
                      ? Icons.cloud_done
                      : _userStatus.contains('Local')
                      ? Icons.storage
                      : Icons.person_outline,
                  color: _userStatus.contains('Firebase')
                      ? Colors.green
                      : _userStatus.contains('Local')
                      ? Colors.blue
                      : Colors.grey,
                ),
                const SizedBox(width: 8),
                Text(
                  _userStatus,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(_userInfo),
            if (_userStatus.contains('Local')) ...[
              const SizedBox(height: 8),
              Text(
                'Note: Using offline mode. Will sync when Firebase is available.',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.blue[600],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
