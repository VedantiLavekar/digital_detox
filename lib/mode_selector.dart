import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lottie/lottie.dart';
import 'dashboard.dart';
import 'kids_mode_setup.dart';
import 'parent_pin_service.dart';

/// Mode selector screen - first screen shown on app launch
/// Allows user to choose between Adult Mode or Kids Mode
class ModeSelector extends StatefulWidget {
  const ModeSelector({Key? key}) : super(key: key);

  @override
  State<ModeSelector> createState() => _ModeSelectorState();
}

class _ModeSelectorState extends State<ModeSelector>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  final ParentPinService _pinService = ParentPinService();

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _selectAdultMode() async {
    // Save mode selection
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('mode_selected', true);
    await prefs.setString('selected_mode', 'adult');

    // Navigate to adult dashboard
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (context) => DashboardPage()));
  }

  Future<void> _selectKidsMode() async {
    // Save mode selection
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('mode_selected', true);
    await prefs.setString('selected_mode', 'kids');

    // Check if parent PIN is set
    final isPinSet = await _pinService.isPinSet();

    if (!isPinSet) {
      // First time using Kids Mode - parent must set PIN
      _showFirstTimeSetup();
    } else {
      // PIN already set - go to Kids Mode setup (set timer)
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => KidsModeSetup()),
      );
    }
  }

  void _showFirstTimeSetup() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.security, color: Colors.orange),
            SizedBox(width: 10),
            Text('Parent Setup Required'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'First time using Kids Mode?',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            SizedBox(height: 10),
            Text(
              'Parents must create a PIN code to:\n'
              '• Set screen time limits\n'
              '• Unlock the device when time expires\n'
              '• Protect settings from changes',
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
                  Icon(Icons.warning_amber, color: Colors.orange),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Keep your PIN safe! It cannot be recovered.',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context) => KidsModeSetup()),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
            child: Text('Continue'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFF5F5DC), Color(0xFFFFE4B5), Color(0xFFFFF8DC)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.0, vertical: 40),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Title
                    Text(
                      'Choose Your Mode',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2E9D8A),
                        letterSpacing: 1.2,
                      ),
                    ),
                    SizedBox(height: 60),

                    // Kids Mode Card
                    _buildModeCard(
                      animationPath: 'assets/animations/Happy boy.json',
                      label: 'Kids Mode',
                      gradient: [
                        Colors.orange.shade400,
                        Colors.orange.shade700,
                      ],
                      onTap: _selectKidsMode,
                    ),

                    SizedBox(height: 50),

                    // Adult Mode Card
                    _buildModeCard(
                      animationPath: 'assets/animations/Female avatar.json',
                      label: 'Adult Mode',
                      gradient: [Color(0xFF2E9D8A), Color(0xFF1A7A6A)],
                      onTap: _selectAdultMode,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModeCard({
    required String animationPath,
    required String label,
    required List<Color> gradient,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 280,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: gradient[0].withOpacity(0.3),
              blurRadius: 25,
              spreadRadius: 1,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(30),
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 30, horizontal: 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Animation
                  Container(
                    height: 200,
                    width: 200,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: gradient,
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(25),
                      child: Lottie.asset(
                        animationPath,
                        fit: BoxFit.contain,
                        repeat: true,
                        errorBuilder: (context, error, stackTrace) {
                          // Fallback to icon if animation fails
                          return Icon(
                            label == 'Kids Mode'
                                ? Icons.child_care
                                : Icons.person,
                            size: 120,
                            color: Colors.white,
                          );
                        },
                      ),
                    ),
                  ),
                  SizedBox(height: 20),

                  // Label
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: gradient[1],
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
