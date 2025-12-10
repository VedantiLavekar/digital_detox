import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:async';
import 'package:usage_stats/usage_stats.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'firestore_service.dart';
import 'parent_pin_service.dart';

const Color kPrimaryColor = Color(0xFF2E9D8A);
const Color kBackgroundColor = Color(0xFFF5F5DC);

// Models
class AppInfo {
  final String packageName;
  final String appName;
  final dynamic icon;

  AppInfo({required this.packageName, required this.appName, this.icon});
}

class DetoxModeNewPage extends StatefulWidget {
  const DetoxModeNewPage({super.key});

  @override
  State<DetoxModeNewPage> createState() => _DetoxModeNewPageState();
}

class _DetoxModeNewPageState extends State<DetoxModeNewPage> {
  bool _hasUsagePermission = false;
  List<AppInfo> _selectedApps = [];
  Map<String, int> _appLimits = {}; // packageName -> minutes
  final Map<String, int> _appUsageToday = {}; // packageName -> minutes used
  final Map<String, bool> _fiveMinWarningShown = {}; // Track if 5-min warning sent
  final Map<String, bool> _twoMinWarningShown = {}; // Track if 2-min warning sent
  Timer? _monitoringTimer;
  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();
  final FirestoreService _firestoreService = FirestoreService();
  final ParentPinService _parentPinService = ParentPinService();

  @override
  void initState() {
    super.initState();
    _initNotifications();
    _checkPermissions();
    _loadSavedData();
  }

  Future<void> _initNotifications() async {
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const initSettings = InitializationSettings(android: androidSettings);
    await _notificationsPlugin.initialize(initSettings);

    // Request notification permission
    await Permission.notification.request();
  }

  Future<void> _showWarningNotification(
    AppInfo app,
    int remainingMinutes,
  ) async {
    const androidDetails = AndroidNotificationDetails(
      'detox_warnings',
      'App Time Warnings',
      channelDescription: 'Warnings when app time limit is approaching',
      importance: Importance.high,
      priority: Priority.high,
    );
    const notificationDetails = NotificationDetails(android: androidDetails);

    await _notificationsPlugin.show(
      app.packageName.hashCode,
      '⏰ ${app.appName} Time Warning',
      'Only $remainingMinutes minutes left! Consider taking a break.',
      notificationDetails,
    );
  }

  Future<void> _showBlockedNotification(AppInfo app) async {
    const androidDetails = AndroidNotificationDetails(
      'detox_blocked',
      'App Blocked',
      channelDescription: 'Notifications when app is blocked',
      importance: Importance.max,
      priority: Priority.max,
    );
    const notificationDetails = NotificationDetails(android: androidDetails);

    await _notificationsPlugin.show(
      app.packageName.hashCode + 1000,
      '🚫 ${app.appName} Blocked',
      'You\'ve reached your daily limit. Time for a digital detox!',
      notificationDetails,
    );
  }

  @override
  void dispose() {
    _monitoringTimer?.cancel();
    super.dispose();
  }

  Future<void> _checkPermissions() async {
    // Check usage stats permission
    final usageStatus = await Permission.appTrackingTransparency.status;
    setState(() {
      _hasUsagePermission = usageStatus.isGranted;
    });

    // Try to check usage stats permission (Android-specific)
    try {
      final granted = await UsageStats.checkUsagePermission();
      setState(() {
        _hasUsagePermission = granted ?? false;
      });
    } catch (e) {
      print('Error checking usage permission: $e');
    }

    if (_hasUsagePermission) {
      _startMonitoring();
    }
  }

