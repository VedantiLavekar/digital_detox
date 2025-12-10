import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math';

class ActivityAchievements {
  static const Map<String, Map<String, dynamic>> achievements = {
    'first_activity': {
      'title': 'Getting Started! 🌟',
      'description': 'Completed your first activity',
      'icon': '🎯',
      'color': Colors.blue,
    },
    'streak_3': {
      'title': 'On a Roll! 🔥',
      'description': 'Completed 3 activities',
      'icon': '🔥',
      'color': Colors.orange,
    },
    'streak_7': {
      'title': 'Week Warrior! 💪',
      'description': 'Completed 7 activities',
      'icon': '💪',
      'color': Colors.green,
    },
    'meditation_master': {
      'title': 'Meditation Master 🧘‍♀️',
      'description': 'Completed 5 meditation sessions',
      'icon': '🧘‍♀️',
      'color': Colors.purple,
    },
    'walker': {
      'title': 'Walking Champion 🚶‍♂️',
      'description': 'Completed 5 walking activities',
      'icon': '🚶‍♂️',
      'color': Colors.teal,
    },
    'phone_detox_hero': {
      'title': 'Digital Detox Hero 📱❌',
      'description': 'Completed 5 phone detox sessions',
      'icon': '📱❌',
      'color': Colors.red,
    },
  };

