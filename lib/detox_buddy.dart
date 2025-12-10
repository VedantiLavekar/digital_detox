import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:share_plus/share_plus.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'dart:math';
import 'dart:async';
import 'detox_buddy_service.dart';
import 'database_helper.dart';
import 'detox_buddy_activity_service.dart';
import 'activity_enhancements.dart';

const Color kPrimaryColor = Color(0xFF2E9D8A);
const Color kBackgroundColor = Color(0xFFF5F5DC);

class DetoxBuddyPage extends StatefulWidget {
  const DetoxBuddyPage({super.key});

  @override
  State<DetoxBuddyPage> createState() => _DetoxBuddyPageState();
}

class _DetoxBuddyPageState extends State<DetoxBuddyPage>
    with SingleTickerProviderStateMixin {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  late TabController _tabController;
  String? currentUserId;
  Map<String, dynamic>? currentUserData;
  List<Map<String, dynamic>> buddyRequests = [];
  List<Map<String, dynamic>> myBuddies = [];
  bool isLoading = true;

  // Stream subscriptions for real-time updates
  Stream<List<Map<String, dynamic>>>? requestsStream;
  Stream<List<Map<String, dynamic>>>? buddiesStream;
  Stream<List<DetoxBuddyActivity>>? activitiesStream;

  // Activity timer variables
  Timer? _activityTimer;
  DetoxBuddyActivity? _currentActivity;
  int _remainingSeconds = 0;
  bool _isTimerRunning = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);

    // Initialize empty streams immediately to prevent errors
    requestsStream = Stream.value([]);
    buddiesStream = Stream.value([]);

    // Listen to auth state changes for real-time updates
    _auth.authStateChanges().listen((user) {
      if (mounted) {
        final newUserId = user?.uid;
        if (newUserId != currentUserId) {
          setState(() {
            currentUserId = newUserId;
            isLoading = newUserId != null;
          });
          if (newUserId != null) {
            _initializeUser();
          }
        }
      }
    });

    _initializeUser();
  }

  Future<void> _initializeUser() async {
    try {
      // Wait for Firebase Auth to initialize with multiple attempts
      for (int i = 0; i < 5; i++) {
        await Future.delayed(const Duration(milliseconds: 300));
        currentUserId = _auth.currentUser?.uid;
        if (currentUserId != null) break;
      }

      // If Firebase Auth failed, try to authenticate with Firebase using local DB data
      if (currentUserId == null) {
        final dbHelper = DatabaseHelper();
        final localUser = await dbHelper.getCurrentUser();

        if (localUser != null && localUser['email'] != null) {
          // User is logged in locally, try to authenticate with Firebase
          // Generate a temporary user ID for local users
          currentUserId =
              'local_${localUser['email'].toString().hashCode.abs()}';

          if (mounted) {
            _showMessage('Using local authentication: ${localUser['email']}');
          }
        }
      } else {
        // Debug: Show Firebase auth state
        if (mounted) {
          final authUser = _auth.currentUser;
          _showMessage(
            'Firebase Auth Success: ${authUser?.email ?? "No email"}',
          );
        }
      }

      if (currentUserId != null) {
        // Test database connectivity
        final connectionOk = await DetoxBuddyService.testConnection();
        if (!connectionOk && mounted) {
          _showMessage(
            'Database connection issue. Please check your internet connection.',
            isError: true,
          );
        }

        await _loadUserData();
        // Initialize Firebase collections
        await DetoxBuddyService.initializeCollections();
        // Now setup real streams after user is authenticated
        _setupStreams();
      } else {
        if (mounted) {
          _showMessage(
            'No authentication found (Firebase or Local)',
            isError: true,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        _showMessage('Initialization error: ${e.toString()}', isError: true);
      }
    }

    if (mounted) {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _setupStreams() {
    if (currentUserId != null) {
      requestsStream = DetoxBuddyService.getBuddyRequests(
        currentUserId,
      ).asBroadcastStream();
      buddiesStream = DetoxBuddyService.getMyBuddies(
        currentUserId,
      ).asBroadcastStream();
      activitiesStream = DetoxBuddyActivityService.getUserActivities(
        currentUserId,
      ).asBroadcastStream();
    } else {
      requestsStream = Stream.value(
        <Map<String, dynamic>>[],
      ).asBroadcastStream();
      buddiesStream = Stream.value(
        <Map<String, dynamic>>[],
      ).asBroadcastStream();
      activitiesStream = Stream.value(
        <DetoxBuddyActivity>[],
      ).asBroadcastStream();
    }
  }

  Future<void> _loadUserData() async {
    try {
      // Handle local users differently
      if (currentUserId != null && currentUserId!.startsWith('local_')) {
        // Load from local database
        final dbHelper = DatabaseHelper();
        final localUser = await dbHelper.getCurrentUser();
        if (localUser != null) {
          currentUserData = {
            'fullName':
                localUser['fullName'] ?? localUser['name'] ?? 'Local User',
            'email': localUser['email'] ?? 'local@user.com',
            'isLocal': true,
          };
        }
        return;
      }

      // Handle Firebase users
      final doc = await _firestore.collection('users').doc(currentUserId).get();
      if (doc.exists) {
        currentUserData = doc.data();
      }
    } catch (e) {
      // Debug: Error loading user data
      currentUserData = {'fullName': 'User', 'email': '', 'error': true};
    }
  }

  // Refresh methods for manual reload
  Future<void> _refreshRequests() async {
    // Trigger a refresh by calling setState - streams will handle the data
    setState(() {});
  }

  Future<void> _refreshBuddies() async {
    // Trigger a refresh by calling setState - streams will handle the data
    setState(() {});
  }

  // Load methods are now replaced with real-time streams
  void _loadBuddyRequests() => _refreshRequests();
  void _loadMyBuddies() => _refreshBuddies();

  // Generate unique buddy code
  String _generateBuddyCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    Random random = Random();
    return List.generate(
      6,
      (index) => chars[random.nextInt(chars.length)],
    ).join();
  }

  // Send buddy request by email
  Future<void> _sendBuddyRequestByEmail(String email) async {
    if (email.trim().isEmpty) {
      _showMessage('Please enter an email address.', isError: true);
      return;
    }

    if (!email.contains('@') || !email.contains('.')) {
      _showMessage('Please enter a valid email address.', isError: true);
      return;
    }

    // Show loading
    _showMessage('Sending buddy request...');

    final senderName = currentUserData?['fullName'] ?? 'Unknown User';

    final senderEmail = currentUserData?['email'];

    final result = await DetoxBuddyService.sendBuddyRequest(
      receiverEmail: email,
      senderName: senderName,
      senderId: currentUserId!,
      senderEmail: senderEmail,
    );

    if (result == 'success') {
      _showMessage('Buddy request sent successfully! 🎉');
    } else if (result == 'user_not_found') {
      _showMessage(
        'User not found. Ensure they have signed up with this email in the Digital Detox app.',
        isError: true,
      );
    } else if (result == 'already_connected') {
      _showMessage(
        'You are already connected or have a pending request.',
        isError: true,
      );
    } else if (result == 'self_request') {
      _showMessage('You cannot invite yourself 😅', isError: true);
    } else if (result == 'network_error') {
      _showMessage(
        'Network error. Please check your internet connection and try again.',
        isError: true,
      );
    } else if (result == 'permission_denied') {
      _showMessage(
        'Permission denied. Please make sure you are logged in correctly.',
        isError: true,
      );
    } else if (result.startsWith('error:')) {
      _showMessage(
        'System error: ${result.replaceAll('error: ', '')}',
        isError: true,
      );
    } else {
      _showMessage(
        'Unable to send buddy request. Please try again later. ($result)',
        isError: true,
      );
    }
  }

  // Accept buddy request
  Future<void> _acceptBuddyRequest(String requestId, String senderId) async {
    final success = await DetoxBuddyService.acceptBuddyRequest(
      requestId,
      senderId,
    );

    if (success) {
      _showMessage('Buddy request accepted! You are now detox buddies!');
      _loadBuddyRequests();
      _loadMyBuddies();
    } else {
      _showMessage('Error accepting buddy request.', isError: true);
    }
  }

  // Reject buddy request
  Future<void> _rejectBuddyRequest(String requestId) async {
    try {
      await _firestore.collection('buddy_requests').doc(requestId).update({
        'status': 'rejected',
        'respondedAt': FieldValue.serverTimestamp(),
      });

      _showMessage('Buddy request rejected.');
      _loadBuddyRequests();
    } catch (e) {
      _showMessage('Error rejecting buddy request.', isError: true);
    }
  }

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : kPrimaryColor,
        duration: Duration(seconds: isError ? 3 : 2),
      ),
    );
  }

  // Test database operations for debugging
  Future<void> _testDatabaseOperations() async {
    try {
      _showMessage('Testing database connection...');

      // Test 1: Check connection
      final connectionOk = await DetoxBuddyService.testConnection();
      if (!connectionOk) {
        _showMessage('Database connection failed!', isError: true);
        return;
      }

      // Test 2: Check user profile
      final userDoc = await _firestore
          .collection('users')
          .doc(currentUserId)
          .get();
      if (!userDoc.exists) {
        _showMessage('User profile not found. Creating...', isError: true);
        await DetoxBuddyService.initializeCollections();
      }

      // Test 3: Test collections access
      await _firestore.collection('buddy_requests').limit(1).get();
      await _firestore.collection('buddy_connections').limit(1).get();

      _showMessage('Database test completed successfully! ✅');
    } catch (e) {
      _showMessage('Database test failed: ${e.toString()}', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        backgroundColor: kBackgroundColor,
        appBar: AppBar(
          title: const Text(
            'Detox Buddy',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          backgroundColor: kPrimaryColor,
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    // Check if user is authenticated after initialization
    if (!isLoading && currentUserId == null) {
      final authUser = _auth.currentUser;
      return Scaffold(
        backgroundColor: kBackgroundColor,
        appBar: AppBar(
          title: const Text(
            'Detox Buddy',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          backgroundColor: kPrimaryColor,
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock_outline, size: 80, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                authUser != null
                    ? 'Authentication issue detected'
                    : 'Please login to access Detox Buddy',
                style: TextStyle(fontSize: 18, color: Colors.grey[600]),
              ),
              if (authUser != null) ...[
                const SizedBox(height: 8),
                Text(
                  'User: ${authUser.email ?? "Unknown"}\nUID: ${authUser.uid}',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                ),
              ],
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () async {
                  setState(() {
                    isLoading = true;
                  });
                  await _initializeUser();
                },
                icon: const Icon(Icons.refresh, color: Colors.white),
                label: const Text(
                  'Retry',
                  style: TextStyle(color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
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
        title: const Text(
          'Detox Buddy',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: kPrimaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.person_add), text: 'Find Buddy'),
            Tab(icon: Icon(Icons.notifications), text: 'Requests'),
            Tab(icon: Icon(Icons.group), text: 'My Buddies'),
            Tab(icon: Icon(Icons.fitness_center), text: 'Activities'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildFindBuddyTab(),
          _buildRequestsTab(),
          _buildMyBuddiesTab(),
          _buildActivitiesTab(),
        ],
      ),
      floatingActionButton: currentUserId != null
          ? FloatingActionButton(
              onPressed: () => _testDatabaseOperations(),
              backgroundColor: kPrimaryColor,
              child: const Icon(Icons.bug_report, color: Colors.white),
            )
          : null,
    );
  }

  Widget _buildFindBuddyTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Local user info banner
          if (currentUserId != null && currentUserId!.startsWith('local_'))
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                border: Border.all(color: Colors.amber.shade200),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.amber.shade700),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'You are using local authentication. To use full Detox Buddy features, please sign up with Firebase authentication.',
                      style: TextStyle(
                        color: Colors.amber.shade800,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          // Welcome Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [kPrimaryColor, kPrimaryColor.withValues(alpha: 0.8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Column(
              children: [
                const Icon(Icons.group_add, size: 60, color: Colors.white),
                const SizedBox(height: 16),
                const Text(
                  'Find Your Detox Buddy!',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Connect with friends or family to support each other in your digital detox journey.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Invite by Email
          _buildInviteByEmailCard(),

          const SizedBox(height: 16),

          // Share QR Code
          _buildQRCodeCard(),

          const SizedBox(height: 16),

          // How it works
          _buildHowItWorksCard(),
        ],
      ),
    );
  }

  Widget _buildInviteByEmailCard() {
    final TextEditingController emailController = TextEditingController();

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.email, color: kPrimaryColor),
                const SizedBox(width: 8),
                const Text(
                  'Invite by Email',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: emailController,
              decoration: InputDecoration(
                labelText: 'Enter friend\'s email address',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                prefixIcon: const Icon(Icons.person),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: (currentUserId != null && currentUserId!.startsWith('local_'))
                    ? null // Disable for local users
                    : () {
                        if (emailController.text.trim().isNotEmpty) {
                          _sendBuddyRequestByEmail(emailController.text.trim());
                          emailController.clear();
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  (currentUserId != null && currentUserId!.startsWith('local_'))
                      ? 'Login Required to Invite'
                      : 'Send Buddy Request',
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQRCodeCard() {
    final buddyCode = _generateBuddyCode();

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.qr_code, color: kPrimaryColor),
                const SizedBox(width: 8),
                const Text(
                  'Share QR Code',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: kPrimaryColor.withValues(alpha: 0.3)),
              ),
              child: QrImageView(
                data: 'detox_buddy:$currentUserId:$buddyCode',
                version: QrVersions.auto,
                size: 200.0,
                eyeStyle: QrEyeStyle(
                  eyeShape: QrEyeShape.square,
                  color: kPrimaryColor,
                ),
                dataModuleStyle: QrDataModuleStyle(
                  dataModuleShape: QrDataModuleShape.square,
                  color: kPrimaryColor,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Buddy Code: $buddyCode',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: kPrimaryColor,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                Share.share(
                  'Join me as my Detox Buddy! Use code: $buddyCode or scan the QR code to connect. Download Digital Detox app and let\'s support each other in reducing screen time!',
                );
              },
              icon: const Icon(Icons.share, color: Colors.white),
              label: const Text(
                'Share Invitation',
                style: TextStyle(color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHowItWorksCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, color: kPrimaryColor),
                const SizedBox(width: 8),
                const Text(
                  'How Detox Buddy Works',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildHowItWorksItem(
              Icons.person_add,
              'Send Invitation',
              'Invite friends/family by email or share your QR code',
            ),
            _buildHowItWorksItem(
              Icons.handshake,
              'Connect Together',
              'Once they accept, you become detox buddies',
            ),
            _buildHowItWorksItem(
              Icons.track_changes,
              'Shared Activities',
              'Track meditation, mood, and screen time together',
            ),
            _buildHowItWorksItem(
              Icons.emoji_events,
              'Motivate Each Other',
              'Send encouragements, share achievements & compete',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHowItWorksItem(IconData icon, String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: kPrimaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(icon, color: kPrimaryColor, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Text(
                  description,
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestsTab() {
    if (requestsStream == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: requestsStream!,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.notifications_none,
                  size: 80,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'No buddy requests',
                  style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                ),
                const SizedBox(height: 8),
                Text(
                  'When someone sends you a buddy request,\nit will appear here.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey[500]),
                ),
              ],
            ),
          );
        }

        final requests = snapshot.data!;
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: requests.length,
          itemBuilder: (context, index) {
            final request = requests[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: kPrimaryColor,
                          child: Text(
                            (request['senderName'] ?? '?')[0].toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                request['senderName'] ?? 'Unknown',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                request['senderEmail'] ?? '',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Wants to be your detox buddy!',
                      style: TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => _acceptBuddyRequest(
                              request['id'],
                              request['senderId'],
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: kPrimaryColor,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text(
                              'Accept',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => _rejectBuddyRequest(request['id']),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: Colors.grey[400]!),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text(
                              'Decline',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildMyBuddiesTab() {
    if (buddiesStream == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: buddiesStream!,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.group_outlined, size: 80, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'No detox buddies yet',
                  style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                ),
                const SizedBox(height: 8),
                Text(
                  'Start by inviting friends or family\nto become your detox buddy!',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey[500]),
                ),
              ],
            ),
          );
        }

        final buddies = snapshot.data!;
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: buddies.length,
          itemBuilder: (context, index) {
            final buddy = buddies[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: kPrimaryColor,
                          radius: 30,
                          child: Text(
                            (buddy['buddyName'] ?? '?')[0].toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 24,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                buddy['buddyName'] ?? 'Unknown',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                              Text(
                                buddy['buddyEmail'] ?? '',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.whatshot,
                                    size: 16,
                                    color: Colors.orange,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Streak: ${buddy['streakCount'] ?? 0} days',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.keyboard_arrow_right,
                          color: Colors.grey[400],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildBuddyActionButton(
                            Icons.mood,
                            'Share Mood',
                            () => _shareMoodWithBuddy(buddy),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildBuddyActionButton(
                            Icons.self_improvement,
                            'Meditate Together',
                            () => _meditateWithBuddy(buddy),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildBuddyActionButton(
                            Icons.chat,
                            'Send Message',
                            () => _sendMessageToBuddy(buddy),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildBuddyActionButton(
    IconData icon,
    String label,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: kPrimaryColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: kPrimaryColor.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: kPrimaryColor, size: 20),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: kPrimaryColor,
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _shareMoodWithBuddy(Map<String, dynamic> buddy) {
    // Implementation for sharing mood with buddy
    _showMessage('Mood sharing feature coming soon!');
  }

  void _meditateWithBuddy(Map<String, dynamic> buddy) {
    // Implementation for meditating with buddy
    _showMessage('Buddy meditation sessions coming soon!');
  }

  void _sendMessageToBuddy(Map<String, dynamic> buddy) {
    // Implementation for sending messages to buddy
    _showMessage('Buddy messaging feature coming soon!');
  }

  Widget _buildActivitiesTab() {
    // Local user info banner
    if (currentUserId != null && currentUserId!.startsWith('local_')) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                border: Border.all(color: Colors.amber.shade200),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Colors.amber.shade700,
                    size: 30,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Activities feature requires Firebase authentication for buddy synchronization. Try our solo activities below!',
                      style: TextStyle(
                        color: Colors.amber.shade800,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Show solo activities for local users
            _buildSoloActivityTemplates(),
          ],
        ),
      );
    }

    return activitiesStream == null
        ? const Center(child: CircularProgressIndicator())
        : StreamBuilder<List<DetoxBuddyActivity>>(
            stream: activitiesStream!,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final activities = snapshot.data ?? [];

              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Active Activity Timer (if any)
                    if (_currentActivity != null && _isTimerRunning)
                      _buildActiveActivityTimer(),

                    // Create New Activity Button
                    ElevatedButton.icon(
                      onPressed: _showCreateActivityDialog,
                      icon: const Icon(Icons.add, color: Colors.white),
                      label: const Text(
                        'Create New Activity',
                        style: TextStyle(color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kPrimaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Activity Stats Section
                    _buildActivityStatsSection(),

                    const SizedBox(height: 24),

                    // Activity Templates Section
                    _buildActivityTemplatesSection(),

                    const SizedBox(height: 24),

                    // Recent Activities
                    if (activities.isNotEmpty) ...[
                      Text(
                        'Your Activities',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: kPrimaryColor,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ...activities.map(
                        (activity) => _buildActivityCard(activity),
                      ),
                    ] else
                      _buildEmptyActivitiesState(),
                  ],
                ),
              );
            },
          );
  }

  Widget _buildSoloActivityTemplates() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Solo Activities (No Sync)',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: kPrimaryColor,
          ),
        ),
        const SizedBox(height: 16),
        ...DetoxBuddyActivityService.activityTemplates
            .where((template) => template.defaultMode != ActivityMode.together)
            .take(6)
            .map((template) => _buildSoloActivityTemplateCard(template)),
      ],
    );
  }

  Widget _buildSoloActivityTemplateCard(ActivityTemplate template) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: kPrimaryColor,
          child: Text(template.icon, style: const TextStyle(fontSize: 20)),
        ),
        title: Text(template.name),
        subtitle: Text(template.description),
        trailing: ElevatedButton(
          onPressed: () => _startSoloActivity(template),
          style: ElevatedButton.styleFrom(
            backgroundColor: kPrimaryColor,
            foregroundColor: Colors.white,
          ),
          child: const Text('Start'),
        ),
      ),
    );
  }

  Widget _buildActiveActivityTimer() {
    final minutes = _remainingSeconds ~/ 60;
    final seconds = _remainingSeconds % 60;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green, Colors.green.shade700],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            _currentActivity!.title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 48,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton.icon(
                onPressed: _pauseActivity,
                icon: Icon(_isTimerRunning ? Icons.pause : Icons.play_arrow),
                label: Text(_isTimerRunning ? 'Pause' : 'Resume'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.green,
                ),
              ),
              ElevatedButton.icon(
                onPressed: _completeCurrentActivity,
                icon: const Icon(Icons.check),
                label: const Text('Complete'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.green,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActivityStatsSection() {
    // Simulated stats for demo - in production this would come from database
    final totalActivities = DateTime.now().day % 15 + 5; // 5-20 activities
    final streakDays = DateTime.now().day % 7 + 1; // 1-7 days
    final favoriteActivity =
        DetoxBuddyActivityService.activityTemplates[DateTime.now().millisecond %
            DetoxBuddyActivityService.activityTemplates.length];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [kPrimaryColor.withOpacity(0.8), kPrimaryColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: kPrimaryColor.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '📊 Your Activity Stats',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  title: 'Total Activities',
                  value: totalActivities.toString(),
                  icon: Icons.fitness_center,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  title: 'Current Streak',
                  value: '$streakDays days',
                  icon: Icons.local_fire_department,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Text(
                  favoriteActivity.icon,
                  style: const TextStyle(fontSize: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Favorite Activity',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                      Text(
                        favoriteActivity.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${(totalActivities * 0.3).round()}x',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            title,
            style: TextStyle(color: color.withOpacity(0.8), fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildActivityTemplatesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Popular Activities',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: kPrimaryColor,
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 200,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: DetoxBuddyActivityService.activityTemplates.length,
            itemBuilder: (context, index) {
              final template =
                  DetoxBuddyActivityService.activityTemplates[index];
              return _buildActivityTemplateCard(template);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildActivityTemplateCard(ActivityTemplate template) {
    return Container(
      width: 200,
      margin: const EdgeInsets.only(right: 16),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(template.icon, style: const TextStyle(fontSize: 30)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      template.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                template.description,
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 4,
                children: template.suggestedDurations.take(3).map((duration) {
                  return Chip(
                    label: Text('${duration}min'),
                    labelStyle: const TextStyle(fontSize: 10),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  );
                }).toList(),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _createActivityFromTemplate(template),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimaryColor,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Use'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActivityCard(DetoxBuddyActivity activity) {
    final isActive = activity.status == ActivityStatus.active;
    final isPending = activity.status == ActivityStatus.pending;
    final isCompleted = activity.status == ActivityStatus.completed;

    Color statusColor = Colors.grey;
    IconData statusIcon = Icons.schedule;
    String statusText = 'Scheduled';

    if (isActive) {
      statusColor = Colors.orange;
      statusIcon = Icons.play_circle_filled;
      statusText = 'Active';
    } else if (isPending) {
      statusColor = Colors.blue;
      statusIcon = Icons.pending;
      statusText = 'Pending';
    } else if (isCompleted) {
      statusColor = Colors.green;
      statusIcon = Icons.check_circle;
      statusText = 'Completed';
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: statusColor,
          child: Icon(statusIcon, color: Colors.white),
        ),
        title: Text(activity.title),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${activity.durationMinutes} minutes • ${activity.mode.name}'),
            Text(
              statusText,
              style: TextStyle(color: statusColor, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(activity.description),
                const SizedBox(height: 12),
                if (activity.locationNote != null) ...[
                  Row(
                    children: [
                      const Icon(Icons.location_on, size: 16),
                      const SizedBox(width: 4),
                      Text(activity.locationNote!),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
                Text(
                  'Participants: ${activity.participants.length}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                if (isPending)
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => _acceptActivity(activity),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                          ),
                          child: const Text(
                            'Accept',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => _declineActivity(activity),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                          ),
                          child: const Text(
                            'Decline',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                if (activity.status == ActivityStatus.accepted)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => _startActivity(activity),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kPrimaryColor,
                      ),
                      child: const Text(
                        'Start Activity',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyActivitiesState() {
    return Center(
      child: Column(
        children: [
          Icon(Icons.fitness_center, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No activities yet!',
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'Create your first activity with a buddy',
            style: TextStyle(color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  // Activity Management Methods
  void _showCreateActivityDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: Container(
          constraints: const BoxConstraints(maxHeight: 600),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppBar(
                title: const Text('Create Activity'),
                backgroundColor: kPrimaryColor,
                foregroundColor: Colors.white,
                automaticallyImplyLeading: false,
                actions: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              Flexible(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Text(
                        'Choose an activity template:',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: ListView.builder(
                          itemCount: DetoxBuddyActivityService
                              .activityTemplates
                              .length,
                          itemBuilder: (context, index) {
                            final template = DetoxBuddyActivityService
                                .activityTemplates[index];
                            return ListTile(
                              leading: Text(
                                template.icon,
                                style: const TextStyle(fontSize: 24),
                              ),
                              title: Text(template.name),
                              subtitle: Text(template.description),
                              onTap: () {
                                Navigator.of(context).pop();
                                _createActivityFromTemplate(template);
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _createActivityFromTemplate(ActivityTemplate template) {
    _showMessage('Activity creation with ${template.name} - Coming Soon! 🚀');
  }

  void _startSoloActivity(ActivityTemplate template) {
    // For local users, start a simple timer
    showDialog(
      context: context,
      builder: (context) {
        int selectedDuration = template.suggestedDurations.first;
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('${template.icon} ${template.name}'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(template.description),
                  const SizedBox(height: 16),
                  const Text('Select duration:'),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: template.suggestedDurations.map((duration) {
                      return ChoiceChip(
                        label: Text('${duration}min'),
                        selected: selectedDuration == duration,
                        onSelected: (_) =>
                            setState(() => selectedDuration = duration),
                      );
                    }).toList(),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    _startSoloTimer(template, selectedDuration);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimaryColor,
                  ),
                  child: const Text(
                    'Start',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _startSoloTimer(ActivityTemplate template, int minutes) {
    setState(() {
      _remainingSeconds = minutes * 60;
      _isTimerRunning = true;
      _currentActivity = DetoxBuddyActivity(
        id: 'solo_${DateTime.now().millisecondsSinceEpoch}',
        type: template.type,
        title: template.name,
        description: template.description,
        durationMinutes: minutes,
        mode: ActivityMode.individual,
        status: ActivityStatus.active,
        createdBy: 'local',
        participants: ['local'],
        scheduledTime: DateTime.now(),
      );
    });

    _activityTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_isTimerRunning) return;

      setState(() {
        if (_remainingSeconds > 0) {
          _remainingSeconds--;

          // Show encouragement at halfway point
          if (_remainingSeconds == (minutes * 60) ~/ 2) {
            _showMessage(ActivityMotivation.getEncouragementMessage());
          }
        } else {
          _completeCurrentActivity();
        }
      });
    });

    _showMessage(ActivityMotivation.getStartMessage());
  }

  Future<void> _startActivity(DetoxBuddyActivity activity) async {
    final success = await DetoxBuddyActivityService.startActivity(activity.id);
    if (success) {
      setState(() {
        _currentActivity = activity;
        _remainingSeconds = activity.durationMinutes * 60;
        _isTimerRunning = true;
      });

      _activityTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (!_isTimerRunning) return;

        setState(() {
          if (_remainingSeconds > 0) {
            _remainingSeconds--;
          } else {
            _completeCurrentActivity();
          }
        });
      });

      _showMessage('Activity started! Good luck! 💪');
    } else {
      _showMessage('Failed to start activity', isError: true);
    }
  }

  void _pauseActivity() {
    setState(() {
      _isTimerRunning = !_isTimerRunning;
    });

    if (_isTimerRunning) {
      _showMessage('Activity resumed! ▶️');
    } else {
      _showMessage('Activity paused ⏸️');
    }
  }

  Future<void> _completeCurrentActivity() async {
    _activityTimer?.cancel();

    if (_currentActivity != null) {
      if (_currentActivity!.id.startsWith('solo_')) {
        // Solo activity completion
        _showMessage(
          '🎉 Congratulations! You completed ${_currentActivity!.title}!',
        );
        _showCompletionDialog(_currentActivity!);
      } else {
        // Firebase activity completion
        final success = await DetoxBuddyActivityService.completeActivity(
          _currentActivity!.id,
          note: 'Completed successfully!',
        );

        if (success) {
          _showMessage('🎉 Activity completed! Well done!');
          _showCompletionDialog(_currentActivity!);
        } else {
          _showMessage('Failed to mark activity as complete', isError: true);
        }
      }
    }

    setState(() {
      _currentActivity = null;
      _remainingSeconds = 0;
      _isTimerRunning = false;
    });
  }

  void _showCompletionDialog(DetoxBuddyActivity activity) {
    final template = DetoxBuddyActivityService.getTemplate(activity.type);

    // Check for achievements (simulate activity counts for demo)
    final activityCount =
        DateTime.now().millisecondsSinceEpoch % 10 + 1; // Simulated count

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.green.shade400, Colors.green.shade600],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Success animation
              TweenAnimationBuilder(
                tween: Tween<double>(begin: 0, end: 1),
                duration: const Duration(milliseconds: 600),
                builder: (context, double value, child) {
                  return Transform.scale(
                    scale: value,
                    child: const Icon(
                      Icons.check_circle,
                      color: Colors.white,
                      size: 80,
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              Text(
                ActivityMotivation.getCompletionMessage(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'You completed "${activity.title}" in ${activity.durationMinutes} minutes!',
                style: const TextStyle(color: Colors.white70, fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              if (template != null) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'Benefits Gained:',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...template.benefits
                          .take(3)
                          .map(
                            (benefit) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 2),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.check,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      benefit,
                                      style: const TextStyle(
                                        color: Colors.white70,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();

                  // Show achievement if applicable
                  Future.delayed(const Duration(milliseconds: 500), () {
                    ActivityAchievements.checkAndShowAchievements(
                      context,
                      totalActivities: activityCount,
                      meditationCount:
                          template?.type == ActivityType.meditationCircle
                          ? 1
                          : 0,
                      walkCount: template?.type == ActivityType.walkChat
                          ? 1
                          : 0,
                      phoneDetoxCount:
                          template?.type == ActivityType.phoneDetoxChallenge
                          ? 1
                          : 0,
                    );
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.green.shade600,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 30,
                    vertical: 12,
                  ),
                ),
                child: const Text(
                  'Awesome!',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _acceptActivity(DetoxBuddyActivity activity) async {
    final success = await DetoxBuddyActivityService.acceptActivityInvitation(
      activity.id,
    );
    if (success) {
      _showMessage('Activity accepted! 👍');
    } else {
      _showMessage('Failed to accept activity', isError: true);
    }
  }

  Future<void> _declineActivity(DetoxBuddyActivity activity) async {
    final success = await DetoxBuddyActivityService.declineActivityInvitation(
      activity.id,
    );
    if (success) {
      _showMessage('Activity declined');
    } else {
      _showMessage('Failed to decline activity', isError: true);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _activityTimer?.cancel();
    super.dispose();
  }
}
