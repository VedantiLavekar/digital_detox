import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:async';
import 'detox_timer_service.dart';
import 'blocking_screen.dart';

const Color kPrimaryColor = Color(0xFF2E9D8A);
const Color kBackgroundColor = Color(0xFFF5F5DC);

// App Limit Model
class AppLimit {
  final String name;
  final String icon;
  int limitMinutes;
  final Color color;
  bool isActive;
  int? remainingMinutes;

  AppLimit({
    required this.name,
    required this.icon,
    required this.limitMinutes,
    required this.color,
    this.isActive = false,
    this.remainingMinutes,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'icon': icon,
    'limitMinutes': limitMinutes,
    'colorValue': color.value,
  };

  factory AppLimit.fromJson(Map<String, dynamic> json) => AppLimit(
    name: json['name'],
    icon: json['icon'],
    limitMinutes: json['limitMinutes'],
    color: Color(json['colorValue']),
  );
}

class DetoxModePage extends StatefulWidget {
  const DetoxModePage({super.key});

  @override
  State<DetoxModePage> createState() => _DetoxModePageState();
}

class _DetoxModePageState extends State<DetoxModePage> {
  final DetoxTimerService _timerService = DetoxTimerService();
  List<AppLimit> appLimits = [];
  int totalBlockedToday = 0;
  int currentStreak = 0;
  int points = 0;
  Timer? _uiUpdateTimer;

