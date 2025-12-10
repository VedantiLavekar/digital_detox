import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'parent_pin_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'kids_mode_service.dart';
import 'kids_mode_dashboard.dart';
import 'kids_overlay_service.dart';

/// Setup screen for Kids Mode
/// Parents set PIN and timer duration
class KidsModeSetup extends StatefulWidget {
  const KidsModeSetup({Key? key}) : super(key: key);

  @override
  State<KidsModeSetup> createState() => _KidsModeSetupState();
}

class _KidsModeSetupState extends State<KidsModeSetup> {
  final ParentPinService _pinService = ParentPinService();
  final KidsModeService _kidsModeService = KidsModeService();

  final TextEditingController _pinController = TextEditingController();
  final TextEditingController _confirmPinController = TextEditingController();

  int _selectedMinutes = 30;
  bool _pinSet = false;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // Always start with PIN setup screen - don't auto-skip
    // This ensures parents consciously set/verify PIN each session
  }

  @override
  void dispose() {
    _pinController.dispose();
    _confirmPinController.dispose();
    super.dispose();
  }

  Future<void> _savePin() async {
    final pin = _pinController.text;
    final confirmPin = _confirmPinController.text;

    setState(() {
      _errorMessage = null;
      _isLoading = true;
    });

    // Validate PIN
    if (pin.length != 4) {
      setState(() {
        _errorMessage = 'PIN must be 4 digits';
        _isLoading = false;
      });
      return;
    }

    if (pin != confirmPin) {
      setState(() {
        _errorMessage = 'PINs do not match';
        _isLoading = false;
      });
      return;
    }

    // Check if PIN already exists - if yes, verify it matches
    final isPinAlreadySet = await _pinService.isPinSet();

    if (isPinAlreadySet) {
      // Verify the entered PIN matches the stored PIN
      final isCorrect = await _pinService.verifyPin(pin);

      if (!isCorrect) {
        setState(() {
          _errorMessage = 'Incorrect PIN. Please enter your existing PIN.';
          _isLoading = false;
        });
        return;
      }

      // PIN verified - proceed to timer
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('PIN verified ✓')));
      }

      setState(() {
        _pinSet = true;
        _isLoading = false;
      });
    } else {
      // No PIN exists - save new PIN
      final success = await _pinService.setPin(pin);

      if (success) {
        final user = FirebaseAuth.instance.currentUser;
        final savedLocation = (user != null)
            ? 'Firebase and local backup'
            : 'Local backup only (not signed in)';

        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('PIN saved: $savedLocation')));
        }

        setState(() {
          _pinSet = true;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Failed to set PIN';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _startKidsMode() async {
    setState(() {
      _isLoading = true;
    });

    // Start Kids Mode immediately - permission will be checked when timer expires
    final success = await _kidsModeService.startKidsMode(_selectedMinutes);

    if (success) {
      // Request overlay permission in background (non-blocking)
      _requestOverlayPermissionInBackground();

      print('✅ Kids Mode started for $_selectedMinutes minutes');
      print('📱 Navigating to Kids Dashboard');

      // Navigate directly to Kids Dashboard to show timer immediately
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const KidsModeDashboard()),
        );
      }
    } else {
      setState(() {
        _errorMessage = 'Failed to start Kids Mode';
        _isLoading = false;
      });
    }
  }

  Future<void> _requestOverlayPermissionInBackground() async {
    try {
      final overlayService = KidsOverlayService();
      final hasPermission = await overlayService.hasOverlayPermission();

      if (!hasPermission) {
        print('📱 Requesting overlay permission in background...');
        await overlayService.requestOverlayPermission();
      }
    } catch (e) {
      print('⚠️ Background permission request failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.purple.shade400, Colors.pink.shade400],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: Icon(Icons.arrow_back, color: Colors.white),
                    ),
                    Expanded(
                      child: Text(
                        '👶 Kids Mode Setup',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    SizedBox(width: 48), // Balance the back button
                  ],
                ),

                SizedBox(height: 40),

                // Step indicator
                _buildStepIndicator(),

                SizedBox(height: 30),

                // Content
                _pinSet ? _buildTimerSetup() : _buildPinSetup(),

                if (_errorMessage != null) ...[
                  SizedBox(height: 20),
                  Container(
                    padding: EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: Colors.red.shade100,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.red.shade300),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error, color: Colors.red),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: TextStyle(color: Colors.red.shade900),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                SizedBox(height: 30),

                // Action button
                if (_isLoading)
                  Center(child: CircularProgressIndicator(color: Colors.white))
                else
                  ElevatedButton(
                    onPressed: _pinSet ? _startKidsMode : _savePin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.purple,
                      padding: EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      elevation: 5,
                    ),
                    child: Text(
                      _pinSet ? 'START KIDS MODE' : 'SAVE PIN & CONTINUE',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStepIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildStep(1, 'Set PIN', true),
        Container(
          width: 50,
          height: 2,
          color: _pinSet ? Colors.white : Colors.white38,
        ),
        _buildStep(2, 'Set Timer', _pinSet),
      ],
    );
  }

  Widget _buildStep(int number, String label, bool isActive) {
    return Column(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isActive ? Colors.white : Colors.white38,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              '$number',
              style: TextStyle(
                color: Colors.purple,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
        ),
        SizedBox(height: 5),
        Text(
          label,
          style: TextStyle(
            color: isActive ? Colors.white : Colors.white60,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildPinSetup() {
    return Container(
      padding: EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 15,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.security, color: Colors.purple, size: 30),
              SizedBox(width: 10),
              Text(
                'Set Parent PIN',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.purple,
                ),
              ),
            ],
          ),

          SizedBox(height: 10),

          Text(
            'Create a 4-digit PIN to unlock Kids Mode',
            style: TextStyle(color: Colors.grey.shade600),
          ),

          SizedBox(height: 25),

          // PIN input
          Text('Enter PIN', style: TextStyle(fontWeight: FontWeight.bold)),
          SizedBox(height: 8),
          TextField(
            controller: _pinController,
            keyboardType: TextInputType.number,
            maxLength: 4,
            obscureText: true,
            decoration: InputDecoration(
              hintText: '••••',
              filled: true,
              fillColor: Colors.grey.shade100,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              counterText: '',
            ),
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          ),

          SizedBox(height: 20),

          // Confirm PIN input
          Text('Confirm PIN', style: TextStyle(fontWeight: FontWeight.bold)),
          SizedBox(height: 8),
          TextField(
            controller: _confirmPinController,
            keyboardType: TextInputType.number,
            maxLength: 4,
            obscureText: true,
            decoration: InputDecoration(
              hintText: '••••',
              filled: true,
              fillColor: Colors.grey.shade100,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              counterText: '',
            ),
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          ),

          SizedBox(height: 15),

          Container(
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.orange, size: 20),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Remember this PIN! You\'ll need it to unlock the device.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.orange.shade900,
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

  Widget _buildTimerSetup() {
    return Container(
      padding: EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 15,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.timer, color: Colors.purple, size: 30),
              SizedBox(width: 10),
              Text(
                'Set Screen Time',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.purple,
                ),
              ),
            ],
          ),

          SizedBox(height: 10),

          Text(
            'How long can the child use the device?',
            style: TextStyle(color: Colors.grey.shade600),
          ),

          SizedBox(height: 30),

          // Timer display
          Center(
            child: Column(
              children: [
                Text(
                  '$_selectedMinutes',
                  style: TextStyle(
                    fontSize: 72,
                    fontWeight: FontWeight.bold,
                    color: Colors.purple,
                  ),
                ),
                Text(
                  'minutes',
                  style: TextStyle(fontSize: 20, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),

          SizedBox(height: 30),

          // Slider
          Slider(
            value: _selectedMinutes.toDouble(),
            min: 5,
            max: 180,
            divisions: 35,
            activeColor: Colors.purple,
            label: '$_selectedMinutes min',
            onChanged: (value) {
              setState(() {
                _selectedMinutes = value.toInt();
              });
            },
          ),

          SizedBox(height: 10),

          // Quick select buttons
          Wrap(
            spacing: 10,
            runSpacing: 10,
            alignment: WrapAlignment.center,
            children: [15, 30, 45, 60, 90, 120].map((minutes) {
              return ChoiceChip(
                label: Text('$minutes min'),
                selected: _selectedMinutes == minutes,
                onSelected: (selected) {
                  if (selected) {
                    setState(() {
                      _selectedMinutes = minutes;
                    });
                  }
                },
                selectedColor: Colors.purple,
                labelStyle: TextStyle(
                  color: _selectedMinutes == minutes
                      ? Colors.white
                      : Colors.purple,
                  fontWeight: FontWeight.bold,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
