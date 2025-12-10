// lib/profile_page.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'landing_page.dart';
import 'login.dart';
import 'firestore_service.dart';
import 'database_helper.dart';

const Color kPrimaryColor = Color(0xFF2E9D8A);
const Color kBackgroundColor = Color(0xFFF5F5DC);
const Color kCardColor = Colors.white;

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  Map<String, dynamic>? userData;
  bool isLoading = true;
  String userSource = 'Firebase'; // Always Firebase now
  List<Map<String, dynamic>> loginHistory = [];
  final FirestoreService _firestoreService = FirestoreService();

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() {
      isLoading = true;
    });

    try {
      // Check local database FIRST
      final dbHelper = DatabaseHelper();
      Map<String, dynamic>? localUser = await dbHelper.getCurrentUser();

      print('🔍 Profile Page - Loading user data...');
      print('🔍 Local DB User: ${localUser != null ? "FOUND" : "NOT FOUND"}');

      if (localUser != null) {
        // User found in local database - USE THIS DATA
        print('✅ Showing user from local database: ${localUser['email']}');
        setState(() {
          userData = {
            'full_name': localUser['full_name'] ?? 'User',
            'email': localUser['email'] ?? '',
            'uid': localUser['id']?.toString() ?? '',
            'phone_number': localUser['phone_number'] ?? '',
            'date_of_birth': localUser['date_of_birth'] ?? '',
            'age': localUser['age'] ?? 0,
            'gender': localUser['gender'] ?? '',
            'screen_time_limit': localUser['screen_time_limit'] ?? 2.0,
            'created_at':
                localUser['created_at'] ?? DateTime.now().toIso8601String(),
            'last_login': DateTime.now().toIso8601String(),
          };
          userSource = 'Local Database';
          isLoading = false;
        });
        return;
      }

      // If not in local, try Firebase
      await FirebaseAuth.instance.currentUser?.reload();
      User? firebaseUser = FirebaseAuth.instance.currentUser;

      print('🔍 Firebase User: ${firebaseUser?.email ?? "NOT LOGGED IN"}');
      print('🔍 User UID: ${firebaseUser?.uid ?? "NO UID"}');
      if (firebaseUser != null) {
        // Fetch user profile from Firestore
        print('🔍 Fetching user profile from Firestore...');
        Map<String, dynamic>? firestoreData = await _firestoreService
            .getUserProfile();

        print('🔍 Firestore Data: ${firestoreData?.toString() ?? "NULL"}');

        if (firestoreData != null) {
          // Use Firestore data - user has migrated
          setState(() {
            userData = {
              'full_name': firestoreData['fullName'] ?? 'User',
              'email': firestoreData['email'] ?? firebaseUser.email ?? '',
              'uid': firebaseUser.uid,
              'phone_number': firestoreData['phoneNumber'] ?? '',
              'date_of_birth': firestoreData['dateOfBirth'] ?? '',
              'age': firestoreData['age'] ?? 0,
              'gender': firestoreData['gender'] ?? '',
              'screen_time_limit': firestoreData['screenTimeLimit'] ?? 2.0,
              'created_at': firestoreData['createdAt'] != null
                  ? (firestoreData['createdAt'] as Timestamp)
                        .toDate()
                        .toIso8601String()
                  : firebaseUser.metadata.creationTime?.toIso8601String() ?? '',
              'last_login': firestoreData['lastLogin'] != null
                  ? (firestoreData['lastLogin'] as Timestamp)
                        .toDate()
                        .toIso8601String()
                  : '',
            };
            userSource = 'Firebase';
            isLoading = false;
          });
          return;
        } else {
          // Firestore data not found, but Firebase user exists
          print('⚠️ No Firestore data found, showing basic Firebase info');
          // Show basic Firebase user data immediately
          setState(() {
            userData = {
              'full_name':
                  firebaseUser.displayName ??
                  firebaseUser.email?.split('@')[0] ??
                  'User',
              'email': firebaseUser.email ?? '',
              'uid': firebaseUser.uid,
              'phone_number': '',
              'date_of_birth': '',
              'age': 0,
              'gender': '',
              'screen_time_limit': 2.0,
              'created_at':
                  firebaseUser.metadata.creationTime?.toIso8601String() ?? '',
              'last_login': DateTime.now().toIso8601String(),
            };
            userSource = 'Firebase';
            isLoading = false;
          });
          // Try to migrate from local database in background
          _autoMigrateFromLocal(firebaseUser);
          return;
        }
      } else {
        print('❌ No Firebase user found - user is not logged in');
      }

      // No user at all
      setState(() {
        isLoading = false;
      });
    } catch (e) {
      print('Error loading user data: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _autoMigrateFromLocal(User firebaseUser) async {
    try {
      final dbHelper = DatabaseHelper();
      Map<String, dynamic>? localUser = await dbHelper.getCurrentUser();

      if (localUser != null && localUser['email'] == firebaseUser.email) {
        // Silently migrate to Firestore
        await _saveToFirestore(firebaseUser, localUser);
        print('✅ Auto-migrated user from local to Firebase');
        // Reload data
        _loadUserData();
      } else {
        // Show basic Firebase data - user is new or no local data
        setState(() {
          userData = {
            'full_name': firebaseUser.displayName ?? 'User',
            'email': firebaseUser.email ?? '',
            'uid': firebaseUser.uid,
            'phone_number': '',
            'date_of_birth': '',
            'age': 0,
            'gender': '',
            'screen_time_limit': 2.0,
            'created_at':
                firebaseUser.metadata.creationTime?.toIso8601String() ?? '',
            'last_login': DateTime.now().toIso8601String(),
          };
          userSource = 'Firebase';
          isLoading = false;
        });
      }
    } catch (e) {
      print('Auto-migration failed: $e');
      // Even if migration fails, show basic Firebase user data
      setState(() {
        userData = {
          'full_name': firebaseUser.displayName ?? 'User',
          'email': firebaseUser.email ?? '',
          'uid': firebaseUser.uid,
          'phone_number': '',
          'date_of_birth': '',
          'age': 0,
          'gender': '',
          'screen_time_limit': 2.0,
          'created_at':
              firebaseUser.metadata.creationTime?.toIso8601String() ?? '',
          'last_login': DateTime.now().toIso8601String(),
        };
        userSource = 'Firebase';
        isLoading = false;
      });
    }
  }

  Future<void> _saveToFirestore(
    User firebaseUser,
    Map<String, dynamic> localUser,
  ) async {
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
          'migratedFromLocal': true,
        }, SetOptions(merge: true));

    await FirebaseFirestore.instance
        .collection('users')
        .doc(firebaseUser.uid)
        .collection('detoxSessions')
        .doc('_initialized')
        .set({'initialized': true, 'timestamp': FieldValue.serverTimestamp()});
  }

  Future<void> _logout() async {
    try {
      // Clear mode selection so user can choose again
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('mode_selected');
      await prefs.remove('selected_mode');

      // Logout from Firebase
      await FirebaseAuth.instance.signOut();

      // Navigate to landing page to show animations and allow mode selection
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LandingPage()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Logout error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        backgroundColor: kBackgroundColor,
        appBar: AppBar(
          backgroundColor: kPrimaryColor,
          title: const Text(
            'My Profile',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (userData == null) {
      return Scaffold(
        backgroundColor: kBackgroundColor,
        appBar: AppBar(
          backgroundColor: kPrimaryColor,
          title: const Text(
            'My Profile',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.person_off, size: 80, color: Colors.grey),
              const SizedBox(height: 16),
              const Text(
                'No user logged in',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const LoginPage()),
                  );
                },
                style: ElevatedButton.styleFrom(backgroundColor: kPrimaryColor),
                child: const Text(
                  'Login',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        backgroundColor: kPrimaryColor,
        title: const Text(
          'My Profile',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        leading: const BackButton(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: _logout,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Profile Header Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      kPrimaryColor,
                      kPrimaryColor.withValues(alpha: 0.7),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: kPrimaryColor.withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.white,
                      child: Text(
                        userData!['full_name']?.isNotEmpty == true
                            ? userData!['full_name'][0].toUpperCase()
                            : userData!['email']?.isNotEmpty == true
                            ? userData!['email'][0].toUpperCase()
                            : '?',
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: kPrimaryColor,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      userData!['full_name'] ?? userData!['email'] ?? 'User',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Welcome to Digital Detox',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Account Status Card
              _infoCard('Account Status', [
                _infoRow('Status', 'Active'),
                _infoRow(
                  'Member Since',
                  _formatDate(userData!['created_at'] ?? ''),
                ),
              ]),
              const SizedBox(height: 16),

              // Data Storage Info Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.cloud_done, color: Colors.green[700], size: 32),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '🔒 Secure Cloud Storage',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.green[900],
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Your personal information is securely stored in our database and is not displayed here for your privacy.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.green[800],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Logout Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _logout,
                  icon: const Icon(Icons.logout, color: Colors.white),
                  label: const Text(
                    'Logout',
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoCard(String title, List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: kCardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black87,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String dateString) {
    if (dateString.isEmpty) return 'Not available';

    try {
      DateTime date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateString;
    }
  }
}
