import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'database_helper.dart';

/// ONE-TIME MIGRATION SCRIPT
/// This migrates existing local database users to Firebase
///
/// HOW TO USE:
/// 1. Add this button temporarily to your login page or profile page
/// 2. Run it once to migrate
/// 3. Remove this file after migration complete

class MigrateToFirebaseButton extends StatelessWidget {
  const MigrateToFirebaseButton({super.key});

  Future<void> _migrateCurrentUser(BuildContext context) async {
    try {
      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      // Get current local user
      DatabaseHelper dbHelper = DatabaseHelper();
      Map<String, dynamic>? localUser = await dbHelper.getCurrentUser();

      if (localUser == null) {
        if (context.mounted) Navigator.pop(context);
        _showMessage(context, 'No local user found to migrate', Colors.red);
        return;
      }

      String email = localUser['email'] ?? '';

      // Check if user is already logged in to Firebase
      User? firebaseUser = FirebaseAuth.instance.currentUser;

      if (firebaseUser != null && firebaseUser.email == email) {
        // User is already logged in to Firebase, just update Firestore
        await _updateFirestoreProfile(firebaseUser, localUser);

        if (context.mounted) Navigator.pop(context);
        _showMessage(
          context,
          '✅ Successfully migrated to Firebase!',
          Colors.green,
        );
        return;
      }

      // If not logged in, show error - user needs to know their password
      if (context.mounted) Navigator.pop(context);
      _showMessage(
        context,
        '⚠️ Please log out and log in again with your password to complete migration',
        Colors.orange,
      );
    } catch (e) {
      if (context.mounted) Navigator.pop(context);
      _showMessage(context, 'Migration failed: $e', Colors.red);
    }
  }

  Future<void> _updateFirestoreProfile(
    User firebaseUser,
    Map<String, dynamic> localUser,
  ) async {
    // Ensure all values are properly converted to strings or defaults
    final fullName = localUser['full_name']?.toString() ?? '';
    final phoneNumber = localUser['phone_number']?.toString() ?? '';
    final email = localUser['email']?.toString() ?? firebaseUser.email ?? '';
    final dateOfBirth = localUser['date_of_birth']?.toString() ?? '';
    final age = (localUser['age'] is int)
        ? localUser['age']
        : (int.tryParse(localUser['age']?.toString() ?? '0') ?? 0);
    final gender = localUser['gender']?.toString() ?? '';
    final screenTimeLimit = (localUser['screen_time_limit'] is double)
        ? localUser['screen_time_limit']
        : (double.tryParse(
                localUser['screen_time_limit']?.toString() ?? '7.0',
              ) ??
              7.0);

    await FirebaseFirestore.instance
        .collection('users')
        .doc(firebaseUser.uid)
        .set({
          'fullName': fullName,
          'phoneNumber': phoneNumber,
          'email': email,
          'dateOfBirth': dateOfBirth,
          'age': age,
          'gender': gender,
          'screenTimeLimit': screenTimeLimit,
          'uid': firebaseUser.uid,
          'createdAt': FieldValue.serverTimestamp(),
          'lastLogin': FieldValue.serverTimestamp(),
          'accountStatus': 'active',
          'migratedFromLocal': true, // Flag to track migration
        }, SetOptions(merge: true));

    // Initialize detox sessions
    await FirebaseFirestore.instance
        .collection('users')
        .doc(firebaseUser.uid)
        .collection('detoxSessions')
        .doc('_initialized')
        .set({'initialized': true, 'timestamp': FieldValue.serverTimestamp()});

    print('✅ User data saved to Firestore: ${firebaseUser.uid}');
  }

  void _showMessage(BuildContext context, String message, Color color) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: color,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: () => _migrateCurrentUser(context),
      icon: const Icon(Icons.cloud_upload),
      label: const Text('Migrate to Firebase'),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      ),
    );
  }
}
