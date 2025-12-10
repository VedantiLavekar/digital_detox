import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

const Color kPrimaryColor = Color(0xFF2E9D8A);
const Color kBackgroundColor = Color(0xFFF5F5DC);

class HealthyLifeSupportPage extends StatelessWidget {
  const HealthyLifeSupportPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        title: const Text(
          'Healthy Life Support',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 22,
            letterSpacing: 0.5,
          ),
        ),
        backgroundColor: kPrimaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        centerTitle: true,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [kPrimaryColor, Colors.teal.shade600],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [kBackgroundColor, kPrimaryColor.withOpacity(0.05)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: GridView.count(
              shrinkWrap: true,
              crossAxisCount: 2,
              mainAxisSpacing: 20,
              crossAxisSpacing: 20,
              childAspectRatio: 1,
              children: [
                _HealthCard(
                  icon: "💡",
                  label: 'Quick Tips',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const QuickTipsPage(),
                      ),
                    );
                  },
                ),
                _HealthCard(
                  icon: "😴",
                  label: 'Sleep Schedule',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SleepSchedulePage(),
                      ),
                    );
                  },
                ),
                _HealthCard(
                  icon: "🍎",
                  label: 'Eating Schedule',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const EatingSchedulePage(),
                      ),
                    );
                  },
                ),
                _HealthCard(
                  icon: "🌱",
                  label: 'Healthy Habits',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const HealthyHabitsPage(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HealthCard extends StatefulWidget {
  final String icon;
  final String label;
  final VoidCallback onTap;

  const _HealthCard({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  State<_HealthCard> createState() => _HealthCardState();
}

class _HealthCardState extends State<_HealthCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        setState(() => _isPressed = true);
        _controller.forward();
      },
      onTapUp: (_) {
        setState(() => _isPressed = false);
        _controller.reverse();
        widget.onTap();
      },
      onTapCancel: () {
        setState(() => _isPressed = false);
        _controller.reverse();
      },
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: _isPressed
                  ? [kPrimaryColor.withOpacity(0.8), Colors.teal.shade300]
                  : [kPrimaryColor, Colors.teal.shade400],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(25),
            boxShadow: [
              BoxShadow(
                color: kPrimaryColor.withOpacity(0.4),
                blurRadius: _isPressed ? 12 : 15,
                offset: _isPressed ? const Offset(0, 4) : const Offset(0, 8),
                spreadRadius: _isPressed ? 0 : 2,
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 600),
                curve: Curves.elasticOut,
                builder: (context, value, child) {
                  return Transform.scale(
                    scale: value,
                    child: Text(
                      widget.icon,
                      style: const TextStyle(fontSize: 55),
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
              Text(
                widget.label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class QuickTipsPage extends StatelessWidget {
  const QuickTipsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        title: const Text(
          'Quick Health Tips',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: kPrimaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        centerTitle: true,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [kBackgroundColor, kPrimaryColor.withOpacity(0.05)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: GridView.count(
          crossAxisCount: 2,
          padding: const EdgeInsets.all(16),
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 0.85,
          children: [
            _QuickTipCard(
              icon: "👁️",
              title: "Eye Break",
              subtitle: "20-20-20 Rule",
              color: Colors.blue,
            ),
            _QuickTipCard(
              icon: "🧍",
              title: "Posture Check",
              subtitle: "Sit Straight",
              color: Colors.orange,
            ),
            _QuickTipCard(
              icon: "💧",
              title: "Drink Water",
              subtitle: "Stay Hydrated",
              color: Colors.cyan,
            ),
            _QuickTipCard(
              icon: "🏃",
              title: "Move Around",
              subtitle: "Stretch & Walk",
              color: Colors.green,
            ),
            _QuickTipCard(
              icon: "🧘",
              title: "Deep Breath",
              subtitle: "Relax Mind",
              color: Colors.purple,
            ),
            _QuickTipCard(
              icon: "🌟",
              title: "Take a Break",
              subtitle: "Rest Your Mind",
              color: Colors.amber,
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickTipCard extends StatefulWidget {
  final String icon;
  final String title;
  final String subtitle;
  final Color color;

  const _QuickTipCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
  });

  @override
  State<_QuickTipCard> createState() => _QuickTipCardState();
}

class _QuickTipCardState extends State<_QuickTipCard> {
  bool _isDone = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _isDone = !_isDone;
        });
        if (_isDone) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Great! ${widget.title} done! ✓'),
              duration: const Duration(seconds: 1),
              backgroundColor: widget.color,
            ),
          );
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: _isDone
                ? [Colors.grey.shade300, Colors.grey.shade400]
                : [widget.color.withOpacity(0.7), widget.color],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: _isDone
                  ? Colors.grey.withOpacity(0.3)
                  : widget.color.withOpacity(0.4),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_isDone)
              const Icon(Icons.check_circle, color: Colors.white, size: 50)
            else
              Text(widget.icon, style: const TextStyle(fontSize: 55)),
            const SizedBox(height: 12),
            Text(
              widget.title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              widget.subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TipCard extends StatefulWidget {
  final String icon;
  final String title;
  final List<String> tips;

  const _TipCard({required this.icon, required this.title, required this.tips});

  @override
  State<_TipCard> createState() => _TipCardState();
}

class _TipCardState extends State<_TipCard>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = true;
  late AnimationController _animController;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _rotationAnimation = Tween<double>(begin: 0, end: 0.5).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(opacity: value, child: child),
        );
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: 16),
        elevation: 6,
        shadowColor: kPrimaryColor.withOpacity(0.3),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              colors: [Colors.white, kPrimaryColor.withOpacity(0.05)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: InkWell(
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
                if (_isExpanded) {
                  _animController.reverse();
                } else {
                  _animController.forward();
                }
              });
            },
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [kPrimaryColor, Colors.teal.shade300],
                          ),
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: [
                            BoxShadow(
                              color: kPrimaryColor.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Text(
                          widget.icon,
                          style: const TextStyle(fontSize: 28),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          widget.title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: kPrimaryColor,
                          ),
                        ),
                      ),
                      RotationTransition(
                        turns: _rotationAnimation,
                        child: Icon(
                          Icons.keyboard_arrow_down,
                          color: kPrimaryColor,
                          size: 28,
                        ),
                      ),
                    ],
                  ),
                  AnimatedCrossFade(
                    firstChild: Column(
                      children: [
                        const SizedBox(height: 16),
                        ...widget.tips.asMap().entries.map(
                          (entry) => TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0.0, end: 1.0),
                            duration: Duration(
                              milliseconds: 300 + (entry.key * 50),
                            ),
                            curve: Curves.easeOut,
                            builder: (context, value, child) {
                              return Transform.translate(
                                offset: Offset(20 * (1 - value), 0),
                                child: Opacity(opacity: value, child: child),
                              );
                            },
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    margin: const EdgeInsets.only(top: 6),
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: kPrimaryColor,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      entry.value,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        height: 1.5,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    secondChild: const SizedBox.shrink(),
                    crossFadeState: _isExpanded
                        ? CrossFadeState.showFirst
                        : CrossFadeState.showSecond,
                    duration: const Duration(milliseconds: 300),
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

class SleepSchedulePage extends StatefulWidget {
  const SleepSchedulePage({super.key});

  @override
  State<SleepSchedulePage> createState() => _SleepSchedulePageState();
}

class _SleepSchedulePageState extends State<SleepSchedulePage> {
  TimeOfDay? bedtime;
  TimeOfDay? wakeTime;
  List<Map<String, dynamic>> sleepLogs = [];

  @override
  void initState() {
    super.initState();
    _loadSchedule();
  }

  Future<void> _loadSchedule() async {
    final prefs = await SharedPreferences.getInstance();

    final bedtimeStr = prefs.getString('bedtime');
    final wakeTimeStr = prefs.getString('wakeTime');
    final logsStr = prefs.getString('sleepLogs');

    setState(() {
      if (bedtimeStr != null) {
        final parts = bedtimeStr.split(':');
        bedtime = TimeOfDay(
          hour: int.parse(parts[0]),
          minute: int.parse(parts[1]),
        );
      }
      if (wakeTimeStr != null) {
        final parts = wakeTimeStr.split(':');
        wakeTime = TimeOfDay(
          hour: int.parse(parts[0]),
          minute: int.parse(parts[1]),
        );
      }
      if (logsStr != null) {
        sleepLogs = List<Map<String, dynamic>>.from(json.decode(logsStr));
      }
    });
  }

  Future<void> _saveSchedule() async {
    final prefs = await SharedPreferences.getInstance();

    if (bedtime != null) {
      await prefs.setString('bedtime', '${bedtime!.hour}:${bedtime!.minute}');
    }
    if (wakeTime != null) {
      await prefs.setString(
        'wakeTime',
        '${wakeTime!.hour}:${wakeTime!.minute}',
      );
    }
    await prefs.setString('sleepLogs', json.encode(sleepLogs));
  }

  Future<void> _selectBedtime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: bedtime ?? const TimeOfDay(hour: 22, minute: 0),
    );
    if (picked != null) {
      setState(() {
        bedtime = picked;
      });
      _saveSchedule();
    }
  }

  Future<void> _selectWakeTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: wakeTime ?? const TimeOfDay(hour: 6, minute: 0),
    );
    if (picked != null) {
      setState(() {
        wakeTime = picked;
      });
      _saveSchedule();
    }
  }

  void _logSleep(int quality) {
    setState(() {
      sleepLogs.insert(0, {
        'date': DateTime.now().toIso8601String(),
        'quality': quality,
      });
      if (sleepLogs.length > 7) {
        sleepLogs = sleepLogs.sublist(0, 7);
      }
    });
    _saveSchedule();

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Sleep quality logged!')));
  }

  String _getSleepDuration() {
    if (bedtime == null || wakeTime == null) return "Not set";

    int bedMinutes = bedtime!.hour * 60 + bedtime!.minute;
    int wakeMinutes = wakeTime!.hour * 60 + wakeTime!.minute;

    int duration = wakeMinutes - bedMinutes;
    if (duration < 0) duration += 24 * 60;

    int hours = duration ~/ 60;
    int minutes = duration % 60;

    return "$hours hours $minutes minutes";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        title: const Text(
          'Sleep Schedule',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        backgroundColor: kPrimaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        centerTitle: true,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [kPrimaryColor, Colors.teal.shade600],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [kBackgroundColor, Colors.indigo.withOpacity(0.05)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Sleep Schedule Card
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      const Text(
                        "Your Sleep Schedule",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: kPrimaryColor,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _TimeSelector(
                            icon: "🌙",
                            label: "Bedtime",
                            time: bedtime,
                            onTap: _selectBedtime,
                          ),
                          _TimeSelector(
                            icon: "☀️",
                            label: "Wake Up",
                            time: wakeTime,
                            onTap: _selectWakeTime,
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: kPrimaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          children: [
                            const Text(
                              "Sleep Duration",
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _getSleepDuration(),
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: kPrimaryColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "How did you sleep last night?",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _QualityButton(
                            emoji: "😫",
                            label: "Poor",
                            onTap: () => _logSleep(1),
                          ),
                          _QualityButton(
                            emoji: "😐",
                            label: "Fair",
                            onTap: () => _logSleep(2),
                          ),
                          _QualityButton(
                            emoji: "😊",
                            label: "Good",
                            onTap: () => _logSleep(3),
                          ),
                          _QualityButton(
                            emoji: "😍",
                            label: "Great",
                            onTap: () => _logSleep(4),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              if (sleepLogs.isNotEmpty) ...[
                const SizedBox(height: 20),
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Recent Sleep Quality",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ...sleepLogs.take(7).map((log) {
                          final date = DateTime.parse(log['date']);
                          final quality = log['quality'];
                          final emoji = ['😫', '😐', '😊', '😍'][quality - 1];
                          final label = [
                            'Poor',
                            'Fair',
                            'Good',
                            'Great',
                          ][quality - 1];

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              children: [
                                Text(
                                  emoji,
                                  style: const TextStyle(fontSize: 24),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  "${date.month}/${date.day}",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(label),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _TimeSelector extends StatelessWidget {
  final String icon;
  final String label;
  final TimeOfDay? time;
  final VoidCallback onTap;

  const _TimeSelector({
    required this.icon,
    required this.label,
    required this.time,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Text(icon, style: const TextStyle(fontSize: 40)),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: kPrimaryColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              time != null ? time!.format(context) : "Set Time",
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QualityButton extends StatelessWidget {
  final String emoji;
  final String label;
  final VoidCallback onTap;

  const _QualityButton({
    required this.emoji,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 36)),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}

// ============ EATING SCHEDULE PAGE ============
class EatingSchedulePage extends StatefulWidget {
  const EatingSchedulePage({super.key});

  @override
  State<EatingSchedulePage> createState() => _EatingSchedulePageState();
}

class _EatingSchedulePageState extends State<EatingSchedulePage> {
  TimeOfDay? breakfastTime;
  TimeOfDay? lunchTime;
  TimeOfDay? dinnerTime;
  List<String> todaysMeals = [];

  @override
  void initState() {
    super.initState();
    _loadSchedule();
  }

  Future<void> _loadSchedule() async {
    final prefs = await SharedPreferences.getInstance();

    final breakfastStr = prefs.getString('breakfastTime');
    final lunchStr = prefs.getString('lunchTime');
    final dinnerStr = prefs.getString('dinnerTime');
    final mealsStr = prefs.getString('todaysMeals_${DateTime.now().day}');

    setState(() {
      if (breakfastStr != null) {
        final parts = breakfastStr.split(':');
        breakfastTime = TimeOfDay(
          hour: int.parse(parts[0]),
          minute: int.parse(parts[1]),
        );
      }
      if (lunchStr != null) {
        final parts = lunchStr.split(':');
        lunchTime = TimeOfDay(
          hour: int.parse(parts[0]),
          minute: int.parse(parts[1]),
        );
      }
      if (dinnerStr != null) {
        final parts = dinnerStr.split(':');
        dinnerTime = TimeOfDay(
          hour: int.parse(parts[0]),
          minute: int.parse(parts[1]),
        );
      }
      if (mealsStr != null) {
        todaysMeals = List<String>.from(json.decode(mealsStr));
      }
    });
  }

  Future<void> _saveSchedule() async {
    final prefs = await SharedPreferences.getInstance();

    if (breakfastTime != null) {
      await prefs.setString(
        'breakfastTime',
        '${breakfastTime!.hour}:${breakfastTime!.minute}',
      );
    }
    if (lunchTime != null) {
      await prefs.setString(
        'lunchTime',
        '${lunchTime!.hour}:${lunchTime!.minute}',
      );
    }
    if (dinnerTime != null) {
      await prefs.setString(
        'dinnerTime',
        '${dinnerTime!.hour}:${dinnerTime!.minute}',
      );
    }
    await prefs.setString(
      'todaysMeals_${DateTime.now().day}',
      json.encode(todaysMeals),
    );
  }

  Future<void> _selectMealTime(String meal) async {
    TimeOfDay? initialTime;
    if (meal == 'Breakfast') {
      initialTime = breakfastTime ?? const TimeOfDay(hour: 8, minute: 0);
    }
    if (meal == 'Lunch') {
      initialTime = lunchTime ?? const TimeOfDay(hour: 13, minute: 0);
    }
    if (meal == 'Dinner') {
      initialTime = dinnerTime ?? const TimeOfDay(hour: 19, minute: 0);
    }

    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: initialTime!,
    );

    if (picked != null) {
      setState(() {
        if (meal == 'Breakfast') breakfastTime = picked;
        if (meal == 'Lunch') lunchTime = picked;
        if (meal == 'Dinner') dinnerTime = picked;
      });
      _saveSchedule();
    }
  }

  void _toggleMeal(String meal) {
    setState(() {
      if (todaysMeals.contains(meal)) {
        todaysMeals.remove(meal);
      } else {
        todaysMeals.add(meal);
      }
    });
    _saveSchedule();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        title: const Text(
          'Eating Schedule',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: kPrimaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Meal Schedule Card
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const Text(
                      "Your Meal Schedule",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: kPrimaryColor,
                      ),
                    ),
                    const SizedBox(height: 20),
                    _MealTimeRow(
                      icon: "🌅",
                      meal: "Breakfast",
                      time: breakfastTime,
                      onTap: () => _selectMealTime('Breakfast'),
                    ),
                    const Divider(height: 30),
                    _MealTimeRow(
                      icon: "☀️",
                      meal: "Lunch",
                      time: lunchTime,
                      onTap: () => _selectMealTime('Lunch'),
                    ),
                    const Divider(height: 30),
                    _MealTimeRow(
                      icon: "🌙",
                      meal: "Dinner",
                      time: dinnerTime,
                      onTap: () => _selectMealTime('Dinner'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Track Today's Meals
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Track Today's Meals",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: kPrimaryColor,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _MealCheckbox(
                      meal: "Breakfast",
                      isChecked: todaysMeals.contains("Breakfast"),
                      onTap: () => _toggleMeal("Breakfast"),
                    ),
                    _MealCheckbox(
                      meal: "Lunch",
                      isChecked: todaysMeals.contains("Lunch"),
                      onTap: () => _toggleMeal("Lunch"),
                    ),
                    _MealCheckbox(
                      meal: "Dinner",
                      isChecked: todaysMeals.contains("Dinner"),
                      onTap: () => _toggleMeal("Dinner"),
                    ),
                    _MealCheckbox(
                      meal: "Snacks",
                      isChecked: todaysMeals.contains("Snacks"),
                      onTap: () => _toggleMeal("Snacks"),
                    ),
                    _MealCheckbox(
                      meal: "Water (8 glasses)",
                      isChecked: todaysMeals.contains("Water (8 glasses)"),
                      onTap: () => _toggleMeal("Water (8 glasses)"),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MealTimeRow extends StatelessWidget {
  final String icon;
  final String meal;
  final TimeOfDay? time;
  final VoidCallback onTap;

  const _MealTimeRow({
    required this.icon,
    required this.meal,
    required this.time,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 32)),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              meal,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: kPrimaryColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              time != null ? time!.format(context) : "Set Time",
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MealCheckbox extends StatelessWidget {
  final String meal;
  final bool isChecked;
  final VoidCallback onTap;

  const _MealCheckbox({
    required this.meal,
    required this.isChecked,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: isChecked ? kPrimaryColor : Colors.white,
                border: Border.all(color: kPrimaryColor, width: 2),
                borderRadius: BorderRadius.circular(6),
              ),
              child: isChecked
                  ? const Icon(Icons.check, color: Colors.white, size: 18)
                  : null,
            ),
            const SizedBox(width: 12),
            Text(
              meal,
              style: TextStyle(
                fontSize: 16,
                decoration: isChecked ? TextDecoration.lineThrough : null,
                color: isChecked ? Colors.grey : Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============ HEALTHY HABITS PAGE ============
class HealthyHabitsPage extends StatefulWidget {
  const HealthyHabitsPage({super.key});

  @override
  State<HealthyHabitsPage> createState() => _HealthyHabitsPageState();
}

class _HealthyHabitsPageState extends State<HealthyHabitsPage> {
  List<Map<String, dynamic>> habits = [];
  final TextEditingController _habitController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadHabits();
  }

  Future<void> _loadHabits() async {
    final prefs = await SharedPreferences.getInstance();
    final habitsStr = prefs.getString('healthyHabits');

    setState(() {
      if (habitsStr != null) {
        habits = List<Map<String, dynamic>>.from(json.decode(habitsStr));
      } else {
        // Default habits
        habits = [
          {'name': 'Morning walk', 'completed': false},
          {'name': 'Read a book', 'completed': false},
          {'name': 'Cook a healthy meal', 'completed': false},
          {'name': 'Exercise 30 minutes', 'completed': false},
          {'name': 'Drink 8 glasses of water', 'completed': false},
        ];
      }
    });
  }

  Future<void> _saveHabits() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('healthyHabits', json.encode(habits));
  }

  void _toggleHabit(int index) {
    setState(() {
      habits[index]['completed'] = !habits[index]['completed'];
    });
    _saveHabits();
  }

  void _addHabit() {
    if (_habitController.text.isNotEmpty) {
      setState(() {
        habits.add({'name': _habitController.text, 'completed': false});
        _habitController.clear();
      });
      _saveHabits();
      Navigator.pop(context);
    }
  }

  void _deleteHabit(int index) {
    setState(() {
      habits.removeAt(index);
    });
    _saveHabits();
  }

  void _showAddHabitDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Habit'),
        content: TextField(
          controller: _habitController,
          decoration: const InputDecoration(
            hintText: 'Enter habit name',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: _addHabit,
            style: ElevatedButton.styleFrom(backgroundColor: kPrimaryColor),
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    int completedCount = habits.where((h) => h['completed'] == true).length;

    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        title: const Text(
          'Healthy Habits Builder',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: kPrimaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddHabitDialog,
        backgroundColor: kPrimaryColor,
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          // Progress Card
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [kPrimaryColor, Colors.teal.shade400],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(15),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 8,
                  offset: Offset(2, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                const Text(
                  "Today's Progress",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  "$completedCount / ${habits.length}",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Habits Completed",
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),

          // Habits List
          Expanded(
            child: habits.isEmpty
                ? const Center(
                    child: Text(
                      "Add your first habit!",
                      style: TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: habits.length,
                    itemBuilder: (context, index) {
                      final habit = habits[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          leading: InkWell(
                            onTap: () => _toggleHabit(index),
                            child: Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                color: habit['completed']
                                    ? kPrimaryColor
                                    : Colors.white,
                                border: Border.all(
                                  color: kPrimaryColor,
                                  width: 2,
                                ),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: habit['completed']
                                  ? const Icon(
                                      Icons.check,
                                      color: Colors.white,
                                      size: 20,
                                    )
                                  : null,
                            ),
                          ),
                          title: Text(
                            habit['name'],
                            style: TextStyle(
                              fontSize: 16,
                              decoration: habit['completed']
                                  ? TextDecoration.lineThrough
                                  : null,
                              color: habit['completed']
                                  ? Colors.grey
                                  : Colors.black,
                            ),
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _deleteHabit(index),
                          ),
                        ),
                      );
                    },
                  ),
          ),

          // Screen-Free Activity Suggestions
          Card(
            margin: const EdgeInsets.all(16),
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Text("🎨", style: TextStyle(fontSize: 24)),
                      SizedBox(width: 8),
                      Text(
                        "Screen-Free Activity Ideas",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: kPrimaryColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _ActivityChip("🚶 Take a walk"),
                      _ActivityChip("📚 Read a book"),
                      _ActivityChip("🧘 Yoga/Meditation"),
                      _ActivityChip("🎨 Draw or paint"),
                      _ActivityChip("🍳 Cook a meal"),
                      _ActivityChip("🌱 Gardening"),
                      _ActivityChip("🎵 Play music"),
                      _ActivityChip("🏃 Exercise"),
                      _ActivityChip("👥 Meet friends"),
                      _ActivityChip("🧩 Puzzles/Games"),
                      _ActivityChip("✍️ Write/Journal"),
                      _ActivityChip("🧶 Crafts/DIY"),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivityChip extends StatelessWidget {
  final String label;

  const _ActivityChip(this.label);

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(label, style: const TextStyle(fontSize: 12)),
      backgroundColor: kPrimaryColor.withOpacity(0.1),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    );
  }
}
