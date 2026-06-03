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

final roomMessagesProvider = StreamProvider.family<List<Message>, String>(
  (ref, roomId) => ref.watch(chatRepositoryProvider).watchMessages(roomId),
);

final activeChatRoomIdProvider = StateProvider<String?>((ref) => null);
