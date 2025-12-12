import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'parent_pin_service.dart';
import 'kids_alarm_service.dart';

class KidsOverlayService {
  static final KidsOverlayService _instance = KidsOverlayService._internal();
  factory KidsOverlayService() => _instance;
  KidsOverlayService._internal();

  bool _isOverlayActive = false;
  bool get isActive => _isOverlayActive;

  Future<bool> hasOverlayPermission() async {
    try {
      return await FlutterOverlayWindow.isPermissionGranted();
    } catch (e) {
      return false;
    }
  }

  Future<bool> requestOverlayPermission() async {
    try {
      if (await FlutterOverlayWindow.isPermissionGranted()) return true;
      return await FlutterOverlayWindow.requestPermission() ?? false;
    } catch (e) {
      return false;
    }
  }

  Future<void> showBlockingOverlay({bool shouldPlayAlarm = false}) async {
    if (_isOverlayActive) return;
    try {
      final hasPermission = await hasOverlayPermission().timeout(
        Duration(seconds: 2),
        onTimeout: () => false,
      );
      if (!hasPermission && !await requestOverlayPermission()) return;

      // Send alarm flag to overlay isolate using shareData
      // This is the correct way to communicate between isolates
      print('🔔 Sending alarm flag to overlay: $shouldPlayAlarm');
      await FlutterOverlayWindow.shareData({'shouldPlayAlarm': shouldPlayAlarm});

      await FlutterOverlayWindow.showOverlay(
        enableDrag: false,
        overlayTitle: "Screen Time Over",
        overlayContent: "Time's up! Ask parent to unlock.",
        flag: OverlayFlag.focusPointer,
        visibility: NotificationVisibility.visibilityPublic,
        height: WindowSize.matchParent,
        width: WindowSize.matchParent,
      );
      _isOverlayActive = true;
    } catch (e) {
      print('❌ Error showing overlay: $e');
    }
  }

  Future<void> closeOverlay() async {
    if (!_isOverlayActive) return;
    try {
      await FlutterOverlayWindow.closeOverlay();
      _isOverlayActive = false;
    } catch (_) {}
  }
}

/// Overlay entry point - This runs in a separate isolate
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

/// The actual blocking screen shown as system overlay
class KidsOverlayBlockingScreen extends StatefulWidget {
  const KidsOverlayBlockingScreen({super.key});

  @override
  State<KidsOverlayBlockingScreen> createState() =>
      _KidsOverlayBlockingScreenState();
}