  @override
  void initState() {
    super.initState();
    _initializeService();
    _loadData();

    // Update UI every second to show remaining time
    _uiUpdateTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _updateRemainingTimes();
    });
  }

  @override
  void dispose() {
    _uiUpdateTimer?.cancel();
    super.dispose();
  }

  Future<void> _initializeService() async {
    await _timerService.initialize();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      // Load app limits
      final limitsStr = prefs.getString('appLimits');
      if (limitsStr != null) {
        final List<dynamic> decoded = json.decode(limitsStr);
        appLimits = decoded.map((e) => AppLimit.fromJson(e)).toList();
      } else {
        // Default apps
        appLimits = [
          AppLimit(
            name: 'Instagram',
            icon: '📷',
            limitMinutes: 30,
            color: Colors.pink,
          ),
          AppLimit(
            name: 'Facebook',
            icon: '👍',
            limitMinutes: 30,
            color: Colors.blue,
          ),
          AppLimit(
            name: 'TikTok',
            icon: '🎵',
            limitMinutes: 20,
            color: Colors.black,
          ),
          AppLimit(
            name: 'YouTube',
            icon: '▶️',
            limitMinutes: 45,
            color: Colors.red,
          ),
          AppLimit(
            name: 'Games',
            icon: '🎮',
            limitMinutes: 60,
            color: Colors.purple,
          ),
        ];
      }

      totalBlockedToday = prefs.getInt('totalBlockedToday') ?? 0;
      currentStreak = prefs.getInt('currentStreak') ?? 0;
      points = prefs.getInt('detoxPoints') ?? 0;
    });

    await _updateRemainingTimes();
  }

  Future<void> _updateRemainingTimes() async {
    for (var app in appLimits) {
      final remaining = await _timerService.getRemainingMinutes(app.name);
      final isBlocked = await _timerService.isAppBlocked(app.name);

      if (mounted) {
        setState(() {
          app.isActive = remaining != null && remaining > 0;
          app.remainingMinutes = remaining;

          if (isBlocked) {
            app.isActive = false;
            app.remainingMinutes = null;
            // Show blocking screen
            _showBlockingScreen(app);
          }
        });
      }
    }

    // Reload stats
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        totalBlockedToday = prefs.getInt('totalBlockedToday') ?? 0;
        currentStreak = prefs.getInt('currentStreak') ?? 0;
        points = prefs.getInt('detoxPoints') ?? 0;
      });
    }
  }

  void _showBlockingScreen(AppLimit app) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BlockingScreen(
          appName: app.name,
          appIcon: app.icon,
          blockDurationMinutes: 15,
          onAccept: () async {
            // Award points for accepting
            final prefs = await SharedPreferences.getInstance();
            final currentPoints = prefs.getInt('detoxPoints') ?? 0;
            await prefs.setInt('detoxPoints', currentPoints + 10);

            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('✅ Good choice! +10 points'),
                  backgroundColor: Colors.green,
                ),
              );
            }
            await _updateRemainingTimes();
          },
          onBreakLimit: () async {
            // Penalize for breaking limit
            final prefs = await SharedPreferences.getInstance();
            final currentPoints = prefs.getInt('detoxPoints') ?? 0;
            await prefs.setInt('detoxPoints', currentPoints - 20);
            await prefs.setInt('currentStreak', 0);

            // Remove block
            await _timerService.stopTimer(app.name);
            final blockedAppsStr = prefs.getString('blockedApps') ?? '{}';
            final Map<String, dynamic> blockedApps = json.decode(
              blockedAppsStr,
            );
            blockedApps.remove(app.name);
            await prefs.setString('blockedApps', json.encode(blockedApps));

            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('⚠️ Limit broken. -20 points, streak reset'),
                  backgroundColor: Colors.orange,
                  duration: Duration(seconds: 3),
                ),
              );
            }
            await _updateRemainingTimes();
          },
        ),
      ),
    );
  }

  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'appLimits',
      json.encode(appLimits.map((e) => e.toJson()).toList()),
    );
  }

  Future<void> _startTimer(AppLimit app) async {
    final isBlocked = await _timerService.isAppBlocked(app.name);

    if (isBlocked) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${app.name} is currently soft-blocked for 15 minutes'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    await _timerService.startTimer(app.name, app.limitMinutes);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '⏱️ Timer started for ${app.name}! You can use it for ${app.limitMinutes} minutes.\n'
          'You can now leave this screen and use other apps.',
        ),
        backgroundColor: kPrimaryColor,
        duration: const Duration(seconds: 4),
      ),
    );

    await _updateRemainingTimes();
  }

  Future<void> _stopTimer(AppLimit app) async {
    await _timerService.stopTimer(app.name);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✅ Timer stopped for ${app.name}! +10 points'),
        backgroundColor: Colors.green,
      ),
    );

    // Award points for stopping early
    final prefs = await SharedPreferences.getInstance();
    final currentPoints = prefs.getInt('detoxPoints') ?? 0;
    await prefs.setInt('detoxPoints', currentPoints + 10);

    await _updateRemainingTimes();
  }

  void _editAppLimit(AppLimit app) {
    showDialog(
      context: context,
      builder: (context) => _EditLimitDialog(
        app: app,
        onSave: (newLimit) {
          setState(() {
            app.limitMinutes = newLimit;
          });
          _saveData();
        },
      ),
    );
  }

  String _formatTime(int? minutes) {
    if (minutes == null) return '--:--';
    final hrs = minutes ~/ 60;
    final mins = minutes % 60;
    if (hrs > 0) {
      return '${hrs}h ${mins}m';
    }
    return '${mins}m';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        title: const Text(
          'Detox Mode',
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
            colors: [kBackgroundColor, kPrimaryColor.withOpacity(0.05)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Stats Cards
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      icon: '🔥',
                      value: '$currentStreak',
                      label: 'Day Streak',
                      color: Colors.orange,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      icon: '⭐',
                      value: '$points',
                      label: 'Points',
                      color: Colors.amber,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      icon: '🚫',
                      value: '$totalBlockedToday',
                      label: 'Blocked',
                      color: Colors.red,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Info Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blue.shade400, Colors.blue.shade600],
                  ),
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.white, size: 30),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Set timer and use other apps freely! You\'ll get notified 5 mins before time is up.',
                        style: TextStyle(color: Colors.white, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // App Limits Title
              const Text(
                'App Time Limits',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Set and start timer for each app',
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 16),

              // App Cards
              ...appLimits.map(
                (app) => _AppLimitCard(
                  app: app,
                  onStart: () => _startTimer(app),
                  onStop: () => _stopTimer(app),
                  onEdit: () => _editAppLimit(app),
                  formatTime: _formatTime,
                ),
              ),

              const SizedBox(height: 24),

              // How it works section
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.green.shade300, width: 2),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.lightbulb, color: Colors.green, size: 24),
                        const SizedBox(width: 8),
                        const Text(
                          'How It Works',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _HowItWorksStep('1', 'Set time limit for app'),
                    _HowItWorksStep('2', 'Start timer and use app freely'),
                    _HowItWorksStep('3', 'Get notification 5 mins before'),
                    _HowItWorksStep('4', 'App soft-blocked when time is up'),
                    _HowItWorksStep(
                      '5',
                      'Wait 15 mins or earn points to unlock',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String icon;
  final String value;
  final String label;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.7), color],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(icon, style: const TextStyle(fontSize: 30)),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
        ],
      ),
    );
  }
}

