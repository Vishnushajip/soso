import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_loader.dart';
import '../../../core/widgets/app_snack_bar.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/user_avatar.dart';
import '../../../core/models/chat_room.dart';
import '../../../core/models/message.dart';
import '../../../core/providers/auth_providers.dart';
import '../../../core/providers/chat_providers.dart';
import '../../../core/providers/repository_providers.dart';
import '../../../core/providers/user_providers.dart';

const _quickReactions = ['👍', '😂', '🔥', '😮', '❤️'];

class InGameChatSheet extends ConsumerStatefulWidget {
  const InGameChatSheet({super.key, required this.room, required this.onClose});
  final ChatRoom room;
  final VoidCallback onClose;

  @override
  ConsumerState<InGameChatSheet> createState() => _InGameChatSheetState();
}

class _InGameChatSheetState extends ConsumerState<InGameChatSheet> {
  final _ctrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  bool _isTyping = false;
  Timer? _typingTimer;

  @override
  void initState() {
    super.initState();
    _markRead();
  }

  void _markRead() {
    final me = ref.read(currentUserProvider).valueOrNull;
    if (me != null) {
      ref
          .read(chatRepositoryProvider)
          .markRead(roomId: widget.room.id, uid: me.uid);
      ref
          .read(chatRepositoryProvider)
          .markMessagesAsRead(roomId: widget.room.id, myUid: me.uid);
    }
  }

  void _onTyping() {
    if (!_isTyping) {
      _isTyping = true;
      _updateFirestoreTyping(true);
    }
    _typingTimer?.cancel();
    _typingTimer = Timer(const Duration(seconds: 2), () {
      _isTyping = false;
      _updateFirestoreTyping(false);
    });
  }

  void _updateFirestoreTyping(bool typing) {
    final me = ref.read(currentUidProvider);
    if (me == null) return;
    FirebaseFirestore.instance
        .collection(AppConstants.chatRoomsCollection)
        .doc(widget.room.id)
        .set({
      'typingState': {me: typing},
    }, SetOptions(merge: true));
  }

