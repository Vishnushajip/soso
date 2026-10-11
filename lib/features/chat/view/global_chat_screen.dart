import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_loader.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/guest_google_prompt_dialog.dart';
import '../../../core/models/chat_room.dart';
import '../../../core/providers/chat_providers.dart';
import '../../../core/providers/repository_providers.dart';
import '../../../core/providers/user_providers.dart';
import '../widgets/message_bubble.dart';

class GlobalChatScreen extends ConsumerStatefulWidget {
  const GlobalChatScreen({super.key});
  @override
  ConsumerState<GlobalChatScreen> createState() => _GlobalChatScreenState();
}

class _GlobalChatScreenState extends ConsumerState<GlobalChatScreen> {
  final _ctrl = TextEditingController();
  ChatRoom? _room;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _room = await ref.read(chatRepositoryProvider).ensureGlobalRoom();
      if (mounted) setState(() {});
    });
  }

  Future<void> _send() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty || _room == null) return;
    if (!GuestGooglePromptDialog.allowAction(
      context,
      ref,
      feature: 'Global Chat',
      description:
          'Guest accounts cannot chat. Sign in with Google to participate in global chat!',
    )) {
      return;
    }
    final me = ref.read(currentUserProvider).valueOrNull;
    if (me == null) return;
    _ctrl.clear();
    await ref.read(chatRepositoryProvider).sendMessage(
          room: _room!, senderId: me.uid, senderName: me.name,
          senderPhoto: me.photoUrl, text: text,
        );
  }

  @override
  Widget build(BuildContext context) {
    final messages = _room == null
        ? const AsyncValue.loading()
        : ref.watch(roomMessagesProvider(_room!.id));
    final me = ref.watch(currentUserProvider).valueOrNull;

    return Scaffold(
      appBar: AppBar(title: const Text('Global Chat')),
      body: Column(
        children: [
          Expanded(
            child: messages.when(
              loading: () => const AppLoader(),
              error: (e, _) => ErrorView(message: '$e'),
              data: (list) => ListView.builder(
                reverse: true,
                itemCount: list.length,
                itemBuilder: (_, i) {
                  final m = list[list.length - 1 - i];
                  return MessageBubble(message: m, mine: m.senderId == me?.uid);
                },
              ),
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
                      onSubmitted: (_) => _send(),
                      decoration: const InputDecoration(hintText: 'Say something to everyone…'),
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
