import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../repositories/auth_repository.dart';

final firebaseAuthProvider = Provider<FirebaseAuth>((_) => FirebaseAuth.instance);
final firestoreProvider = Provider<FirebaseFirestore>((_) => FirebaseFirestore.instance);
final messagingProvider = Provider<FirebaseMessaging>((_) => FirebaseMessaging.instance);
final analyticsClientProvider = Provider<FirebaseAnalytics>((_) => FirebaseAnalytics.instance);
final crashlyticsClientProvider = Provider<FirebaseCrashlytics>((_) => FirebaseCrashlytics.instance);
final storageClientProvider = Provider<FirebaseStorage>((_) => FirebaseStorage.instance);

final googleSignInProvider = Provider<GoogleSignIn>((_) => AuthRepository.buildGoogleSignIn());

/// Set in `main.dart` after `SharedPreferences.getInstance()`.
final sharedPreferencesProvider = Provider<SharedPreferences>((_) {
  throw UnimplementedError('sharedPreferencesProvider must be overridden in main()');
});
