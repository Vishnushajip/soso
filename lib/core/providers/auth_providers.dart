import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../utils/logger.dart';
import 'firebase_providers.dart';
import 'repository_providers.dart';
import 'service_providers.dart';

/// Stream of the current Firebase user (or null).
final authStateProvider = StreamProvider<fb_auth.User?>(
  (ref) => ref.watch(authRepositoryProvider).authStateChanges,
);

/// Convenience: the current uid (or null).
final currentUidProvider = Provider<String?>(
  (ref) => ref.watch(authStateProvider).valueOrNull?.uid,
);

/// Imperative actions for sign-in / sign-out screens.
class AuthController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> signInWithGoogle() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(authRepositoryProvider);
      final cred = await repo.signInWithGoogle();
      if (cred == null) return;
      final user = cred.user;
      if (user != null) {
        await ref.read(userRepositoryProvider).ensureUserFromAuth(user);
        await ref.read(analyticsServiceProvider).log('sign_in', {'method': 'google'});
        final isNewUser = cred.additionalUserInfo?.isNewUser == true;
        await ref.read(trackingServiceProvider).googleSignIn(isNewUser: isNewUser);
      }
    });
  }

  Future<void> signInAsGuest() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(authRepositoryProvider);
      final prefs = ref.read(sharedPreferencesProvider);
      final cred = await repo.signInAsGuest(prefs: prefs);
      if (cred == null) return;
      final user = cred.user;
      if (user != null) {
        await ref.read(userRepositoryProvider).ensureUserFromAuth(user, isGuest: true);
        await ref.read(analyticsServiceProvider).log('sign_in', {'method': 'guest'});
        await ref.read(trackingServiceProvider).guestStart();
      }
    });
  }

  Future<void> signOut() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final uid = ref.read(currentUidProvider);
      if (uid != null) {
        await ref.read(fcmServiceProvider).clearTokenForUser(uid);
        await ref.read(presenceServiceProvider).stop();
      }
      await ref.read(authRepositoryProvider).signOut();
      appLogger.i('signed out');
    });
  }
}

final authControllerProvider = AsyncNotifierProvider<AuthController, void>(
  AuthController.new,
);