  static void showAchievementDialog(
    BuildContext context,
    String achievementKey,
  ) {
    final achievement = achievements[achievementKey];
    if (achievement == null) return;

    HapticFeedback.mediumImpact();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                achievement['color'].withOpacity(0.8),
                achievement['color'],
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: achievement['color'].withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TweenAnimationBuilder(
                tween: Tween<double>(begin: 0, end: 1),
                duration: const Duration(milliseconds: 800),
                builder: (context, double value, child) {
                  return Transform.scale(
                    scale: value,
                    child: Text(
                      achievement['icon'],
                      style: const TextStyle(fontSize: 60),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              const Text(
                'Achievement Unlocked!',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                achievement['title'],
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                achievement['description'],
                style: const TextStyle(color: Colors.white70, fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: achievement['color'],
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

  static void checkAndShowAchievements(
    BuildContext context, {
    int totalActivities = 0,
    int meditationCount = 0,
    int walkCount = 0,
    int phoneDetoxCount = 0,
  }) {
    if (totalActivities == 1) {
      showAchievementDialog(context, 'first_activity');
    } else if (totalActivities == 3) {
      showAchievementDialog(context, 'streak_3');
    } else if (totalActivities == 7) {
      showAchievementDialog(context, 'streak_7');
    }

    if (meditationCount == 5) {
      showAchievementDialog(context, 'meditation_master');
    }

    if (walkCount == 5) {
      showAchievementDialog(context, 'walker');
    }

    if (phoneDetoxCount == 5) {
      showAchievementDialog(context, 'phone_detox_hero');
    }
  }
}

class ActivityMotivation {
  static final List<String> startMessages = [
    "🌟 You've got this! Every step counts towards better wellness!",
    "💪 Time to shine! Your future self will thank you for this!",
    "🎯 Focus on this moment - you're doing something amazing!",
    "✨ Progress over perfection! You're already winning by starting!",
    "🚀 Ready to level up your wellness? Let's go!",
    "💎 You're investing in the most important thing - yourself!",
    "🌈 Small steps lead to big changes. You're on the right path!",
    "⭐ Believe in yourself! You have the strength to complete this!",
  ];

  static final List<String> encouragementMessages = [
    "🔥 You're doing great! Keep up the momentum!",
    "💫 Halfway there! Your dedication is inspiring!",
    "🌟 Stay strong! You're building healthy habits!",
    "⚡ Power through! You're stronger than you think!",
    "🎉 Amazing progress! Don't stop now!",
    "💪 You're a wellness warrior! Keep going!",
    "🏆 Excellence in motion! You're unstoppable!",
    "🌸 Breathe, focus, and keep moving forward!",
  ];

  static final List<String> completionMessages = [
    "🎉 Incredible job! You completed your activity!",
    "🌟 Success! You're building amazing habits!",
    "💪 Fantastic work! You should be proud!",
    "✨ Mission accomplished! You're a wellness champion!",
    "🏆 Outstanding! You've earned this victory!",
    "🚀 Boom! Another step towards better health!",
    "💎 Perfect! You're investing in your best life!",
    "🌈 Beautiful work! You're glowing with accomplishment!",
  ];

  static String getRandomMessage(List<String> messages) {
    final random = Random();
    return messages[random.nextInt(messages.length)];
  }

  static String getStartMessage() => getRandomMessage(startMessages);
  static String getEncouragementMessage() =>
      getRandomMessage(encouragementMessages);
  static String getCompletionMessage() => getRandomMessage(completionMessages);
}

class ActivityTimer extends StatefulWidget {
  final String activityTitle;
  final int totalMinutes;
  final VoidCallback onComplete;
  final VoidCallback? onPause;
  final VoidCallback? onResume;

  const ActivityTimer({
    super.key,
    required this.activityTitle,
    required this.totalMinutes,
    required this.onComplete,
    this.onPause,
    this.onResume,
  });

  @override
  State<ActivityTimer> createState() => _ActivityTimerState();
}

class _ActivityTimerState extends State<ActivityTimer>
    with TickerProviderStateMixin {
  late AnimationController _progressController;
  late AnimationController _pulseController;
  bool _isRunning = true;
  int _remainingSeconds = 0;
  String? _motivationalMessage;

  @override
  void initState() {
    super.initState();
    _remainingSeconds = widget.totalMinutes * 60;

    _progressController = AnimationController(
      duration: Duration(seconds: widget.totalMinutes * 60),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _progressController.forward();
    _pulseController.repeat();

    _motivationalMessage = ActivityMotivation.getStartMessage();

    _scheduleEncouragement();
  }

  void _scheduleEncouragement() {
    final halfTime = (widget.totalMinutes * 60 / 2).floor();
    final threeQuarterTime = (widget.totalMinutes * 60 * 0.75).floor();

    Future.delayed(Duration(seconds: halfTime), () {
      if (mounted && _isRunning) {
        setState(() {
          _motivationalMessage = ActivityMotivation.getEncouragementMessage();
        });
        HapticFeedback.lightImpact();
      }
    });

    Future.delayed(Duration(seconds: threeQuarterTime), () {
      if (mounted && _isRunning) {
        setState(() {
          _motivationalMessage =
              "🔥 Almost there! You're in the final stretch!";
        });
        HapticFeedback.lightImpact();
      }
    });
  }

  void _toggleTimer() {
    setState(() {
      _isRunning = !_isRunning;
    });

    if (_isRunning) {
      _progressController.forward();
      _pulseController.repeat();
      widget.onResume?.call();
    } else {
      _progressController.stop();
      _pulseController.stop();
      widget.onPause?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    final minutes = _remainingSeconds ~/ 60;
    final seconds = _remainingSeconds % 60;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [const Color(0xFF4CAF50), const Color(0xFF2E7D32)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4CAF50).withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            widget.activityTitle,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),

          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 200,
                height: 200,
                child: AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _isRunning
                          ? 1 + (_pulseController.value * 0.05)
                          : 1,
                      child: CircularProgressIndicator(
                        value: _progressController.value,
                        strokeWidth: 12,
                        backgroundColor: Colors.white30,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Colors.white,
                        ),
                      ),
                    );
                  },
                ),
              ),
              Column(
                children: [
                  Text(
                    '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    _isRunning ? 'Active' : 'Paused',
                    style: const TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 24),

          if (_motivationalMessage != null)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _motivationalMessage!,
                style: const TextStyle(color: Colors.white, fontSize: 16),
                textAlign: TextAlign.center,
              ),
            ),

          const SizedBox(height: 24),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton.icon(
                onPressed: _toggleTimer,
                icon: Icon(_isRunning ? Icons.pause : Icons.play_arrow),
                label: Text(_isRunning ? 'Pause' : 'Resume'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF4CAF50),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                ),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  HapticFeedback.mediumImpact();
                  setState(() {
                    _motivationalMessage =
                        ActivityMotivation.getCompletionMessage();
                  });
                  widget.onComplete();
                },
                icon: const Icon(Icons.check),
                label: const Text('Complete'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF4CAF50),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _progressController.dispose();
    _pulseController.dispose();
    super.dispose();
  }
}
