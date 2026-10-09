import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/friend_request.dart';
import '../models/friendship.dart';
import 'auth_providers.dart';
import 'repository_providers.dart';

final incomingRequestsProvider = StreamProvider<List<FriendRequest>>((ref) {
  final uid = ref.watch(currentUidProvider);
  if (uid == null) return Stream.value(const []);
  return ref.watch(friendRepositoryProvider).watchIncoming(uid);
});

final outgoingRequestsProvider = StreamProvider<List<FriendRequest>>((ref) {
  final uid = ref.watch(currentUidProvider);
  if (uid == null) return Stream.value(const []);
  return ref.watch(friendRepositoryProvider).watchOutgoing(uid);
});

final friendshipsProvider = StreamProvider<List<Friendship>>((ref) {
  final uid = ref.watch(currentUidProvider);
  if (uid == null) return Stream.value(const []);
  return ref.watch(friendRepositoryProvider).watchFriends(uid);
});