  Future<void> _send(String text) async {
    if (text.trim().isEmpty) return;
    final me = ref.read(currentUserProvider).valueOrNull;
    if (me == null) return;
    _ctrl.clear();
    _isTyping = false;
    _updateFirestoreTyping(false);

    try {
      await ref.read(chatRepositoryProvider).sendMessage(
            room: widget.room,
            senderId: me.uid,
            senderName: me.name,
            senderPhoto: me.photoUrl,
            text: text.trim(),
          );
      _scrollCtrl.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    } catch (e) {
      if (mounted) AppSnackBar.showError(context, e.toString());
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _scrollCtrl.dispose();
    _typingTimer?.cancel();
    _updateFirestoreTyping(false);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final asyncMessages = ref.watch(roomMessagesProvider(widget.room.id));
    final me = ref.watch(currentUserProvider).valueOrNull;
    final otherUid = me != null ? widget.room.otherUid(me.uid) : '';

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.arenaStone, AppColors.arenaBgBottom],
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
        border: Border.all(
          color: AppColors.arenaGold.withOpacity(0.35),
          width: 1.5,
        ),
      ),
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SafeArea(
        top: false,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.7,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 10),
              Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.onArenaMuted.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              _header(context),
              Flexible(
                child: asyncMessages.when(
                  loading: () => const AppLoader(),
                  error: (e, _) => ErrorView(message: '$e'),
                  data: (messages) {
                    if (messages.isEmpty) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(
                            'Say hello to your opponent! 👋',
                            style: GoogleFonts.outfit(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.onArenaMuted,
                            ),
                          ),
                        ),
                      );
                    }
                    return ListView.builder(
                      controller: _scrollCtrl,
                      reverse: true,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      itemCount: messages.length,
                      itemBuilder: (context, i) {
                        final m = messages[messages.length - 1 - i];
                        return _InGameMessageBubble(
                          message: m,
                          isMine: m.senderId == me?.uid,
                        );
                      },
                    );
                  },
                ),
              ),
              _typingIndicator(otherUid),
              _quickReactionsRow(),
              _inputBar(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.arenaGold.withOpacity(0.18)),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(Icons.chat_rounded,
                  color: AppColors.arenaGold, size: 20),
              const SizedBox(width: 8),
              Text(
                'MATCH CHAT',
                style: GoogleFonts.luckiestGuy(
                  fontSize: 16,
                  color: AppColors.arenaGold,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
          GestureDetector(
            onTap: () {
              widget.onClose();
              Navigator.pop(context);
            },
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.arenaBgBottom.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close_rounded,
                  color: AppColors.onArenaMuted, size: 18),
            ),
          ),
        ],
      ),
    );
  }

  Widget _typingIndicator(String otherUid) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection(AppConstants.chatRoomsCollection)
          .doc(widget.room.id)
          .snapshots(),
      builder: (context, snapshot) {
        final data = snapshot.data?.data();
        final typingMap = data?['typingState'] as Map?;
        final otherTyping = typingMap?[otherUid] as bool? ?? false;
        if (!otherTyping) return const SizedBox(height: 0);
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
          alignment: Alignment.centerLeft,
          child: Text(
            'Opponent is typing…',
            style: GoogleFonts.outfit(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: AppColors.secondary,
            ),
          ),
        );
      },
    );
  }

  Widget _quickReactionsRow() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: _quickReactions.map((emoji) {
          return GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              _send(emoji);
            },
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.arenaBgBottom.withOpacity(0.5),
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.arenaGold.withOpacity(0.2),
                ),
              ),
              child: Text(emoji, style: const TextStyle(fontSize: 20)),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _inputBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 2, 14, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Container(
              constraints: const BoxConstraints(minHeight: 46),
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: AppColors.arenaBgBottom.withOpacity(0.6),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: AppColors.arenaGold.withOpacity(0.3),
                  width: 1.5,
                ),
              ),
              child: TextField(
                controller: _ctrl,
                minLines: 1,
                maxLines: 4,
                textInputAction: TextInputAction.send,
                textCapitalization: TextCapitalization.sentences,
                cursorColor: AppColors.arenaGold,
                onChanged: (_) => _onTyping(),
                onSubmitted: (val) {
                  HapticFeedback.mediumImpact();
                  _send(val);
                },
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.onArena,
                ),
                decoration: InputDecoration(
                  isCollapsed: true,
                  filled: false,
                  hintText: 'Send message…',
                  hintStyle: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.onArenaMuted.withOpacity(0.6),
                  ),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
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
                  _send(_ctrl.text);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  height: 46,
                  width: 46,
                  decoration: BoxDecoration(
                    gradient: hasText
                        ? const LinearGradient(
                            colors: [AppColors.primary, AppColors.sColor],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : null,
                    color: hasText
                        ? null
                        : AppColors.onArenaMuted.withOpacity(0.2),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withOpacity(0.2),
                      width: 1.5,
                    ),
                    boxShadow: hasText
                        ? [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.35),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ]
                        : null,
                  ),
                  child: Icon(
                    Icons.send_rounded,
                    color: hasText ? Colors.white : AppColors.onArenaMuted,
                    size: 18,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _InGameMessageBubble extends StatelessWidget {
  const _InGameMessageBubble({required this.message, required this.isMine});
  final Message message;
  final bool isMine;

  @override
  Widget build(BuildContext context) {
    final isReaction = _quickReactions.contains(message.text);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment:
            isMine ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMine) ...[
            UserAvatar(
              photoUrl: message.senderPhoto,
              name: message.senderName,
              size: 26,
            ),
            const SizedBox(width: 6),
          ],
          Flexible(
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: isReaction ? 8 : 13,
                vertical: isReaction ? 4 : 9,
              ),
              decoration: BoxDecoration(
                gradient: isReaction
                    ? null
                    : (isMine
                        ? const LinearGradient(
                            colors: [AppColors.primary, AppColors.sColor],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : null),
                color: isReaction
                    ? Colors.transparent
                    : (isMine ? null : AppColors.arenaStoneEdge),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isMine ? 16 : 4),
                  bottomRight: Radius.circular(isMine ? 4 : 16),
                ),
                border: isReaction || isMine
                    ? null
                    : Border.all(
                        color: AppColors.arenaGold.withOpacity(0.15),
                      ),
              ),
              child: Text(
                message.text,
                style: GoogleFonts.outfit(
                  fontSize: isReaction ? 28 : 14,
                  fontWeight: FontWeight.w700,
                  color: isMine ? Colors.white : AppColors.onArena,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
