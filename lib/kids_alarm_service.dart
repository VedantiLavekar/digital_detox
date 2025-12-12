import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';

/// Service for playing alarm sound when Kids Mode timer expires
class KidsAlarmService {
  static final KidsAlarmService _instance = KidsAlarmService._internal();
  factory KidsAlarmService() => _instance;
  KidsAlarmService._internal();

  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;

  /// Play alarm sound on repeat
  Future<void> playAlarm() async {
    if (_isPlaying) return;

    try {
      _isPlaying = true;

      // Try to play alarm sound from assets
      try {
        await _audioPlayer.setVolume(1.0);
        await _audioPlayer.setReleaseMode(ReleaseMode.loop);
        await _audioPlayer.play(AssetSource('sounds/alarm_alert.mp3.mp3'), volume: 1.0);
        print('🔔 Alarm sound started from assets');
      } catch (assetError) {
        print('⚠️ Asset alarm not found: $assetError');
        // Fallback to URL-based alarm sound
        try {
          await _audioPlayer.play(
            UrlSource(
              'https://actions.google.com/sounds/v1/alarms/beep_short.ogg',
            ),
            volume: 1.0,
          );
          print('🔔 Alarm started from URL');
        } catch (urlError) {
          print('⚠️ URL alarm failed: $urlError');
          // Final fallback: continuous vibration
          _vibrate();
          print('📳 Using vibration as alarm');
        }
      }
    } catch (e) {
      print('❌ Error playing alarm: $e');
      _vibrate();
    }
  }

  /// Stop alarm sound
  Future<void> stopAlarm() async {
    if (!_isPlaying) return;

    try {
      await _audioPlayer.stop();
      _isPlaying = false;
      print('🔕 Alarm stopped');
    } catch (e) {
      print('❌ Error stopping alarm: $e');
    }
  }

  /// Pause alarm
  Future<void> pauseAlarm() async {
    try {
      await _audioPlayer.pause();
      print('⏸️ Alarm paused');
    } catch (e) {
      print('❌ Error pausing alarm: $e');
    }
  }

  /// Resume alarm
  Future<void> resumeAlarm() async {
    try {
      await _audioPlayer.resume();
      print('▶️ Alarm resumed');
    } catch (e) {
      print('❌ Error resuming alarm: $e');
    }
  }

  /// Vibrate device (as backup when audio fails)
  void _vibrate() {
    try {
      HapticFeedback.heavyImpact();
      Future.delayed(Duration(milliseconds: 500), () {
        if (_isPlaying) {
          HapticFeedback.heavyImpact();
          _vibrate(); // Repeat
        }
      });
    } catch (e) {
      print('❌ Error vibrating: $e');
    }
  }

  /// Check if alarm is currently playing
  bool get isPlaying => _isPlaying;

  /// Dispose audio player
  void dispose() {
    _audioPlayer.dispose();
  }
}
