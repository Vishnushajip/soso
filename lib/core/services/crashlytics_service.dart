import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

import '../constants/env.dart';

class CrashlyticsService {
  CrashlyticsService(this._crashlytics);
  final FirebaseCrashlytics _crashlytics;

  Future<void> setUser(String? uid) async {
    if (!Env.enableCrashlytics || kIsWeb) return;
    await _crashlytics.setUserIdentifier(uid ?? '');
  }

  Future<void> record(Object error, StackTrace stack, {String? reason, bool fatal = false}) async {
    if (!Env.enableCrashlytics || kIsWeb) {
      // ignore: avoid_print
      print('Crash captured (disabled/web): $reason\n$error\n$stack');
      return;
    }
    await _crashlytics.recordError(error, stack, reason: reason, fatal: fatal);
  }

  Future<void> log(String message) async {
    if (!Env.enableCrashlytics || kIsWeb) return;
    await _crashlytics.log(message);
  }
}
