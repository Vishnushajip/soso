import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../core/constants/env.dart';
import '../core/utils/logger.dart';

class AuthRepository {
  AuthRepository(this._auth, this._google);
  final FirebaseAuth _auth;
  final GoogleSignIn _google;

  Stream<User?> get authStateChanges => _auth.userChanges();
  User? get currentUser => _auth.currentUser;

  /// Returns `null` if the user cancelled the picker. Throws [AuthException]
  /// for any real failure with a user-friendly message attached.
  Future<UserCredential?> signInWithGoogle() async {
    try {
      if (kIsWeb) {
        final provider = GoogleAuthProvider()..addScope('email');
        return await _auth.signInWithPopup(provider);
      }

      final account = await _google.signIn();
      if (account == null) return null;

      final tokens = await account.authentication;
      if (tokens.idToken == null) {
        throw const AuthException(
          'no-id-token',
          'Google returned no ID token. Check that your Android SHA-1 fingerprint '
              'is registered in Firebase Console and the OAuth web client ID '
              'matches GOOGLE_SERVER_CLIENT_ID in .env.',
        );
      }
      final credential = GoogleAuthProvider.credential(
        idToken: tokens.idToken,
        accessToken: tokens.accessToken,
      );
      return await _auth.signInWithCredential(credential);
    } on PlatformException catch (e, s) {
      appLogger.w(
        'Google sign-in PlatformException: ${e.code} / ${e.message}\n$s',
      );
      throw AuthException(e.code, _decodePlatformError(e));
    } on FirebaseAuthException catch (e, s) {
      appLogger.w('FirebaseAuth ${e.code}: ${e.message}\n$s');
      throw AuthException(e.code, e.message ?? 'Authentication failed.');
    } catch (e, s) {
      appLogger.e('Unexpected sign-in error', error: e, stackTrace: s);
      throw const AuthException(
        'unknown',
        'Something went wrong. Please try again.',
      );
    }
  }

  String _decodePlatformError(PlatformException e) {
    final raw = '${e.message ?? ''} ${e.details ?? ''}';
    if (raw.contains('ApiException: 10')) {
      return 'Google sign-in is not configured for this build. Add your '
          'app\'s SHA-1 fingerprint to Firebase Console, re-download '
          'google-services.json, and rebuild.';
    }
    if (raw.contains('ApiException: 7') || e.code == 'network_error') {
      return 'No internet connection. Check your network and try again.';
    }
    if (raw.contains('ApiException: 12501') || e.code == 'sign_in_canceled') {
      return 'Sign-in cancelled.';
    }
    if (raw.contains('ApiException: 12502')) {
      return 'A sign-in is already in progress. Please wait.';
    }
    if (raw.contains('ApiException: null') || e.code == 'sign_in_failed') {
      return 'Google Play Services could not complete sign-in. Make sure '
          'Play Services is up to date and your SHA-1 is registered in '
          'Firebase Console for this app.';
    }
    return e.message ?? 'Sign-in failed.';
  }

  Future<void> signOut() async {
    try {
      if (!kIsWeb) {
        try {
          await _google.signOut();
        } catch (_) {}
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
      serverClientId: kIsWeb
          ? null
          : (serverClientId.isEmpty ? null : serverClientId),
    );
  }
}

class AuthException implements Exception {
  const AuthException(this.code, this.message);
  final String code;
  final String message;
  @override
  String toString() => message;
}
