import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Service for managing Firestore database operations
/// All user data is stored in Firebase, not locally in the app
class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Get current user ID
  String? get currentUserId => _auth.currentUser?.uid;

  /// Check if user is logged in
  bool get isLoggedIn => currentUserId != null;

  // ============== DETOX MODE DATA ==============

  /// Save app blocking session to Firestore
  /// Stores which app was blocked, when, and for how long
  Future<bool> saveDetoxSession({
    required String appName,
    required String packageName,
    required int limitMinutes,
    required int usedMinutes,
    required DateTime timestamp,
    String? blockReason,
  }) async {
    try {
      if (!isLoggedIn) return false;

      await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('detoxSessions')
          .add({
            'appName': appName,
            'packageName': packageName,
            'limitMinutes': limitMinutes,
            'usedMinutes': usedMinutes,
            'timestamp': Timestamp.fromDate(timestamp),
            'blockReason': blockReason ?? 'Time limit reached',
            'createdAt': FieldValue.serverTimestamp(),
          });

      print('✅ Detox session saved: $appName');
      return true;
    } catch (e) {
      print('❌ Error saving detox session: $e');
      return false;
    }
  }

  /// Save daily app usage statistics
  Future<bool> saveDailyAppUsage({
    required String appName,
    required String packageName,
    required int usageMinutes,
    required DateTime date,
  }) async {
    try {
      if (!isLoggedIn) return false;

      String dateKey =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

      await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('appUsage')
          .doc(dateKey)
          .set({
            'date': Timestamp.fromDate(date),
            'apps': FieldValue.arrayUnion([
              {
                'appName': appName,
                'packageName': packageName,
                'usageMinutes': usageMinutes,
                'recordedAt': Timestamp.fromDate(DateTime.now()),
              },
            ]),
          }, SetOptions(merge: true));

      return true;
    } catch (e) {
      print('❌ Error saving app usage: $e');
      return false;
    }
  }

  /// Get user's detox sessions history
  Future<List<Map<String, dynamic>>> getDetoxSessions({int? limit}) async {
    try {
      if (!isLoggedIn) return [];

      Query query = _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('detoxSessions')
          .orderBy('timestamp', descending: true);

      if (limit != null) {
        query = query.limit(limit);
      }

      QuerySnapshot snapshot = await query.get();
      return snapshot.docs
          .map((doc) => {...doc.data() as Map<String, dynamic>, 'id': doc.id})
          .toList();
    } catch (e) {
      print('❌ Error fetching detox sessions: $e');
      return [];
    }
  }

  // ============== JOURNAL ENTRIES ==============

  /// Save journal entry to Firestore
  Future<bool> saveJournalEntry({
    required String entry,
    required String mood,
    required DateTime timestamp,
  }) async {
    try {
      if (!isLoggedIn) return false;

      await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('journal')
          .add({
            'entry': entry,
            'mood': mood,
            'timestamp': Timestamp.fromDate(timestamp),
            'createdAt': FieldValue.serverTimestamp(),
          });

      print('✅ Journal entry saved');
      return true;
    } catch (e) {
      print('❌ Error saving journal entry: $e');
      return false;
    }
  }

  /// Get user's journal entries
  Future<List<Map<String, dynamic>>> getJournalEntries({int? limit}) async {
    try {
      if (!isLoggedIn) return [];

      Query query = _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('journal')
          .orderBy('timestamp', descending: true);

      if (limit != null) {
        query = query.limit(limit);
      }

      QuerySnapshot snapshot = await query.get();
      return snapshot.docs
          .map((doc) => {...doc.data() as Map<String, dynamic>, 'id': doc.id})
          .toList();
    } catch (e) {
      print('❌ Error fetching journal entries: $e');
      return [];
    }
  }

  // ============== MOOD TRACKING ==============

  /// Save mood entry to Firestore
  Future<bool> saveMoodEntry({
    required String mood,
    required String note,
    required DateTime timestamp,
  }) async {
    try {
      if (!isLoggedIn) return false;

      await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('moods')
          .add({
            'mood': mood,
            'note': note,
            'timestamp': Timestamp.fromDate(timestamp),
            'createdAt': FieldValue.serverTimestamp(),
          });

      print('✅ Mood entry saved: $mood');
      return true;
    } catch (e) {
      print('❌ Error saving mood entry: $e');
      return false;
    }
  }

  // ============== HEALTHY LIFE SUPPORT ==============

  /// Save sleep schedule to Firestore
  Future<bool> saveSleepSchedule({
    required String bedtime,
    required String wakeTime,
    required DateTime date,
  }) async {
    try {
      if (!isLoggedIn) return false;

      String dateKey =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

      await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('sleepSchedule')
          .doc(dateKey)
          .set({
            'bedtime': bedtime,
            'wakeTime': wakeTime,
            'date': Timestamp.fromDate(date),
            'updatedAt': FieldValue.serverTimestamp(),
          });

      print('✅ Sleep schedule saved');
      return true;
    } catch (e) {
      print('❌ Error saving sleep schedule: $e');
      return false;
    }
  }

  /// Save eating schedule to Firestore
  Future<bool> saveEatingSchedule({
    required List<Map<String, String>> meals,
    required DateTime date,
  }) async {
    try {
      if (!isLoggedIn) return false;

      String dateKey =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

      await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('eatingSchedule')
          .doc(dateKey)
          .set({
            'meals': meals,
            'date': Timestamp.fromDate(date),
            'updatedAt': FieldValue.serverTimestamp(),
          });

      print('✅ Eating schedule saved');
      return true;
    } catch (e) {
      print('❌ Error saving eating schedule: $e');
      return false;
    }
  }

  /// Save healthy habit completion
  Future<bool> saveHabitCompletion({
    required String habitName,
    required bool completed,
    required DateTime date,
  }) async {
    try {
      if (!isLoggedIn) return false;

      String dateKey =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

      await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('habits')
          .doc(dateKey)
          .set({
            'habits': FieldValue.arrayUnion([
              {
                'habitName': habitName,
                'completed': completed,
                'timestamp': Timestamp.fromDate(DateTime.now()),
              },
            ]),
            'date': Timestamp.fromDate(date),
          }, SetOptions(merge: true));

      print('✅ Habit completion saved: $habitName');
      return true;
    } catch (e) {
      print('❌ Error saving habit: $e');
      return false;
    }
  }

  // ============== USER STATISTICS ==============

  /// Get total detox sessions count
  Future<int> getTotalDetoxSessions() async {
    try {
      if (!isLoggedIn) return 0;

      QuerySnapshot snapshot = await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('detoxSessions')
          .get();

      return snapshot.docs.length;
    } catch (e) {
      print('❌ Error getting session count: $e');
      return 0;
    }
  }

  /// Get total blocked minutes across all apps
  Future<int> getTotalBlockedMinutes() async {
    try {
      if (!isLoggedIn) return 0;

      QuerySnapshot snapshot = await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('detoxSessions')
          .get();

      int total = 0;
      for (var doc in snapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        total += (data['usedMinutes'] as int? ?? 0);
      }

      return total;
    } catch (e) {
      print('❌ Error calculating blocked minutes: $e');
      return 0;
    }
  }

  /// Update user profile in Firestore
  Future<bool> updateUserProfile(Map<String, dynamic> updates) async {
    try {
      if (!isLoggedIn) return false;

      await _firestore.collection('users').doc(currentUserId).update(updates);

      print('✅ User profile updated');
      return true;
    } catch (e) {
      print('❌ Error updating profile: $e');
      return false;
    }
  }

  /// Get user profile from Firestore
  Future<Map<String, dynamic>?> getUserProfile() async {
    try {
      if (!isLoggedIn) return null;

      DocumentSnapshot doc = await _firestore
          .collection('users')
          .doc(currentUserId)
          .get();

      if (doc.exists) {
        return doc.data() as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      print('❌ Error fetching user profile: $e');
      return null;
    }
  }
}
