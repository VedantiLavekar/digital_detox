import 'package:flutter/material.dart';
// import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Entry point for the system overlay window
@pragma("vm:entry-point")
void overlayMain() {
  runApp(const OverlayApp());
}

class OverlayApp extends StatelessWidget {
  const OverlayApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: BlockingOverlayScreen(),
    );
  }
}

class BlockingOverlayScreen extends StatefulWidget {
  const BlockingOverlayScreen({super.key});

  @override
  State<BlockingOverlayScreen> createState() => _BlockingOverlayScreenState();
}

class _BlockingOverlayScreenState extends State<BlockingOverlayScreen> {
  String appName = '';
  int usageMinutes = 0;
  int limitMinutes = 0;

  @override
  void initState() {
    super.initState();
    _loadBlockedAppData();
  }

  Future<void> _loadBlockedAppData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      appName = prefs.getString('blocked_app_name') ?? 'App';
      usageMinutes = prefs.getInt('blocked_app_usage') ?? 0;
      limitMinutes = prefs.getInt('blocked_app_limit') ?? 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.red.shade900,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Blocked icon
              const Icon(Icons.block, size: 120, color: Colors.white),
              const SizedBox(height: 32),

              // App name
              Text(
                '🚫 $appName Blocked',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),

              // Message
              const Text(
                'You\'ve reached your daily screen time limit!',
                style: TextStyle(fontSize: 18, color: Colors.white70),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),

              // Usage info
              Container(
                margin: const EdgeInsets.symmetric(vertical: 24),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    const Text(
                      'Time Used Today',
                      style: TextStyle(fontSize: 14, color: Colors.white60),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '$usageMinutes minutes',
                      style: const TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Limit: $limitMinutes minutes',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white60,
                      ),
                    ),
                  ],
                ),
              ),

              // Motivational message
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white10,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  '💪 Time for a digital detox!\n\nTry some offline activities:\n• Read a book\n• Take a walk\n• Call a friend\n• Practice meditation',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 32),

              // Close button
              ElevatedButton(
                onPressed: () async {
                  // await FlutterOverlayWindow.closeOverlay();
                  Navigator.of(context).pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.red.shade900,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 48,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: const Text(
                  'I Understand',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'This app will remain blocked until tomorrow',
                style: TextStyle(fontSize: 12, color: Colors.white54),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
