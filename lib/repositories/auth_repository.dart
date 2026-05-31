import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../core/constants/env.dart';
import '../core/utils/logger.dart';

class AuthRepository {
  AuthRepository(this._auth, this._google);
  final FirebaseAuth _auth;
  final GoogleSignIn _google;

  Stream<User?> get authStateChanges => _auth.userChanges();
  User? get currentUser => _auth.currentUser;

  Future<UserCredential> signInWithGoogle() async {
    if (kIsWeb) {
      final provider = GoogleAuthProvider()..addScope('email');
      return _auth.signInWithPopup(provider);
    }
    final account = await _google.signIn();
    if (account == null) {
      throw FirebaseAuthException(code: 'cancelled', message: 'Sign-in cancelled');
    }
    final tokens = await account.authentication;
    final credential = GoogleAuthProvider.credential(
      idToken: tokens.idToken,
      accessToken: tokens.accessToken,
    );
    return _auth.signInWithCredential(credential);
  }

  Future<void> signOut() async {
    try {
      if (!kIsWeb) {
        try { await _google.signOut(); } catch (_) {}
      }
      await _auth.signOut();
    } catch (e, s) {
      appLogger.w('signOut failed: $e\n$s');
      rethrow;
    }
  }

  static GoogleSignIn buildGoogleSignIn() {
    final serverClientId = Env.googleServerClientId;
    return GoogleSignIn(
      scopes: const ['email', 'profile'],
      // On Android serverClientId is used to mint an ID token usable by Firebase Auth.
      // On Web you should configure the meta tag in index.html, the package picks it up automatically.
      serverClientId: kIsWeb ? null : (serverClientId.isEmpty ? null : serverClientId),
    );
  }
}
