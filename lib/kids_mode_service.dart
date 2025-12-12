import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'kids_overlay_service.dart';

/// Service for managing Kids Mode timer and state
/// Handles countdown, expiration, and persistent state
/// Timer state is stored in Firebase Firestore and synced across devices
class KidsModeService extends ChangeNotifier {
  static final KidsModeService _instance = KidsModeService._internal();
  factory KidsModeService() => _instance;
  KidsModeService._internal();

  // Keys for SharedPreferences
  static const String _isActiveKey = 'kids_mode_active';
  static const String _totalMinutesKey = 'kids_mode_total_minutes';
  static const String _remainingSecondsKey = 'kids_mode_remaining_seconds';
  static const String _expiryTimeKey = 'kids_mode_expiry_time';

  // State
  bool _isActive = false;
  int _totalMinutes = 0;
  int _remainingSeconds = 0;
  Timer? _countdownTimer;
  DateTime? _expiryTime;

  // Callbacks
  Function? onTimerExpired;
  Function(int)? onTimerTick;

  // Import overlay service
  KidsOverlayService? _overlayService;

  // Firebase
  FirebaseFirestore? get _firestore {
    try {
      return FirebaseFirestore.instance;
    } catch (e) {
      return null;
    }
  }

  FirebaseAuth? get _auth {
    try {
      return FirebaseAuth.instance;
    } catch (e) {
      return null;
    }
  }

  String? get _currentUserId => _auth?.currentUser?.uid;

