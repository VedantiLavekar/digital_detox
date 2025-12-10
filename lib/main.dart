import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'firebase_options.dart';
import 'landing_page.dart';
import 'kids_mode_dashboard.dart';
import 'kids_mode_service.dart';
import 'kids_overlay_service.dart';

@pragma("vm:entry-point")
void overlayMain() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      home: KidsOverlayBlockingScreen(),
    ),
  );
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {}

  await KidsModeService().initialize();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Digital Detox App',
      home: FutureBuilder<bool>(
        future: _checkKidsModeActive(),
        builder: (context, kidsModeSnapshot) {
          // Show loading while checking
          if (kidsModeSnapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(color: Color(0xFF2E9D8A)),
              ),
            );
          }

          // If Kids Mode is active, go directly to Kids Dashboard
          if (kidsModeSnapshot.data == true) {
            return const KidsModeDashboard();
          }

          // Show normal app flow (original landing page with animations)
          // Always start with landing page for non-kids mode
          return const LandingPage();
        },
      ),
    );
  }

  Future<bool> _checkKidsModeActive() async {
    final kidsModeService = KidsModeService();
    return kidsModeService.isActive;
  }
}
