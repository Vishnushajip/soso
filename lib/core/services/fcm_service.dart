import 'dart:async';
import 'dart:io' show Platform;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/app_constants.dart';
import '../utils/logger.dart';
import 'local_notifications_service.dart';

class FcmService {
  FcmService({
    required FirebaseMessaging messaging,
    required FirebaseFirestore firestore,
    required SharedPreferences prefs,
    required LocalNotificationsService localNotifications,
  })  : _messaging = messaging,
        _firestore = firestore,
        _prefs = prefs,
        _localNotifications = localNotifications;

  final FirebaseMessaging _messaging;
  final FirebaseFirestore _firestore;
  final SharedPreferences _prefs;
  final LocalNotificationsService _localNotifications;

  final _foreground = StreamController<RemoteMessage>.broadcast();
  Stream<RemoteMessage> get onForegroundMessage => _foreground.stream;
  StreamSubscription<RemoteMessage>? _fgSub;
  StreamSubscription<String>? _refreshSub;

  Future<void> init() async {
    try {
      await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      // Show foreground iOS notifications via system.
      await _messaging.setForegroundNotificationPresentationOptions(
        alert: true, badge: true, sound: true,
      );

      _fgSub = FirebaseMessaging.onMessage.listen((msg) {
        _foreground.add(msg);
        final n = msg.notification;
        if (n != null) {
          _localNotifications.show(
            title: n.title ?? AppConstants.fcmChannelName,
            body: n.body ?? '',
            payload: msg.data.toString(),
          );
        }
      });
    } catch (e) {
      appLogger.w('FCM init failed: $e');
    }
  }

  /// Ensure the active user's `fcmToken` / `platform` / `lastTokenUpdate`
  /// are up-to-date in Firestore, writing ONLY when the token changes.
  Future<void> syncTokenForUser(String uid) async {
    try {
      final token = await _messaging.getToken();
      if (token == null || token.isEmpty) return;

      final lastToken = _prefs.getString(AppConstants.prefsLastFcmToken);
      if (lastToken == token) return; // No change — skip Firestore write.

      await _firestore.collection(AppConstants.usersCollection).doc(uid).set({
        'fcmToken': token,
        'platform': _platformName(),
        'lastTokenUpdate': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      await _prefs.setString(AppConstants.prefsLastFcmToken, token);

      _refreshSub?.cancel();
      _refreshSub = _messaging.onTokenRefresh.listen((newToken) async {
        if (_prefs.getString(AppConstants.prefsLastFcmToken) == newToken) return;
        await _firestore.collection(AppConstants.usersCollection).doc(uid).set({
          'fcmToken': newToken,
          'platform': _platformName(),
          'lastTokenUpdate': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        await _prefs.setString(AppConstants.prefsLastFcmToken, newToken);
      });
    } catch (e) {
      appLogger.w('FCM sync failed: $e');
    }
  }

  Future<void> clearTokenForUser(String uid) async {
    try {
      await _firestore.collection(AppConstants.usersCollection).doc(uid).set({
        'fcmToken': FieldValue.delete(),
      }, SetOptions(merge: true));
      await _prefs.remove(AppConstants.prefsLastFcmToken);
    } catch (_) {}
  }

  String _platformName() {
    if (kIsWeb) return 'web';
    try {
      if (Platform.isAndroid) return 'android';
      if (Platform.isIOS) return 'ios';
      if (Platform.isMacOS) return 'macos';
      if (Platform.isWindows) return 'windows';
      if (Platform.isLinux) return 'linux';
    } catch (_) {}
    return 'unknown';
  }

  Future<void> dispose() async {
    await _fgSub?.cancel();
    await _refreshSub?.cancel();
    await _foreground.close();
  }
}