  Future<void> _requestPermissions() async {
    try {
      // Request usage stats permission
      await UsageStats.grantUsagePermission();

      // Check if granted
      await Future.delayed(const Duration(milliseconds: 500));
      final granted = await UsageStats.checkUsagePermission();

      if (granted == true) {
        setState(() {
          _hasUsagePermission = true;
        });

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Permission granted! You can now block apps.'),
            backgroundColor: Colors.green,
          ),
        );

        _startMonitoring();
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Permission required to block apps'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('Error requesting permission: $e');
    }
  }

  Future<void> _loadSavedData() async {
    final prefs = await SharedPreferences.getInstance();

    // Load selected apps
    final appsJson = prefs.getString('selectedApps');
    if (appsJson != null) {
      final List<dynamic> appsList = json.decode(appsJson);
      _selectedApps = appsList.map((app) {
        return AppInfo(
          packageName: app['packageName'],
          appName: app['appName'],
          icon: app['icon'],
        );
      }).toList();
    }

    // Load limits
    final limitsJson = prefs.getString('appLimits');
    if (limitsJson != null) {
      _appLimits = Map<String, int>.from(json.decode(limitsJson));
    }

    setState(() {});
  }

  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();

    // Save selected apps
    final appsJson = json.encode(
      _selectedApps
          .map(
            (app) => {
              'packageName': app.packageName,
              'appName': app.appName,
              'icon': app.icon,
            },
          )
          .toList(),
    );
    await prefs.setString('selectedApps', appsJson);

    // Save limits
    await prefs.setString('appLimits', json.encode(_appLimits));
  }

  void _startMonitoring() {
    _monitoringTimer?.cancel();
    // Check every 10 seconds for faster response
    _monitoringTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      _checkAppUsage();
    });
    _checkAppUsage(); // Initial check
  }

  Future<void> _checkAppUsage() async {
    if (!_hasUsagePermission) return;

    try {
      final endDate = DateTime.now();
      final startDate = DateTime(endDate.year, endDate.month, endDate.day);

      final usageStats = await UsageStats.queryUsageStats(startDate, endDate);

      if (usageStats.isEmpty) return;

      for (var app in _selectedApps) {
        final packageName = app.packageName;
        try {
          final usage = usageStats.firstWhere(
            (stat) => stat.packageName == packageName,
          );

          // totalTimeInForeground is String, need to parse it
          final timeStr = usage.totalTimeInForeground ?? '0';
          final usageMillis = int.tryParse(timeStr) ?? 0;
          final usageMinutes = usageMillis ~/ 60000;
          _appUsageToday[packageName] = usageMinutes;

          // Save daily usage to Firestore (runs in background)
          _firestoreService.saveDailyAppUsage(
            appName: app.appName,
            packageName: packageName,
            usageMinutes: usageMinutes,
            date: DateTime.now(),
          );

          // Check if limit exceeded
          final limit = _appLimits[packageName] ?? 0;
          if (limit > 0) {
            final remainingMinutes = limit - usageMinutes;

            // Show 5-minute warning
            if (remainingMinutes == 5 &&
                _fiveMinWarningShown[packageName] != true) {
              _showWarningNotification(app, 5);
              _fiveMinWarningShown[packageName] = true;
            }

            // Show 2-minute warning
            if (remainingMinutes == 2 &&
                _twoMinWarningShown[packageName] != true) {
              _showWarningNotification(app, 2);
              _twoMinWarningShown[packageName] = true;
            }

            // Block app when limit reached
            if (usageMinutes >= limit) {
              _showBlockedNotification(app);
              _blockApp(app);
              // Reset warnings for next day
              _fiveMinWarningShown[packageName] = false;
              _twoMinWarningShown[packageName] = false;
            }
          }
        } catch (e) {
          // App not in usage stats today
          _appUsageToday[packageName] = 0;
        }
      }

      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      print('Error checking app usage: $e');
    }
  }

  void _blockApp(AppInfo app) {
    // Save blocking session to Firestore
    _firestoreService.saveDetoxSession(
      appName: app.appName,
      packageName: app.packageName,
      limitMinutes: _appLimits[app.packageName] ?? 0,
      usedMinutes: _appUsageToday[app.packageName] ?? 0,
      timestamp: DateTime.now(),
      blockReason: 'Daily limit reached',
    );

    // Show blocking overlay with animation
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => WillPopScope(
        onWillPop: () async => false,
        child: Scaffold(
          backgroundColor: Colors.red.shade900,
          body: SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Animated icon
                    TweenAnimationBuilder(
                      duration: const Duration(milliseconds: 500),
                      tween: Tween<double>(begin: 0, end: 1),
                      builder: (context, double value, child) {
                        return Transform.scale(
                          scale: value,
                          child: Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withOpacity(0.2),
                            ),
                            child: Text(
                              app.icon?.toString() ?? '🚫',
                              style: const TextStyle(fontSize: 80),
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 32),
                    Text(
                      '⏰ Time\'s Up!',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Text(
                            app.appName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Daily limit: ${_appLimits[app.packageName]} minutes',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 16,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    Text(
                      '🧘 Time for a digital detox break!\nYour wellbeing matters more.',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 16,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 40),
                    ElevatedButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.check_circle),
                      label: const Text(
                        'Got It!',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.red.shade900,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 40,
                          vertical: 18,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _showPinDialog(app);
                      },
                      icon: const Icon(Icons.lock_open, color: Colors.white70),
                      label: const Text(
                        'Unlock with PIN',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'App will be available again tomorrow',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 12,
                      ),
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

  Future<void> _showPinDialog(AppInfo app) async {
    final pinController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    // Check if PIN is set
    final isPinSet = await _parentPinService.isPinSet();

    if (!mounted) return;

    if (!isPinSet) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ No Parent PIN set. Please set one in Settings.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Unlock App'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Enter Parent PIN to extend time by 15 minutes.'),
            const SizedBox(height: 16),
            Form(
              key: formKey,
              child: TextFormField(
                controller: pinController,
                keyboardType: TextInputType.number,
                obscureText: true,
                maxLength: 4,
                decoration: const InputDecoration(
                  labelText: 'PIN',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock),
                ),
                validator: (value) {
                  if (value == null || value.length != 4) {
                    return 'Enter 4-digit PIN';
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                final success = await _parentPinService.verifyPin(
                  pinController.text,
                );
                
                if (!mounted) return;
                
                if (success) {
                  // Extend time by 15 minutes
                  setState(() {
                    _appLimits[app.packageName] =
                        (_appLimits[app.packageName] ?? 0) + 15;
                  });
                  
                  Navigator.pop(context);
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('✅ Unlocked ${app.appName} for 15 minutes'),
                      backgroundColor: Colors.green,
                    ),
                  );

                  // Go to home screen as requested
                  SystemNavigator.pop();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('❌ Incorrect PIN'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Unlock'),
          ),
        ],
      ),
    );
  }

  Future<void> _selectApps() async {
    if (!mounted) return;

    final selected = await showDialog<List<AppInfo>>(
      context: context,
      builder: (context) => _AppSelectorDialog(
        selectedPackages: _selectedApps.map((a) => a.packageName).toList(),
      ),
    );

    if (selected != null) {
      setState(() {
        _selectedApps = selected;

        // Set default limits
        for (var app in _selectedApps) {
          _appLimits[app.packageName] ??= 30;
        }
      });
      _saveData();
    }
  }

  void _setLimit(AppInfo app) {
    showDialog(
      context: context,
      builder: (context) => _LimitDialog(
        appName: app.appName,
        currentLimit: _appLimits[app.packageName] ?? 30,
        onSave: (minutes) {
          setState(() {
            _appLimits[app.packageName] = minutes;
          });
          _saveData();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        title: const Text(
          'Detox Mode - Real Blocking',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: kPrimaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
        centerTitle: true,
      ),
      body: !_hasUsagePermission
          ? _buildPermissionScreen()
          : _buildMainContent(),
    );
  }

  Widget _buildPermissionScreen() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.security, size: 100, color: Colors.grey.shade400),
            const SizedBox(height: 24),
            const Text(
              'Permission Required',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Text(
              'To block apps when time limits are reached, we need permission to track app usage.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
            ),
            const SizedBox(height: 40),
            ElevatedButton.icon(
              onPressed: _requestPermissions,
              icon: const Icon(Icons.check_circle),
              label: const Text('Grant Permission'),
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Add Apps Button
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            child: InkWell(
              onTap: _selectApps,
              borderRadius: BorderRadius.circular(15),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: kPrimaryColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.add_circle,
                        color: kPrimaryColor,
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Select Apps to Block',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Choose which apps to limit',
                            style: TextStyle(fontSize: 14, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Selected Apps List
          if (_selectedApps.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  'No apps selected yet.\nTap above to select apps to block.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                ),
              ),
            )
          else
            ..._selectedApps.map((app) {
              final limit = _appLimits[app.packageName] ?? 30;
              final used = _appUsageToday[app.packageName] ?? 0;
              final percentage = (used / limit).clamp(0.0, 1.0);
              final isBlocked = used >= limit;

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          // App Icon
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: kPrimaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: Text(
                                app.icon?.toString() ?? '📱',
                                style: const TextStyle(fontSize: 28),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          // App Info
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        app.appName,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    if (isBlocked)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.red,
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: const Text(
                                          'BLOCKED',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.access_time,
                                      size: 16,
                                      color: isBlocked
                                          ? Colors.red
                                          : kPrimaryColor,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Used: ',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey.shade700,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    Text(
                                      '$used min',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: isBlocked
                                            ? Colors.red
                                            : kPrimaryColor,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      ' / $limit min',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                if (!isBlocked)
                                  Text(
                                    '${limit - used} minutes remaining',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.green.shade700,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  )
                                else
                                  Text(
                                    'Time limit exceeded!',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.red.shade700,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          // Edit Button
                          IconButton(
                            onPressed: () => _setLimit(app),
                            icon: const Icon(Icons.edit),
                            color: Colors.grey.shade600,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Progress Bar
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: percentage,
                          minHeight: 8,
                          backgroundColor: Colors.grey.shade200,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            isBlocked ? Colors.red : kPrimaryColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }
}

// App Selector Dialog
class _AppSelectorDialog extends StatefulWidget {
  final List<String> selectedPackages;

  const _AppSelectorDialog({required this.selectedPackages});

  @override
  State<_AppSelectorDialog> createState() => _AppSelectorDialogState();
}

class _AppSelectorDialogState extends State<_AppSelectorDialog> {
  late List<String> _selected;
  String _searchQuery = '';

  // Common distracting apps
  final List<AppInfo> _allApps = [
    AppInfo(
      packageName: 'com.instagram.android',
      appName: 'Instagram',
      icon: '📷',
    ),
    AppInfo(
      packageName: 'com.facebook.katana',
      appName: 'Facebook',
      icon: '👤',
    ),
    AppInfo(
      packageName: 'com.zhiliaoapp.musically',
      appName: 'TikTok',
      icon: '🎵',
    ),
    AppInfo(
      packageName: 'com.snapchat.android',
      appName: 'Snapchat',
      icon: '👻',
    ),
    AppInfo(
      packageName: 'com.twitter.android',
      appName: 'Twitter/X',
      icon: '🐦',
    ),
    AppInfo(packageName: 'com.reddit.frontpage', appName: 'Reddit', icon: '🤖'),
    AppInfo(
      packageName: 'com.google.android.youtube',
      appName: 'YouTube',
      icon: '▶️',
    ),
    AppInfo(packageName: 'com.whatsapp', appName: 'WhatsApp', icon: '💬'),
    AppInfo(
      packageName: 'com.netflix.mediaclient',
      appName: 'Netflix',
      icon: '🎬',
    ),
    AppInfo(packageName: 'com.spotify.music', appName: 'Spotify', icon: '🎧'),
    AppInfo(
      packageName: 'com.amazon.mShop.android.shopping',
      appName: 'Amazon',
      icon: '🛒',
    ),
    AppInfo(packageName: 'com.pinterest', appName: 'Pinterest', icon: '📌'),
    AppInfo(
      packageName: 'com.linkedin.android',
      appName: 'LinkedIn',
      icon: '💼',
    ),
    AppInfo(packageName: 'com.discord', appName: 'Discord', icon: '🎮'),
    AppInfo(
      packageName: 'com.google.android.apps.messaging',
      appName: 'Messages',
      icon: '💬',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _selected = List.from(widget.selectedPackages);
  }

  @override
  Widget build(BuildContext context) {
    final filteredApps = _allApps.where((app) {
      return app.appName.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: kPrimaryColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Column(
              children: [
                const Text(
                  'Select Apps to Block',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                  decoration: InputDecoration(
                    hintText: 'Search apps...',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // App List
          Expanded(
            child: ListView.builder(
              itemCount: filteredApps.length,
              itemBuilder: (context, index) {
                final app = filteredApps[index];
                final isSelected = _selected.contains(app.packageName);

                return CheckboxListTile(
                  value: isSelected,
                  onChanged: (checked) {
                    setState(() {
                      if (checked == true) {
                        _selected.add(app.packageName);
                      } else {
                        _selected.remove(app.packageName);
                      }
                    });
                  },
                  title: Text(app.appName),
                  subtitle: Text(
                    app.packageName,
                    style: const TextStyle(fontSize: 11),
                  ),
                  secondary: Text(
                    app.icon.toString(),
                    style: const TextStyle(fontSize: 32),
                  ),
                );
              },
            ),
          ),
          // Actions
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      final selectedApps = _allApps
                          .where((app) => _selected.contains(app.packageName))
                          .toList();
                      Navigator.pop(context, selectedApps);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kPrimaryColor,
                    ),
                    child: Text('Done (${_selected.length})'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Limit Dialog
class _LimitDialog extends StatefulWidget {
  final String appName;
  final int currentLimit;
  final Function(int) onSave;

  const _LimitDialog({
    required this.appName,
    required this.currentLimit,
    required this.onSave,
  });

  @override
  State<_LimitDialog> createState() => _LimitDialogState();
}

class _LimitDialogState extends State<_LimitDialog> {
  late int _selectedMinutes;

  @override
  void initState() {
    super.initState();
    _selectedMinutes = widget.currentLimit;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Set Limit for ${widget.appName}'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: kPrimaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Text(
                  '$_selectedMinutes',
                  style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: kPrimaryColor,
                  ),
                ),
                Text(
                  'minutes per day',
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Testing Options',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [1, 2, 5].map((mins) {
              return ChoiceChip(
                label: Text('${mins}m TEST'),
                selected: _selectedMinutes == mins,
                onSelected: (selected) {
                  if (selected) {
                    setState(() {
                      _selectedMinutes = mins;
                    });
                  }
                },
                selectedColor: Colors.orange,
                backgroundColor: Colors.orange.shade50,
                labelStyle: TextStyle(
                  color: _selectedMinutes == mins
                      ? Colors.white
                      : Colors.orange.shade700,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          Text(
            'Common Limits',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [15, 30, 45, 60, 90, 120].map((mins) {
              return ChoiceChip(
                label: Text('${mins}m'),
                selected: _selectedMinutes == mins,
                onSelected: (selected) {
                  if (selected) {
                    setState(() {
                      _selectedMinutes = mins;
                    });
                  }
                },
                selectedColor: kPrimaryColor,
                labelStyle: TextStyle(
                  color: _selectedMinutes == mins
                      ? Colors.white
                      : Colors.black87,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          Slider(
            value: _selectedMinutes.toDouble(),
            min: 1,
            max: 180,
            divisions: 179,
            activeColor: kPrimaryColor,
            label: '$_selectedMinutes min',
            onChanged: (value) {
              setState(() {
                _selectedMinutes = value.toInt();
              });
            },
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
            widget.onSave(_selectedMinutes);
            Navigator.pop(context);
          },
          style: ElevatedButton.styleFrom(backgroundColor: kPrimaryColor),
          child: const Text('Save'),
        ),
      ],
    );
  }
}
