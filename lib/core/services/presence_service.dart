import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/widgets.dart';

import '../constants/app_constants.dart';
import '../constants/env.dart';
import '../utils/logger.dart';

/// Production-grade Firestore presence:
/// - sets `isOnline=true` after sign-in and on app resume
/// - heartbeats `lastSeen` every [Env.presenceHeartbeatSeconds]
/// - sets `isOnline=false` on pause / inactive / detached / sign-out
class PresenceService with WidgetsBindingObserver {
  PresenceService(this._firestore);
  final FirebaseFirestore _firestore;

  String? _uid;
  Timer? _heartbeat;

  void start(String uid) {
    if (_uid == uid) return;
    _uid = uid;
    WidgetsBinding.instance.addObserver(this);
    _markOnline();
    _heartbeat?.cancel();
    _heartbeat = Timer.periodic(
      Duration(seconds: Env.presenceHeartbeatSeconds),
      (_) => _touch(),
    );
  }

  Future<void> stop() async {
    _heartbeat?.cancel();
    _heartbeat = null;
    WidgetsBinding.instance.removeObserver(this);
    await _markOffline();
    _uid = null;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        _markOnline();
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        _markOffline();
        break;
    }
  }

  Future<void> _markOnline() async {
    final uid = _uid;
    if (uid == null) return;
    try {
      await _firestore.collection(AppConstants.usersCollection).doc(uid).set({
        'isOnline': true,
        'lastSeen': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      appLogger.d('presence online failed: $e');
    }
  }

  Future<void> _touch() async {
    final uid = _uid;
    if (uid == null) return;
    try {
      await _firestore.collection(AppConstants.usersCollection).doc(uid).set({
        'lastSeen': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      appLogger.d('presence heartbeat failed: $e');
    }
  }

  Future<void> _markOffline() async {
    final uid = _uid;
    if (uid == null) return;
    try {
      await _firestore.collection(AppConstants.usersCollection).doc(uid).set({
        'isOnline': false,
        'lastSeen': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      appLogger.d('presence offline failed: $e');
    }
  }
}
