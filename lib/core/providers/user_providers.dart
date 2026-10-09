import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/app_user.dart';
import 'auth_providers.dart';
import 'repository_providers.dart';

final currentUserProvider = StreamProvider<AppUser?>((ref) {
  final uid = ref.watch(currentUidProvider);
  if (uid == null) return Stream.value(null);
  return ref.watch(userRepositoryProvider).watchUser(uid);
});

final userByUidProvider = StreamProvider.family<AppUser?, String>(
  (ref, uid) => ref.watch(userRepositoryProvider).watchUser(uid),
);

final onlineCountProvider = FutureProvider<int>((ref) async {
  final repo = ref.watch(userRepositoryProvider);
  final count = await repo.getOnlineUsersCount();

  
  ref.keepAlive();
  final timer = Timer(const Duration(seconds: 30), () {
    ref.invalidateSelf();
  });
  ref.onDispose(timer.cancel);

  return count;
});
