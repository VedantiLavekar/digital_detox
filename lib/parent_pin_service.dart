import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert';

/// Service for managing parent PIN authentication
/// Used to protect Kids Mode settings and unlock blocked screens
/// PIN is stored in Firebase Firestore (hashed) and synced across devices
class ParentPinService {
  static const String _pinKey = 'parent_pin_hash';
  static const String _pinSetKey = 'parent_pin_set';

  FirebaseFirestore? get _firestore {
    try {
      return FirebaseFirestore.instance;
    } catch (e) {
      print('⚠️ Firebase not initialized');
      return null;
    }
  }

  FirebaseAuth? get _auth {
    try {
      return FirebaseAuth.instance;
    } catch (e) {
      print('⚠️ Firebase Auth not initialized');
      return null;
    }
  }

  String? get _currentUserId => _auth?.currentUser?.uid;

  /// Return debug information about PIN storage and Firebase state
  Future<Map<String, dynamic>> debugInfo() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'currentUserId': _currentUserId,
      'firestoreAvailable': _firestore != null,
      'localPinHash': prefs.getString(_pinKey),
    };
  }

  /// Check if parent PIN is set (checks Firebase first, then local backup)
  Future<bool> isPinSet() async {
    try {
      // Try Firebase first
      if (_currentUserId != null && _firestore != null) {
        final doc = await _firestore!
            .collection('users')
            .doc(_currentUserId)
            .collection('settings')
            .doc('parent_pin')
            .get();

        if (doc.exists && doc.data()?['pin_hash'] != null) {
          return true;
        }
      }
    } catch (e) {
      print('⚠️ Firebase PIN check failed, checking local: $e');
    }

    // Fallback to local storage
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_pinSetKey) ?? false;
  }

  /// Set parent PIN (hashed for security, stored in Firebase)
  Future<bool> setPin(String pin) async {
    print('🔐 Setting PIN: length=${pin.length}, isNumeric=${_isNumeric(pin)}');

    if (pin.length != 4 || !_isNumeric(pin)) {
      print('❌ Invalid PIN format');
      return false;
    }

    final hash = _hashPin(pin);
    print('🔐 PIN hashed successfully');

    try {
      // Save to Firebase
      if (_currentUserId != null && _firestore != null) {
        print('🔐 Saving PIN to Firebase for user: $_currentUserId');
        await _firestore!
            .collection('users')
            .doc(_currentUserId)
            .collection('settings')
            .doc('parent_pin')
            .set({
              'pin_hash': hash,
              'created_at': FieldValue.serverTimestamp(),
              'updated_at': FieldValue.serverTimestamp(),
            });
        print('✅ Parent PIN saved to Firebase');
      } else {
        print('⚠️ No user logged in, saving only locally');
      }
    } catch (e) {
      print('⚠️ Firebase PIN save failed, saving locally: $e');
    }

    // Also save locally as backup
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_pinKey, hash);
    await prefs.setBool(_pinSetKey, true);

    print('✅ Parent PIN set successfully (hash: ${hash.substring(0, 10)}...)');
    return true;
  }

  /// Verify parent PIN (checks local storage first when in overlay, Firebase otherwise)
  Future<bool> verifyPin(String pin, {bool isOverlay = false}) async {
    print('🔐 Verifying PIN: length=${pin.length}, isOverlay=$isOverlay');

    final inputHash = _hashPin(pin);
    print('🔐 Input PIN hashed: ${inputHash.substring(0, 10)}...');
    String? storedHash;

    // In overlay, skip Firebase entirely and only use local storage
    if (!isOverlay) {
      try {
        // Try Firebase first (only in main app)
        if (_currentUserId != null && _firestore != null) {
          print('🔐 Checking Firebase for user: $_currentUserId');
          final doc = await _firestore!
              .collection('users')
              .doc(_currentUserId)
              .collection('settings')
              .doc('parent_pin')
              .get();

          if (doc.exists) {
            storedHash = doc.data()?['pin_hash'];
            print(
              '🔐 PIN found in Firebase: ${storedHash?.substring(0, 10)}...',
            );

            // Sync to local storage for offline access
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString(_pinKey, storedHash!);
            await prefs.setBool(_pinSetKey, true);
          } else {
            print('⚠️ No PIN document found in Firebase');
          }
        } else {
          print('⚠️ No user logged in');
        }
      } catch (e) {
        print('⚠️ Firebase PIN verification failed, checking local: $e');
      }
    } else {
      print(
        '🔐 Running in overlay - skipping Firebase, using local storage only',
      );
    }

    // Fallback to local storage (or primary for overlay)
    if (storedHash == null) {
      print('🔐 Checking local storage for PIN');
      final prefs = await SharedPreferences.getInstance();
      storedHash = prefs.getString(_pinKey);
      if (storedHash != null) {
        print(
          '🔐 PIN found in local storage: ${storedHash.substring(0, 10)}...',
        );
      } else {
        print('❌ No PIN found in local storage');
      }
    }

    if (storedHash == null) {
      print('❌ No PIN set anywhere');
      return false;
    }

    final isMatch = inputHash == storedHash;
    print('🔐 PIN match result: $isMatch');
    return isMatch;
  }

  /// Change existing PIN (requires old PIN verification)
  Future<bool> changePin(String oldPin, String newPin) async {
    final isOldPinCorrect = await verifyPin(oldPin);

    if (!isOldPinCorrect) {
      return false;
    }

    return await setPin(newPin);
  }

  /// Reset PIN (removes from Firebase and local storage)
  Future<void> resetPin() async {
    try {
      // Remove from Firebase
      if (_currentUserId != null && _firestore != null) {
        await _firestore!
            .collection('users')
            .doc(_currentUserId)
            .collection('settings')
            .doc('parent_pin')
            .delete();
        print('✅ Parent PIN removed from Firebase');
      }
    } catch (e) {
      print('⚠️ Firebase PIN removal failed: $e');
    }

    // Remove from local storage
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_pinKey);
    await prefs.setBool(_pinSetKey, false);
    print('⚠️ Parent PIN reset');
  }

  /// Hash PIN using SHA-256 for security
  String _hashPin(String pin) {
    final bytes = utf8.encode(pin);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Check if string contains only numbers
  bool _isNumeric(String str) {
    return RegExp(r'^[0-9]+$').hasMatch(str);
  }
}
