import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_loader.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/user_avatar.dart';
import '../../../models/chat_room.dart';
import '../../../providers/chat_providers.dart';
import '../../../providers/repository_providers.dart';
import '../../../providers/user_providers.dart';
import '../widgets/message_bubble.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key, required this.roomId, this.autoSend});
  final String roomId;
  final String? autoSend;
  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _ctrl = TextEditingController();
  ChatRoom? _room;
  // Captured up-front so it can be cleared in dispose() — `ref` itself must not
  // be used after the widget is disposed.
  StateController<String?>? _activeRoomCtrl;

  @override
  void initState() {
    super.initState();
    _activeRoomCtrl = ref.read(activeChatRoomIdProvider.notifier);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _activeRoomCtrl?.state = widget.roomId;
      _loadRoom();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    // Defer clearing the active room: modifying a provider synchronously during
    // dispose happens while the widget tree is building, which Riverpod forbids.
    // The provider is global (not autoDispose) so the controller outlives us.
    final ctrl = _activeRoomCtrl;
    Future(() => ctrl?.state = null);
    super.dispose();
  }

  Future<void> _loadRoom() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection(AppConstants.chatRoomsCollection)
          .doc(widget.roomId)
          .get();
      if (!doc.exists) return;
      setState(() => _room = ChatRoom.fromDoc(doc));
      final me = ref.read(currentUserProvider).valueOrNull;
      if (me != null) {
        await ref.read(chatRepositoryProvider).markRead(roomId: widget.roomId, uid: me.uid);
        await ref.read(chatRepositoryProvider).markMessagesAsRead(roomId: widget.roomId, myUid: me.uid);
      }
      
      if (widget.autoSend != null && widget.autoSend!.isNotEmpty) {
        _ctrl.text = widget.autoSend!;
        _send();
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
    final otherUid = (me != null && _room != null) ? _room!.otherUid(me.uid) : '';
    final otherUser = otherUid.isNotEmpty ? ref.watch(userByUidProvider(otherUid)).valueOrNull : null;
    final isOnline = otherUser?.isOnline ?? false;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            Navigator.of(context).pop();
          },
          child: Container(
            margin: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.primary.withOpacity(0.18),
                width: 1.5,
              ),
            ),
            child: const Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 16,
              color: AppColors.primary,
            ),
          ),
        ),
        title: otherUser != null
            ? Row(
                children: [
                  UserAvatar(
                    photoUrl: otherUser.photoUrl,
                    name: otherUser.name,
                    online: isOnline,
                    frameColor: otherUser.avatarFrameColor,
                    size: 36,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          otherUser.name,
                          style: GoogleFonts.luckiestGuy(
                            fontSize: 16,
                            color: AppColors.primary,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: isOnline ? AppColors.success : AppColors.onSurfaceMuted.withOpacity(0.4),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              isOnline ? 'Online' : 'Offline',
                              style: GoogleFonts.outfit(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: isOnline ? AppColors.success : AppColors.onSurfaceMuted,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              )
            : Text(
                _room?.title ?? 'Chat Room',
                style: GoogleFonts.luckiestGuy(
                  fontSize: 18,
                  color: AppColors.primary,
                  letterSpacing: 1.5,
                ),
              ),
        centerTitle: false,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.5),
          child: Container(
            height: 1.5,
            color: AppColors.primary.withOpacity(0.12),
          ),
        ),
      ),
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.bg, AppColors.surfaceContainerLow],
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child: asyncMessages.when(
                loading: () => const AppLoader(),
                error: (e, _) => ErrorView(message: '$e'),
                data: (messages) {
                  if (me != null) {
                    final hasUnread = messages.any((m) => m.senderId != me.uid && m.status != 'read');
                    if (hasUnread) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        ref.read(chatRepositoryProvider).markMessagesAsRead(
                              roomId: widget.roomId,
                              myUid: me.uid,
                            );
                      });
                    }
                  }

                  if (messages.isEmpty) {
                    return Center(
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 24),
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: AppColors.primary.withOpacity(0.14),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.04),
                              blurRadius: 16,
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.08),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppColors.primary.withOpacity(0.18),
                                  width: 2,
                                ),
                              ),
                              child: const Icon(
                                Icons.chat_bubble_outline_rounded,
                                color: AppColors.primary,
                                size: 38,
                              ),
                            ),
                            const SizedBox(height: 18),
                            Text(
                              'No Messages Yet!',
                              style: GoogleFonts.luckiestGuy(
                                fontSize: 18,
                                color: AppColors.onSurface,
                                letterSpacing: 1,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Say hi to start the chat!',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.outfit(
                                fontSize: 13,
                                color: AppColors.onSurfaceMuted,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                  return ListView.builder(
                    reverse: true,
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                    itemCount: messages.length,
                    itemBuilder: (_, i) {
                      final m = messages[messages.length - 1 - i];
                      return MessageBubble(message: m, mine: m.senderId == me?.uid);
                    },
                  );
                },
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                border: Border(
                  top: BorderSide(
                    color: AppColors.primary.withOpacity(0.1),
                    width: 1.5,
                  ),
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.05),
                    blurRadius: 16,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Container(
                          constraints: const BoxConstraints(minHeight: 48),
                          padding: const EdgeInsets.symmetric(horizontal: 18),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: AppColors.surfaceContainer,
                            borderRadius: BorderRadius.circular(26),
                            border: Border.all(
                              color: AppColors.primary.withOpacity(0.18),
                              width: 1.5,
                            ),
                          ),
                          child: TextField(
                            controller: _ctrl,
                            minLines: 1,
                            maxLines: 5,
                            textInputAction: TextInputAction.send,
                            textCapitalization: TextCapitalization.sentences,
                            onSubmitted: (_) {
                              HapticFeedback.mediumImpact();
                              _send();
                            },
                            cursorColor: AppColors.primary,
                            style: GoogleFonts.outfit(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.onSurface,
                            ),
                            decoration: InputDecoration(
                              isCollapsed: true,
                              filled: false,
                              hintText: 'Type a message...',
                              hintStyle: GoogleFonts.outfit(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.onSurfaceMuted.withOpacity(0.5),
                              ),
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              contentPadding:
                                  const EdgeInsets.symmetric(vertical: 13),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      AnimatedBuilder(
                        animation: _ctrl,
                        builder: (context, _) {
                          final hasText = _ctrl.text.trim().isNotEmpty;
                          return GestureDetector(
                            onTap: () {
                              HapticFeedback.mediumImpact();
                              _send();
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              height: 48,
                              width: 48,
                              decoration: BoxDecoration(
                                gradient: hasText
                                    ? const LinearGradient(
                                        colors: [
                                          AppColors.primary,
                                          AppColors.sColor,
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      )
                                    : null,
                                color: hasText
                                    ? null
                                    : AppColors.onSurfaceMuted
                                        .withOpacity(0.18),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.2),
                                  width: 2,
                                ),
                                boxShadow: hasText
                                    ? [
                                        BoxShadow(
                                          color: AppColors.primary
                                              .withOpacity(0.35),
                                          blurRadius: 12,
                                          offset: const Offset(0, 4),
                                        ),
                                      ]
                                    : null,
                              ),
                              child: Icon(
                                Icons.send_rounded,
                                color: hasText
                                    ? Colors.white
                                    : AppColors.onSurfaceMuted,
                                size: 20,
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
