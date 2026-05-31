import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_loader.dart';
import '../../../core/widgets/section_card.dart';
import '../../../models/game_room.dart';
import '../../../providers/repository_providers.dart';
import '../../../providers/user_providers.dart';
import '../../../routes/route_names.dart';

class OnlineLobbyScreen extends ConsumerStatefulWidget {
  const OnlineLobbyScreen({super.key});

  @override
  ConsumerState<OnlineLobbyScreen> createState() => _OnlineLobbyScreenState();
}

class _OnlineLobbyScreenState extends ConsumerState<OnlineLobbyScreen> {
  bool _busy = false;
  String? _error;
  final _codeCtrl = TextEditingController();

  GameRoomType _modeFromQuery() {
    final m = GoRouterState.of(context).uri.queryParameters['mode'];
    return GameRoomType.values.firstWhere(
      (t) => t.name == m,
      orElse: () => GameRoomType.quick,
    );
  }

  Future<void> _startMatch(GameRoomType mode) async {
    setState(() { _busy = true; _error = null; });
    final user = ref.read(currentUserProvider).valueOrNull;
    final repo = ref.read(gameRepositoryProvider);
    try {
      if (user == null) throw StateError('Not signed in');
      GameRoom? room;
      if (mode == GameRoomType.quick || mode == GameRoomType.ranked) {
        final found = await repo.findQuickMatch();
        if (found != null) {
          await repo.joinRoom(roomId: found.id, user: user);
          room = found;
        } else {
          room = await repo.createRoom(host: user, type: mode);
        }
      } else {
        room = await repo.createRoom(host: user, type: mode);
      }
      if (!mounted) return;
      context.push('${RouteNames.gameBoard}?roomId=${room.id}');
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _joinByCode() async {
    final code = _codeCtrl.text.trim().toUpperCase();
    if (code.isEmpty) return;
    setState(() { _busy = true; _error = null; });
    try {
      final user = ref.read(currentUserProvider).valueOrNull;
      if (user == null) throw StateError('Not signed in');
      final room = await ref.read(gameRepositoryProvider).findByCode(code);
      if (room == null) throw StateError('No waiting room with that code');
      await ref.read(gameRepositoryProvider).joinRoom(roomId: room.id, user: user);
      if (!mounted) return;
      context.push('${RouteNames.gameBoard}?roomId=${room.id}');
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final mode = _modeFromQuery();

    return Scaffold(
      appBar: AppBar(title: Text('Online · ${mode.name}')),
      body: _busy
          ? const AppLoader(label: 'Finding a match…')
          : Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SectionCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          mode == GameRoomType.private || mode == GameRoomType.friend
                              ? 'Create a room and share the code'
                              : 'Tap to enter the matchmaking queue',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 12),
                        AppButton(
                          expanded: true,
                          icon: Icons.play_circle_fill,
                          label: mode == GameRoomType.quick
                              ? 'Start Quick Match'
                              : mode == GameRoomType.ranked
                                  ? 'Start Ranked Match'
                                  : mode == GameRoomType.private
                                      ? 'Create Private Room'
                                      : 'Create Room & Invite Friend',
                          onPressed: () => _startMatch(mode),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  SectionCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Join with a code', style: TextStyle(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _codeCtrl,
                          textCapitalization: TextCapitalization.characters,
                          decoration: const InputDecoration(hintText: 'ABCDEF'),
                        ),
                        const SizedBox(height: 12),
                        AppButton(
                          expanded: true,
                          variant: AppButtonVariant.secondary,
                          icon: Icons.login,
                          label: 'Join room',
                          onPressed: _joinByCode,
                        ),
                      ],
                    ),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 16),
                    Text(_error!, style: const TextStyle(color: AppColors.danger)),
                  ],
                ],
              ),
            ),
    );
  }
}
