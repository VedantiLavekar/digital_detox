import 'package:flutter/material.dart';
import 'kids_mode_service.dart';
import 'kids_blocking_screen.dart';

/// Simplified dashboard for Kids Mode
/// Shows large timer display and simple UI - no access to settings
class KidsModeDashboard extends StatefulWidget {
  const KidsModeDashboard({Key? key}) : super(key: key);

  @override
  State<KidsModeDashboard> createState() => _KidsModeDashboardState();
}

class _KidsModeDashboardState extends State<KidsModeDashboard>
    with SingleTickerProviderStateMixin {
  final KidsModeService _kidsModeService = KidsModeService();
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();

    _animController = AnimationController(
      vsync: this,
      duration: Duration(seconds: 3),
    )..repeat();

    // Initialize service
    _kidsModeService.initialize();

    // Listen for timer expiry
    _kidsModeService.onTimerExpired = () {
      _showBlockingScreen();
    };

    // Listen for state changes
    _kidsModeService.addListener(_onKidsModeUpdate);

    // Check if timer is already expired when dashboard loads
    // This handles the case where timer expired while app was closed
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_kidsModeService.isExpired) {
        _showBlockingScreen();
      }
    });
  }

  void _onKidsModeUpdate() {
    if (mounted) {
      setState(() {});

      // Check if timer expired
      if (_kidsModeService.isExpired) {
        _showBlockingScreen();
      }
    }
  }

  void _showBlockingScreen() {
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (context) => KidsBlockingScreen(),
          fullscreenDialog: true,
        ),
        (route) => false, // Remove all previous routes
      );
    }
  }

  @override
  void dispose() {
    _kidsModeService.removeListener(_onKidsModeUpdate);
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.purple.shade100,
              Colors.blue.shade100,
              Colors.pink.shade100,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: _kidsModeService.isActive
                ? _buildActiveTimerUI()
                : _buildInactiveUI(),
          ),
        ),
      ),
    );
  }

  Widget _buildActiveTimerUI() {
    final remainingSeconds = _kidsModeService.remainingSeconds;
    final totalSeconds = _kidsModeService.totalMinutes * 60;
    final progress = remainingSeconds / totalSeconds;

    // Determine color based on remaining time
    Color timerColor = Colors.green;
    if (remainingSeconds < 300) {
      // Less than 5 minutes
      timerColor = Colors.red;
    } else if (remainingSeconds < 600) {
      // Less than 10 minutes
      timerColor = Colors.orange;
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Large circular timer
        Container(
          width: 220,
          height: 220,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Progress circle
              SizedBox(
                width: 220,
                height: 220,
                child: CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 12,
                  backgroundColor: Colors.grey.shade300,
                  valueColor: AlwaysStoppedAnimation<Color>(timerColor),
                ),
              ),

              // Time text
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _kidsModeService.remainingTimeFormatted,
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: timerColor,
                      fontFamily: 'monospace',
                    ),
                  ),
                  Text(
                    'minutes left',
                    style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ],
          ),
        ),

        SizedBox(height: 30),

        // Encouraging message
        Container(
          margin: EdgeInsets.symmetric(horizontal: 30),
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.8),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 10,
                offset: Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            children: [
              Icon(
                remainingSeconds < 300 ? Icons.timer_outlined : Icons.thumb_up,
                size: 32,
                color: timerColor,
              ),
              SizedBox(height: 8),
              Text(
                _getEncouragingMessage(remainingSeconds),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.purple.shade700,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),

        SizedBox(height: 20),

        // Fun stats
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildStatCard(
              icon: Icons.access_time,
              label: 'Total Time',
              value: '${_kidsModeService.totalMinutes} min',
            ),
            _buildStatCard(
              icon: Icons.phone_android,
              label: 'Used Time',
              value:
                  '${_kidsModeService.totalMinutes - _kidsModeService.remainingMinutes} min',
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInactiveUI() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.timer_off, size: 100, color: Colors.grey.shade400),
          SizedBox(height: 20),
          Text(
            'No Timer Active',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700,
            ),
          ),
          SizedBox(height: 10),
          Text(
            'Ask your parent to set screen time',
            style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.8),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 5, offset: Offset(0, 3)),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.purple.shade700, size: 30),
          SizedBox(height: 5),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
          SizedBox(height: 3),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.purple.shade700,
            ),
          ),
        ],
      ),
    );
  }

  String _getEncouragingMessage(int secondsLeft) {
    if (secondsLeft < 60) {
      return '⏰ Almost time to stop!';
    } else if (secondsLeft < 300) {
      return '🎯 Just a few more minutes!';
    } else if (secondsLeft < 600) {
      return '👍 You\'re doing great!';
    } else {
      return '🎉 Enjoy your screen time!';
    }
  }
}
