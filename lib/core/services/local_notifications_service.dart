import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../constants/app_constants.dart';
import '../utils/logger.dart';

class LocalNotificationsService {
  LocalNotificationsService();
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  final StreamController<String?> _clicks = StreamController<String?>.broadcast();
  Stream<String?> get onClickResponse => _clicks.stream;

  Future<void> init() async {
    if (kIsWeb) return;
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    try {
      await _plugin.initialize(
        const InitializationSettings(android: android, iOS: ios),
        onDidReceiveNotificationResponse: (details) {
          _clicks.add(details.payload);
        },
      );

      const channel = AndroidNotificationChannel(
        AppConstants.fcmChannelId,
        AppConstants.fcmChannelName,
        description: AppConstants.fcmChannelDescription,
        importance: Importance.max,
        sound: RawResourceAndroidNotificationSound('notify'),
        playSound: true,
      );
      await _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.createNotificationChannel(channel);
    } catch (e) {
      appLogger.w('LocalNotifications init failed: $e');
    }
  }

  Future<void> show({
    required String title,
    required String body,
    String? payload,
  }) async {
    if (kIsWeb) return;
    const notif = NotificationDetails(
      android: AndroidNotificationDetails(
        AppConstants.fcmChannelId,
        AppConstants.fcmChannelName,
        channelDescription: AppConstants.fcmChannelDescription,
        importance: Importance.max,
        priority: Priority.max,
        sound: RawResourceAndroidNotificationSound('notify'),
        playSound: true,
      ),
      iOS: DarwinNotificationDetails(
        presentSound: true,
        sound: 'notify.mp3',
      ),
    );
    await _plugin.show(
      DateTime.now().millisecondsSinceEpoch.remainder(1 << 31),
      title,
      body,
      notif,
      payload: payload,
    );
  }
}
