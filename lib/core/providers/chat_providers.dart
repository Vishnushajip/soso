import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/chat_room.dart';
import '../models/message.dart';
import 'auth_providers.dart';
import 'repository_providers.dart';

final myChatRoomsProvider = StreamProvider<List<ChatRoom>>((ref) {
  final uid = ref.watch(currentUidProvider);
  if (uid == null) return Stream.value(const []);
  return ref.watch(chatRepositoryProvider).watchMyRooms(uid);
});

// autoDispose so the messages subscription is cancelled when no screen is
// listening (e.g. after leaving a match/chat), preventing late stream emits
// from rebuilding a disposed element ("defunct element" assertion).
final roomMessagesProvider =
    StreamProvider.autoDispose.family<List<Message>, String>(
  (ref, roomId) => ref.watch(chatRepositoryProvider).watchMessages(roomId),
);

final activeChatRoomIdProvider = StateProvider<String?>((ref) => null);

final unreadMessagesCountProvider = Provider<int>((ref) {
  final uid = ref.watch(currentUidProvider);
  if (uid == null) return 0;
  final rooms = ref.watch(myChatRoomsProvider).valueOrNull ?? const [];
  int count = 0;
  for (final r in rooms) {
    if (r.type == ChatRoomType.direct) {
      count += (r.unreadCount[uid] ?? 0);
    }
  }
  return count;
});

