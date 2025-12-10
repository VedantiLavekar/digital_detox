import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'parent_pin_service.dart';
import 'kids_mode_service.dart';
import 'kids_alarm_service.dart';
import 'package:lottie/lottie.dart';

/// Non-dismissible blocking screen shown when Kids Mode timer expires
/// Can only be unlocked with parent PIN
class KidsBlockingScreen extends StatefulWidget {
  const KidsBlockingScreen({Key? key}) : super(key: key);

  @override
  State<KidsBlockingScreen> createState() => _KidsBlockingScreenState();
}

class _KidsBlockingScreenState extends State<KidsBlockingScreen>
    with SingleTickerProviderStateMixin {
  final ParentPinService _pinService = ParentPinService();
  final KidsModeService _kidsModeService = KidsModeService();
  final KidsAlarmService _alarmService = KidsAlarmService();

  final TextEditingController _pinController = TextEditingController();
  bool _showPinEntry = false;
  bool _pinError = false;
  bool _alarmPlaying = true;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: Duration(seconds: 2),
    )..repeat(reverse: true);

    // Don't play alarm - just show visual alert
    // Show PIN entry after 5 seconds
    Future.delayed(Duration(seconds: 5), () {
      if (mounted) {
        setState(() {
          _alarmPlaying = false;
          _showPinEntry = true;
        });
      }
    });

    // Disable system UI (hide navigation bar, status bar)
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _pinController.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  Future<void> _verifyPin() async {
    final pin = _pinController.text;

    if (pin.length != 4) {
      setState(() => _pinError = true);
      return;
    }

    final isValid = await _pinService.verifyPin(pin);

    if (isValid) {
      // PIN correct - stop Kids Mode and exit
      await _kidsModeService.stopKidsMode();
      if (mounted) {
        Navigator.of(context).pop();
      }
    } else {
      // PIN incorrect
      setState(() {
        _pinError = true;
        _pinController.clear();
      });

      // Clear error after 2 seconds
      Future.delayed(Duration(seconds: 2), () {
        if (mounted) {
          setState(() => _pinError = false);
        }
      });
    }
  }

  Future<void> _addExtraTime() async {
    final pin = _pinController.text;

    if (pin.length != 4) {
      setState(() => _pinError = true);
      return;
    }

    final isValid = await _pinService.verifyPin(pin);

    if (isValid) {
      // Add 15 minutes extra time
      await _kidsModeService.addExtraTime(15);
      if (mounted) {
        Navigator.of(context).pop();
      }
    } else {
      setState(() {
        _pinError = true;
        _pinController.clear();
      });

      Future.delayed(Duration(seconds: 2), () {
        if (mounted) {
          setState(() => _pinError = false);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false, // Prevent back button
      child: Scaffold(
        backgroundColor: Colors.red.shade900,
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.red.shade900,
                Colors.red.shade700,
                Colors.red.shade900,
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
        ),
      ),
    );
  }

  Widget _buildAlarmScreen() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Pulsing alarm icon
        ScaleTransition(
          scale: Tween(begin: 1.0, end: 1.2).animate(_pulseController),
          child: Icon(Icons.alarm, size: 120, color: Colors.white),
        ),

        SizedBox(height: 40),

        // Main message
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

        // Subtitle
        Text(
          'Time to take a break!',
          style: TextStyle(fontSize: 24, color: Colors.white70),
          textAlign: TextAlign.center,
        ),

        SizedBox(height: 40),

        // Alarm playing indicator
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
  }

  Widget _buildPinEntryScreen() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Lock icon
          Icon(Icons.lock_outline, size: 80, color: Colors.white),

          SizedBox(height: 30),

          // Message
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
            'Screen time is over for today.\nAsk a parent to unlock.',
            style: TextStyle(fontSize: 18, color: Colors.white70),
            textAlign: TextAlign.center,
          ),

          SizedBox(height: 50),

          // PIN entry
          Text(
            'Enter Parent PIN',
            style: TextStyle(
              fontSize: 20,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),

          SizedBox(height: 20),

          // PIN input field
          Container(
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
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
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

          // Buttons
          Column(
            children: [
              // Unlock button
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

              // Add 15 min button
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
