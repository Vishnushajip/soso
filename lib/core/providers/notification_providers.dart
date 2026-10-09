import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/notification_model.dart';
import 'auth_providers.dart';
import 'repository_providers.dart';

final notificationsProvider = StreamProvider<List<AppNotification>>((ref) {
  final uid = ref.watch(currentUidProvider);
  if (uid == null) return Stream.value(const []);
  return ref.watch(notificationRepositoryProvider).watchFor(uid);
});

final unreadNotificationsCountProvider = StreamProvider<int>((ref) {
  final uid = ref.watch(currentUidProvider);
  if (uid == null) return Stream.value(0);
  return ref.watch(notificationRepositoryProvider).watchUnreadCount(uid);
});