  // Getters
  bool get isActive => _isActive;
  int get totalMinutes => _totalMinutes;
  int get remainingSeconds => _remainingSeconds;
  int get remainingMinutes => (_remainingSeconds / 60).ceil();
  bool get isExpired => _isActive && _remainingSeconds <= 0;
  String get remainingTimeFormatted {
    final minutes = _remainingSeconds ~/ 60;
    final seconds = _remainingSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  /// Initialize service and restore state
  Future<void> initialize() async {
    await _loadState();

    // Check if user unlocked from overlay
    final prefs = await SharedPreferences.getInstance();
    final wasUnlocked = prefs.getBool('kids_mode_unlocked') ?? false;
    if (wasUnlocked) {
      print('🔓 Kids Mode was unlocked from overlay - stopping');
      await prefs.remove('kids_mode_unlocked');
      await stopKidsMode();
      return;
    }

    if (_isActive && _expiryTime != null) {
      final now = DateTime.now();

      if (now.isBefore(_expiryTime!)) {
        // Timer still running - calculate remaining time based on expiry time
        // This ensures accurate timing even if app was closed/backgrounded
        _remainingSeconds = _expiryTime!.difference(now).inSeconds;
        _startCountdown();
        print('✅ Kids Mode restored: $_remainingSeconds seconds remaining');
        print('📅 Expiry time: $_expiryTime');
      } else {
        // Timer expired while app was closed/backgrounded
        // Show blocking overlay immediately
        print('⏰ Kids Mode timer expired while app was closed');
        _remainingSeconds = 0;

        // Show overlay WITHOUT alarm since this is not a fresh expiry
        _overlayService ??= KidsOverlayService();
        await _overlayService!.showBlockingOverlay(shouldPlayAlarm: false);

        onTimerExpired?.call();
        notifyListeners();
      }
    }
  }

  /// Start Kids Mode with specified duration in minutes
  Future<bool> startKidsMode(int minutes) async {
    if (minutes <= 0) {
      return false;
    }

    _isActive = true;
    _totalMinutes = minutes;
    _remainingSeconds = minutes * 60;
    _expiryTime = DateTime.now().add(Duration(minutes: minutes));

    await _saveState();
    _startCountdown();

    print('✅ Kids Mode started: $minutes minutes');
    notifyListeners();
    return true;
  }

  /// Stop Kids Mode (requires parent PIN verification before calling)
  Future<void> stopKidsMode() async {
    print('⏹️ Stopping Kids Mode...');
    _isActive = false;
    _remainingSeconds = 0;
    _totalMinutes = 0;
    _expiryTime = null;
    _countdownTimer?.cancel();
    _countdownTimer = null;

    await _saveState();

    // Close the overlay if it's showing
    print('🚪 Attempting to close overlay from stopKidsMode...');
    try {
      await FlutterOverlayWindow.closeOverlay();
      print('✅ Overlay closed successfully');
    } catch (e) {
      print('⚠️ Error closing overlay: $e');
    }

    print('✅ Kids Mode stopped completely');
    notifyListeners();
  }

  /// Add extra time (for emergency situations, requires parent PIN)
  Future<void> addExtraTime(int minutes) async {
    if (!_isActive) {
      return;
    }

    _remainingSeconds += minutes * 60;
    _expiryTime = DateTime.now().add(Duration(seconds: _remainingSeconds));

    await _saveState();

    print('➕ Added $minutes minutes to Kids Mode');
    notifyListeners();
  }

  /// Start countdown timer
  void _startCountdown() {
    _countdownTimer?.cancel();

    _countdownTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      // Recalculate based on expiry time to ensure accuracy
      // even if app was suspended/backgrounded
      if (_expiryTime != null) {
        final now = DateTime.now();
        _remainingSeconds = _expiryTime!.difference(now).inSeconds;

        if (_remainingSeconds < 0) {
          _remainingSeconds = 0;
        }
      }

      if (_remainingSeconds > 0) {
        _saveState(); // Persist state
        onTimerTick?.call(_remainingSeconds);
        notifyListeners();
      } else {
        timer.cancel();
        _triggerExpiry();
      }
    });
  }

  /// Trigger timer expiry (only called when timer naturally expires during countdown)
  void _triggerExpiry() async {
    print('🔥🔥🔥 Kids Mode timer expired! 🔥🔥🔥');
    print('📊 _countdownTimer is null: ${_countdownTimer == null}');
    print('📊 _isActive: $_isActive');
    print('📊 _remainingSeconds: $_remainingSeconds');

    // Always show overlay when timer expires during active countdown
    if (_countdownTimer != null || _isActive) {
      print('🚀 Attempting to show blocking overlay...');

      // Show system-wide overlay WITH alarm for fresh timer expiry
      _overlayService ??= KidsOverlayService();

      try {
        await _overlayService!.showBlockingOverlay(shouldPlayAlarm: true);
        print('✅ Overlay shown successfully');
      } catch (e) {
        print('❌ Error showing overlay: $e');
      }

      onTimerExpired?.call();
    } else {
      print('⚠️ Timer expired but no active countdown - skipping overlay');
    }

    notifyListeners();
  }

  /// Save state to Firebase and local storage
  Future<void> _saveState() async {
    try {
      // Save to Firebase
      if (_currentUserId != null && _firestore != null) {
        await _firestore!
            .collection('users')
            .doc(_currentUserId)
            .collection('settings')
            .doc('kids_mode')
            .set({
              'is_active': _isActive,
              'total_minutes': _totalMinutes,
              'remaining_seconds': _remainingSeconds,
              'expiry_time': _expiryTime?.toIso8601String(),
              'updated_at': FieldValue.serverTimestamp(),
            });
        print('✅ Kids Mode state saved to Firebase');
      }
    } catch (e) {
      print('⚠️ Firebase save failed, saving locally: $e');
    }

    // Save to local storage as backup
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isActiveKey, _isActive);
    await prefs.setInt(_totalMinutesKey, _totalMinutes);
    await prefs.setInt(_remainingSecondsKey, _remainingSeconds);

    if (_expiryTime != null) {
      await prefs.setString(_expiryTimeKey, _expiryTime!.toIso8601String());
    } else {
      await prefs.remove(_expiryTimeKey);
    }
  }

  /// Load state from Firebase (with local backup)
  Future<void> _loadState() async {
    try {
      // Try Firebase first
      if (_currentUserId != null && _firestore != null) {
        final doc = await _firestore!
            .collection('users')
            .doc(_currentUserId)
            .collection('settings')
            .doc('kids_mode')
            .get();

        if (doc.exists) {
          final data = doc.data()!;
          _isActive = data['is_active'] ?? false;
          _totalMinutes = data['total_minutes'] ?? 0;
          _remainingSeconds = data['remaining_seconds'] ?? 0;

          final expiryTimeStr = data['expiry_time'];
          if (expiryTimeStr != null) {
            _expiryTime = DateTime.parse(expiryTimeStr);
          }

          print('✅ Kids Mode state loaded from Firebase');

          // Sync to local storage for offline access
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool(_isActiveKey, _isActive);
          await prefs.setInt(_totalMinutesKey, _totalMinutes);
          await prefs.setInt(_remainingSecondsKey, _remainingSeconds);
          if (_expiryTime != null) {
            await prefs.setString(
              _expiryTimeKey,
              _expiryTime!.toIso8601String(),
            );
          }

          return;
        }
      }
    } catch (e) {
      print('⚠️ Firebase load failed, loading from local: $e');
    }

    // Fallback to local storage
    final prefs = await SharedPreferences.getInstance();
    _isActive = prefs.getBool(_isActiveKey) ?? false;
    _totalMinutes = prefs.getInt(_totalMinutesKey) ?? 0;
    _remainingSeconds = prefs.getInt(_remainingSecondsKey) ?? 0;

    final expiryTimeStr = prefs.getString(_expiryTimeKey);
    if (expiryTimeStr != null) {
      _expiryTime = DateTime.parse(expiryTimeStr);
    }
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }
}
