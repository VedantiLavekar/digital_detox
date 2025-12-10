import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class AuthBypass {
  static Future<UserCredential?> createUserBypass({
    required String email,
    required String password,
    required Map<String, dynamic> userData,
  }) async {
    try {
      final auth = FirebaseAuth.instance;

      await auth.setSettings(
        appVerificationDisabledForTesting: true,
        userAccessGroup: null,
      );

      UserCredential userCredential = await auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user!.uid)
          .set(userData);

      if (kDebugMode) {
        print('User created successfully: ${userCredential.user!.email}');
      }

      return userCredential;
    } catch (e) {
      if (kDebugMode) {
        print('Bypass auth error: $e');
      }

      try {
        return await _createUserViaAnonymousLink(email, password, userData);
      } catch (linkError) {
        if (kDebugMode) {
          print('Anonymous link failed: $linkError');
        }
        rethrow;
      }
    }
  }

  static Future<UserCredential> _createUserViaAnonymousLink(
    String email,
    String password,
    Map<String, dynamic> userData,
  ) async {
    final auth = FirebaseAuth.instance;

    // Create anonymous user first
    UserCredential anonCredential = await auth.signInAnonymously();

    // Link with email/password
    AuthCredential emailCredential = EmailAuthProvider.credential(
      email: email,
      password: password,
    );

    UserCredential linkedCredential = await anonCredential.user!
        .linkWithCredential(emailCredential);

    // Save user data
    await FirebaseFirestore.instance
        .collection('users')
        .doc(linkedCredential.user!.uid)
        .set(userData);

    return linkedCredential;
  }
}
