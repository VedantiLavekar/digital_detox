// TTS Service - Disabled (flutter_tts package removed)
import 'package:shared_preferences/shared_preferences.dart';

class TTSService {
  static final TTSService _instance = TTSService._internal();
  factory TTSService() => _instance;
  TTSService._internal();

  bool _isInitialized = false;

  // Voice settings
  bool _isVoiceEnabled = true;
  double _speechRate = 0.5;
  double _volume = 0.8;
  double _pitch = 1.0;
  String _language = 'en-US';

  // Initialize TTS (disabled)
  Future<void> initialize() async {
    if (_isInitialized) return;
    await _loadSettings();
    _isInitialized = true;
  }

  // Load settings from SharedPreferences
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _isVoiceEnabled = prefs.getBool('voice_enabled') ?? true;
    _speechRate = prefs.getDouble('speech_rate') ?? 0.5;
    _volume = prefs.getDouble('voice_volume') ?? 0.8;
    _pitch = prefs.getDouble('voice_pitch') ?? 1.0;
    _language = prefs.getString('voice_language') ?? 'en-US';
  }

  // Save settings to SharedPreferences
  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('voice_enabled', _isVoiceEnabled);
    await prefs.setDouble('speech_rate', _speechRate);
    await prefs.setDouble('voice_volume', _volume);
    await prefs.setDouble('voice_pitch', _pitch);
    await prefs.setString('voice_language', _language);
  }

  // Speak text (disabled - no actual speech)
  Future<void> speak(String text) async {
    if (!_isInitialized) await initialize();
    if (!_isVoiceEnabled) return;
    // TTS disabled - no speech output
  }

  // Stop speaking (disabled)
  Future<void> stop() async {
    if (!_isInitialized) return;
    // TTS disabled - no action needed
  }

  // Pause speaking (disabled)
  Future<void> pause() async {
    if (!_isInitialized) return;
    // TTS disabled - no action needed
  }

  // Getters
  bool get isVoiceEnabled => _isVoiceEnabled;
  double get speechRate => _speechRate;
  double get volume => _volume;
  double get pitch => _pitch;
  String get language => _language;

  // Setters with persistence
  Future<void> setVoiceEnabled(bool enabled) async {
    _isVoiceEnabled = enabled;
    await _saveSettings();
  }

  Future<void> setSpeechRate(double rate) async {
    _speechRate = rate;
    await _saveSettings();
  }

  Future<void> setVolume(double volume) async {
    _volume = volume;
    await _saveSettings();
  }

  Future<void> setPitch(double pitch) async {
    _pitch = pitch;
    await _saveSettings();
  }

  Future<void> setLanguage(String language) async {
    _language = language;
    await _saveSettings();
  }

  // Meditation-specific voice instructions (disabled - no actual speech)
  Future<void> speakBreathingInstruction(
    String pattern,
    String phase,
    int duration,
  ) async {
    // TTS disabled - no speech output
    // This method exists for compatibility but does nothing
  }

  // Get available voices/languages (disabled)
  Future<List<dynamic>> getLanguages() async {
    if (!_isInitialized) await initialize();
    return []; // TTS disabled - no languages available
  }

  // Cleanup (disabled)
  void dispose() {
    // TTS disabled - no cleanup needed
  }
}