class _AppLimitCard extends StatelessWidget {
  final AppLimit app;
  final VoidCallback onStart;
  final VoidCallback onStop;
  final VoidCallback onEdit;
  final String Function(int?) formatTime;

  const _AppLimitCard({
    required this.app,
    required this.onStart,
    required this.onStop,
    required this.onEdit,
    required this.formatTime,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: app.color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(app.icon, style: const TextStyle(fontSize: 28)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            app.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (app.isActive) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Text(
                                'ACTIVE',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        app.isActive
                            ? 'Time remaining: ${formatTime(app.remainingMinutes)}'
                            : 'Limit: ${app.limitMinutes} minutes',
                        style: TextStyle(
                          fontSize: 13,
                          color: app.isActive
                              ? Colors.green
                              : Colors.grey.shade600,
                          fontWeight: app.isActive
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit, color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: app.isActive ? onStop : onStart,
                    icon: Icon(
                      app.isActive ? Icons.stop : Icons.play_arrow,
                      size: 20,
                    ),
                    label: Text(app.isActive ? 'Stop Timer' : 'Start Timer'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: app.isActive ? Colors.red : app.color,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _HowItWorksStep extends StatelessWidget {
  final String number;
  final String text;

  const _HowItWorksStep(this.number, this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: Colors.green,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
            ),
          ),
        ],
      ),
    );
  }
}

class _EditLimitDialog extends StatefulWidget {
  final AppLimit app;
  final Function(int) onSave;

  const _EditLimitDialog({required this.app, required this.onSave});

  @override
  State<_EditLimitDialog> createState() => _EditLimitDialogState();
}

class _EditLimitDialogState extends State<_EditLimitDialog> {
  late int selectedMinutes;

  @override
  void initState() {
    super.initState();
    selectedMinutes = widget.app.limitMinutes;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Set Limit for ${widget.app.name}'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$selectedMinutes minutes',
            style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
          ),
          Slider(
            value: selectedMinutes.toDouble(),
            min: 5,
            max: 180,
            divisions: 35,
            activeColor: widget.app.color,
            onChanged: (value) {
              setState(() {
                selectedMinutes = value.toInt();
              });
            },
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            children: [15, 30, 45, 60, 90, 120].map((mins) {
              return ChoiceChip(
                label: Text('${mins}m'),
                selected: selectedMinutes == mins,
                onSelected: (selected) {
                  if (selected) {
                    setState(() {
                      selectedMinutes = mins;
                    });
                  }
                },
                selectedColor: widget.app.color,
                labelStyle: TextStyle(
                  color: selectedMinutes == mins
                      ? Colors.white
                      : Colors.black87,
                ),
              );
            }).toList(),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            widget.onSave(selectedMinutes);
            Navigator.pop(context);
          },
          style: ElevatedButton.styleFrom(backgroundColor: widget.app.color),
          child: const Text('Save'),
        ),
      ],
    );
  }
}