class _KidsOverlayBlockingScreenState extends State<KidsOverlayBlockingScreen>
    with TickerProviderStateMixin {
  final _pinService = ParentPinService();
  final _pinController = TextEditingController();
  bool _pinError = false, _alarmPlaying = true;
  late AnimationController _pulseController, _flashController;
  StreamSubscription? _overlayListener;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: Duration(seconds: 2),
    )..repeat(reverse: true);
    _flashController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 300),
    )..repeat(reverse: true);
    
    // Listen for data from main app isolate
    _overlayListener = FlutterOverlayWindow.overlayListener.listen((data) {
      print('🔔 Overlay received data: $data');
      if (data is Map && data.containsKey('shouldPlayAlarm')) {
        final shouldPlayAlarm = data['shouldPlayAlarm'] as bool;
        print('🔔 Should play alarm: $shouldPlayAlarm');
        
        if (shouldPlayAlarm && mounted) {
          // Play alarm only on fresh timer expiry
          print('🔊 Starting alarm...');
          KidsAlarmService().playAlarm();
        } else {
          // Don't play alarm, skip to PIN entry screen
          print('🔇 Skipping alarm, going to PIN entry');
          if (mounted) {
            setState(() => _alarmPlaying = false);
          }
        }
      }
    });
    
    Future.delayed(Duration(seconds: 8), () {
      if (mounted) {
        _flashController.duration = Duration(milliseconds: 800);
        setState(() => _alarmPlaying = false);
        // Stop alarm after 8 seconds
        KidsAlarmService().stopAlarm();
      }
    });
  }


  @override
  void dispose() {
    _overlayListener?.cancel();
    _pulseController.dispose();
    _flashController.dispose();
    _pinController.dispose();
    // Stop alarm when overlay is disposed
    KidsAlarmService().stopAlarm();
    super.dispose();
  }

  Future<void> _verifyPin() async {
    final pin = _pinController.text;
    if (pin.length != 4) {
      setState(() => _pinError = true);
      return;
    }
    setState(() => _pinError = false);
    try {
      print('🔐 Verifying PIN in overlay...');
      if (await _pinService.verifyPin(pin, isOverlay: true)) {
        print('✅ PIN verified! Stopping Kids Mode...');

        // Stop alarm
        await KidsAlarmService().stopAlarm();

        // Signal main app to stop Kids Mode
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('kids_mode_unlocked', true);
        await prefs.setBool('kids_mode_active', false);
        await prefs.remove('kids_mode_remaining_seconds');
        await prefs.remove('kids_mode_expiry_time');
        print('✅ Kids Mode state cleared');

        // Close overlay
        await FlutterOverlayWindow.closeOverlay();
        print('✅ Overlay closed successfully');
      } else {
        print('❌ PIN verification failed');
        setState(() => _pinError = true);
        _pinController.clear();
        Future.delayed(
          Duration(seconds: 2),
          () => mounted ? setState(() => _pinError = false) : null,
        );
      }
    } catch (e) {
      print('❌ Error during PIN verification: $e');
      setState(() => _pinError = true);
      _pinController.clear();
    }
  }

  Future<void> _addExtraTime() async {
    final pin = _pinController.text;
    if (pin.length != 4) {
      setState(() => _pinError = true);
      return;
    }
    setState(() => _pinError = false);
    try {
      print('🔐 Verifying PIN for add time...');
      if (await _pinService.verifyPin(pin, isOverlay: true)) {
        print('✅ PIN verified! Adding 15 minutes and closing overlay...');
        // Stop alarm
        await KidsAlarmService().stopAlarm();
        // TODO: Add time functionality - for now just close overlay
        await FlutterOverlayWindow.closeOverlay();
        print('✅ Overlay closed successfully');
      } else {
        setState(() => _pinError = true);
        _pinController.clear();
        Future.delayed(
          Duration(seconds: 2),
          () => mounted ? setState(() => _pinError = false) : null,
        );
      }
    } catch (e) {
      setState(() => _pinError = true);
      _pinController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: AnimatedBuilder(
        animation: _flashController,
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.red.shade900.withValues(
                    alpha: 0.85 + (_flashController.value * 0.15),
                  ),
                  Colors.red.shade700.withValues(
                    alpha: 0.85 + (_flashController.value * 0.15),
                  ),
                  Colors.red.shade900.withValues(
                    alpha: 0.85 + (_flashController.value * 0.15),
                  ),
                ],
              ),
            ),
            child: SafeArea(
              child: Center(
                child: _alarmPlaying
                    ? _buildAlarmScreen()
                    : _buildPinEntryScreen(),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAlarmScreen() => Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      ScaleTransition(
        scale: Tween(begin: 1.0, end: 1.2).animate(_pulseController),
        child: Icon(Icons.alarm, size: 120, color: Colors.white),
      ),
      SizedBox(height: 40),
      Text(
        '⏰ SCREEN TIME IS OVER!',
        style: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          letterSpacing: 2,
        ),
        textAlign: TextAlign.center,
      ),
      SizedBox(height: 20),
      Text(
        'Time to take a break!',
        style: TextStyle(fontSize: 24, color: Colors.white70),
        textAlign: TextAlign.center,
      ),
      SizedBox(height: 40),
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.volume_up, color: Colors.white, size: 32),
          SizedBox(width: 10),
          Text(
            'ALARM PLAYING',
            style: TextStyle(
              fontSize: 20,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    ],
  );

  Widget _buildPinEntryScreen() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.lock_outline, size: 80, color: Colors.white),

          SizedBox(height: 30),

          Text(
            '🔒 Phone Locked',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),

          SizedBox(height: 15),

          Text(
            'Screen time is over.\nAsk a parent to unlock.',
            style: TextStyle(fontSize: 18, color: Colors.white70),
            textAlign: TextAlign.center,
          ),

          SizedBox(height: 50),

          Text(
            'Enter Parent PIN',
            style: TextStyle(
              fontSize: 20,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),

          SizedBox(height: 20),

          SizedBox(
            width: 200,
            child: TextField(
              controller: _pinController,
              keyboardType: TextInputType.number,
              maxLength: 4,
              obscureText: true,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 32,
                letterSpacing: 20,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
              decoration: InputDecoration(
                counterText: '',
                filled: true,
                fillColor: _pinError ? Colors.red.shade800 : Colors.white24,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide.none,
                ),
                hintText: '••••',
                hintStyle: TextStyle(color: Colors.white38),
              ),
              onChanged: (value) {
                if (value.length == 4) {
                  _verifyPin();
                }
              },
            ),
          ),

          if (_pinError) ...[
            SizedBox(height: 10),
            Text(
              '❌ Incorrect PIN',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],

          SizedBox(height: 40),

          Column(
            children: [
              ElevatedButton.icon(
                onPressed: _verifyPin,
                icon: Icon(Icons.lock_open),
                label: Text('UNLOCK PHONE'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.red.shade900,
                  padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  elevation: 5,
                ),
              ),

              SizedBox(height: 15),

              OutlinedButton.icon(
                onPressed: _addExtraTime,
                icon: Icon(Icons.add_alarm),
                label: Text('ADD 15 MINUTES'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: BorderSide(color: Colors.white, width: 2),
                  padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
