import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_loader.dart';
import '../../../core/widgets/error_view.dart';
import '../../../models/chat_room.dart';
import '../../../providers/chat_providers.dart';
import '../../../providers/repository_providers.dart';
import '../../../providers/user_providers.dart';
import '../widgets/message_bubble.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key, required this.roomId});
  final String roomId;
  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _ctrl = TextEditingController();
  ChatRoom? _room;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadRoom());
  }

  Future<void> _loadRoom() async {
    try {
      // Try to read the doc directly to support both direct chats and globalChat.
      final doc = await FirebaseFirestore.instance
          .collection(AppConstants.chatRoomsCollection)
          .doc(widget.roomId)
          .get();
      if (!doc.exists) return;
      setState(() => _room = ChatRoom.fromDoc(doc));
      final me = ref.read(currentUserProvider).valueOrNull;
      if (me != null) {
        await ref.read(chatRepositoryProvider).markRead(roomId: widget.roomId, uid: me.uid);
      }
    } catch (_) {}
  }

  Future<void> _send() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty || _room == null) return;
    final me = ref.read(currentUserProvider).valueOrNull;
    if (me == null) return;
    _ctrl.clear();
    try {
      await ref.read(chatRepositoryProvider).sendMessage(
            room: _room!, senderId: me.uid, senderName: me.name,
            senderPhoto: me.photoUrl, text: text,
          );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final asyncMessages = ref.watch(roomMessagesProvider(widget.roomId));
    final me = ref.watch(currentUserProvider).valueOrNull;

    return Scaffold(
      appBar: AppBar(title: const Text('Chat')),
      body: Column(
        children: [
          Expanded(
            child: asyncMessages.when(
              loading: () => const AppLoader(),
              error: (e, _) => ErrorView(message: '$e'),
              data: (messages) {
                if (messages.isEmpty) {
                  return const Center(
                    child: Text(
                      'No messages yet — say hi 👋',
                      style: TextStyle(color: AppColors.onSurfaceMuted),
                    ),
                  );
                }
                return ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  itemCount: messages.length,
                  itemBuilder: (_, i) {
                    final m = messages[messages.length - 1 - i];
                    return MessageBubble(message: m, mine: m.senderId == me?.uid);
                  },
                );
              },
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _ctrl,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _send(),
                      decoration: const InputDecoration(hintText: 'Type a message…'),
                    ),
                  ),
                  IconButton(
                    onPressed: _send,
                    icon: const Icon(Icons.send, color: AppColors.sColor),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
