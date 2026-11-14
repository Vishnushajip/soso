import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/constants/env.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/models/game_room.dart';
import '../../../core/providers/repository_providers.dart';
import '../../../core/providers/service_providers.dart';
import '../../../core/providers/user_providers.dart';
import '../../../core/routes/route_names.dart';
import '../../../core/services/sound_service.dart';
import '../../../core/theme/board_theme.dart';
import '../../../core/widgets/app_banner_ad.dart';
import '../../../core/widgets/guest_google_prompt_dialog.dart';
import '../widgets/board_theme_selection_sheet.dart';
class OnlineLobbyScreen extends ConsumerStatefulWidget {
  const OnlineLobbyScreen({super.key});

  @override
  ConsumerState<OnlineLobbyScreen> createState() => _OnlineLobbyScreenState();
}

class _OnlineLobbyScreenState extends ConsumerState<OnlineLobbyScreen> {
  bool _busy = false;
  String? _error;
  bool _magicEnabled = true;
  int _maxPlayers = 2;
  int _boardSize = Env.boardSize;
  final _codeCtrl = TextEditingController();

  GameRoomType _modeFromQuery() {
    final m = GoRouterState.of(context).uri.queryParameters['mode'];
    return GameRoomType.values.firstWhere(
      (t) => t.name == m,
      orElse: () => GameRoomType.quick,
    );
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _codeCtrl.dispose();
    super.dispose();
  }

  Future<void> _startMatch(GameRoomType mode) async {
    if (mode == GameRoomType.friend) {
      if (!GuestGooglePromptDialog.allowAction(
        context,
        ref,
        feature: 'Friend Match',
        description:
            'Guest accounts cannot play friend matches. Sign in with Google to challenge and play with your friends!',
      )) {
        return;
      }
    }
    ref.read(soundServiceProvider).play(AppSound.buttonClick);
    HapticFeedback.heavyImpact();
    setState(() {
      _busy = true;
      _error = null;
    });
    final user = ref.read(currentUserProvider).valueOrNull;
    final repo = ref.read(gameRepositoryProvider);
    try {
      if (user == null) throw StateError('Not signed in');
      GameRoom? room;
      if (mode == GameRoomType.quick || mode == GameRoomType.ranked) {
        final found = await repo.findQuickMatch(type: mode);
        if (found != null) {
          await repo.joinRoom(roomId: found.id, user: user);
          room = found;
        } else {
          room = await repo.createRoom(host: user, type: mode);
        }
      } else {
        room = await repo.createRoom(
          host: user,
          type: mode,
          maxPlayers: _maxPlayers,
          boardSize: _boardSize,
          magicEnabled: _magicEnabled,
        );
      }
      if (!mounted) return;
      context.push('${RouteNames.gameBoard}?roomId=${room.id}');
    } catch (e) {
      HapticFeedback.vibrate();
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _joinByCode() async {
    final mode = _modeFromQuery();
    if (mode == GameRoomType.friend) {
      if (!GuestGooglePromptDialog.allowAction(
        context,
        ref,
        feature: 'Friend Match',
        description:
            'Guest accounts cannot play friend matches. Sign in with Google to challenge and play with your friends!',
      )) {
        return;
      }
    }
    final code = _codeCtrl.text.trim().toUpperCase();
    if (code.isEmpty) {
      HapticFeedback.lightImpact();
      return;
    }
    HapticFeedback.mediumImpact();
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final user = ref.read(currentUserProvider).valueOrNull;
      if (user == null) throw StateError('Not signed in');
      final room = await ref.read(gameRepositoryProvider).findByCode(code);
      if (room == null) throw StateError('No waiting room with that code');
      await ref
          .read(gameRepositoryProvider)
          .joinRoom(roomId: room.id, user: user);
      if (!mounted) return;
      context.push('${RouteNames.gameBoard}?roomId=${room.id}');
    } catch (e) {
      HapticFeedback.vibrate();
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final mode = _modeFromQuery();

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
        title: Column(
          children: [
            Text(
              'Online Arena',
              style: GoogleFonts.luckiestGuy(
                fontSize: 20,
                color: AppColors.primary,
                letterSpacing: 1.5,
              ),
            ),
            Text(
              _modeLabel(mode),
              style: GoogleFonts.outfit(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.onSurfaceMuted,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: _busy
          ? _BusyOverlay(mode: mode)
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _ModeHeroBanner(mode: mode),
                  const SizedBox(height: 16),
                  _StartCard(
                    mode: mode,
                    onStart: () => _startMatch(mode),
                  ),
                  if (mode == GameRoomType.private ||
                      mode == GameRoomType.friend) ...[
                    const SizedBox(height: 14),
                    _PlayerCountCard(
                      value: _maxPlayers,
                      onChanged: (v) {
                        HapticFeedback.selectionClick();
                        setState(() => _maxPlayers = v);
                      },
                    ),
                    const SizedBox(height: 14),
                    _BoardSizeCard(
                      boardSize: _boardSize,
                      onChanged: (v) {
                        HapticFeedback.selectionClick();
                        setState(() => _boardSize = v);
                      },
                    ),
                    const SizedBox(height: 14),
                    _MagicSpellsCard(
                      enabled: _magicEnabled,
                      onChanged: (v) {
                        HapticFeedback.selectionClick();
                        setState(() => _magicEnabled = v);
                      },
                    ),
                    const SizedBox(height: 14),
                    _BoardThemeCard(),
                  ],
                  const SizedBox(height: 14),
                  _JoinCodeCard(controller: _codeCtrl, onJoin: _joinByCode),
                  if (_error != null) ...[
                    const SizedBox(height: 14),
                    _ErrorBanner(message: _error!),
                  ],
                ],
              ),
            ),
      bottomNavigationBar: const SafeArea(
        child: AppBannerAd(placement: 'online_lobby'),
      ),
    );
  }

  String _modeLabel(GameRoomType mode) {
    return switch (mode) {
      GameRoomType.quick => 'QUICK MATCH',
      GameRoomType.ranked => 'RANKED MATCH',
      GameRoomType.private => 'PRIVATE ROOM',
      _ => 'FRIEND MATCH',
    };
  }
}

class _BusyOverlay extends StatelessWidget {
  const _BusyOverlay({required this.mode});
  final GameRoomType mode;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: AppColors.surface,
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.primary.withOpacity(0.2),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.15),
                  blurRadius: 24,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: SizedBox(
              width: 40,
              height: 40,
              child: CircularProgressIndicator(
                strokeWidth: 3.5,
                valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                backgroundColor: AppColors.primary.withOpacity(0.12),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            mode == GameRoomType.quick || mode == GameRoomType.ranked
                ? 'Finding a Match…'
                : 'Creating Room…',
            style: GoogleFonts.luckiestGuy(
              fontSize: 20,
              color: AppColors.onSurface,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Searching the arena for opponents',
            style: GoogleFonts.outfit(
              fontSize: 13,
              color: AppColors.onSurfaceMuted,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _ModeHeroBanner extends StatelessWidget {
  const _ModeHeroBanner({required this.mode});
  final GameRoomType mode;

  @override
  Widget build(BuildContext context) {
    final data = _modeData(mode);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [data.color.withOpacity(0.15), data.color.withOpacity(0.06)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: data.color.withOpacity(0.28), width: 2),
        boxShadow: [
          BoxShadow(
            color: data.color.withOpacity(0.10),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: data.color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: data.color.withOpacity(0.3),
                width: 1.5,
              ),
            ),
            child: Text(data.emoji, style: const TextStyle(fontSize: 28)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.title,
                  style: GoogleFonts.luckiestGuy(
                    fontSize: 18,
                    color: data.color,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  data.subtitle,
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    color: AppColors.onSurfaceMuted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  _ModeInfo _modeData(GameRoomType mode) {
    return switch (mode) {
      GameRoomType.quick => const _ModeInfo(
        '⚡',
        'Quick Match',
        'Jump straight into a casual game',
        AppColors.highlight,
      ),
      GameRoomType.ranked => const _ModeInfo(
        '🏆',
        'Ranked Match',
        'Compete for points on the leaderboard',
        AppColors.secondary,
      ),
      GameRoomType.private => const _ModeInfo(
        '🔒',
        'Private Room',
        'Create a room and share the code',
        AppColors.sColor,
      ),
      _ => const _ModeInfo(
        '👥',
        'Friend Match',
        'Invite a friend to your room',
        AppColors.oColor,
      ),
    };
  }
}

class _ModeInfo {
  const _ModeInfo(this.emoji, this.title, this.subtitle, this.color);
  final String emoji;
  final String title;
  final String subtitle;
  final Color color;
}

class _StartCard extends StatelessWidget {
  const _StartCard({
    required this.mode,
    required this.onStart,
  });
  final GameRoomType mode;
  final VoidCallback onStart;

  String _label(GameRoomType mode) => switch (mode) {
    GameRoomType.quick => 'Start Quick Match',
    GameRoomType.ranked => 'Start Ranked Match',
    GameRoomType.private => 'Create Private Room',
    _ => 'Create Room & Invite',
  };

  String _sublabel(GameRoomType mode) => switch (mode) {
    GameRoomType.quick || GameRoomType.ranked => 'You\'ll be matched instantly',
    _ => 'Share the code with your friend',
  };

  @override
  Widget build(BuildContext context) {
    return _GameCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _CardLabel(label: 'Quick Action', icon: Icons.bolt_rounded),
          const SizedBox(height: 14),
          Text(
            _sublabel(mode),
            style: GoogleFonts.outfit(
              fontSize: 12,
              color: AppColors.onSurfaceMuted,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 14),
          GestureDetector(
            onTap: onStart,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, AppColors.sColor],
                ),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: Colors.white.withOpacity(0.2),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.5),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                  BoxShadow(
                    color: AppColors.sColor.withOpacity(0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.play_arrow_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    _label(mode),
                    style: GoogleFonts.luckiestGuy(
                      fontSize: 18,
                      color: Colors.white,
                      letterSpacing: 1,
                    ),
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

class _JoinCodeCard extends StatelessWidget {
  const _JoinCodeCard({required this.controller, required this.onJoin});
  final TextEditingController controller;
  final VoidCallback onJoin;

  @override
  Widget build(BuildContext context) {
    return _GameCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _CardLabel(
            label: 'Join with Code',
            icon: Icons.vpn_key_rounded,
          ),
          const SizedBox(height: 14),
          TextField(
            controller: controller,
            textCapitalization: TextCapitalization.characters,
            textAlign: TextAlign.center,
            style: GoogleFonts.luckiestGuy(
              fontSize: 22,
              color: AppColors.primary,
              letterSpacing: 8,
            ),
            onChanged: (_) => HapticFeedback.selectionClick(),
            decoration: InputDecoration(
              hintText: 'ABCDEF',
              hintStyle: GoogleFonts.luckiestGuy(
                fontSize: 22,
                color: AppColors.onSurfaceMuted.withOpacity(0.3),
                letterSpacing: 8,
              ),
              filled: true,
              fillColor: AppColors.primary.withOpacity(0.05),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: AppColors.primary.withOpacity(0.2),
                  width: 1.5,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(
                  color: AppColors.primary,
                  width: 2,
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: onJoin,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 15),
              decoration: BoxDecoration(
                color: AppColors.secondary.withOpacity(0.12),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.secondary.withOpacity(0.4),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.secondary.withOpacity(0.12),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.login_rounded,
                    color: AppColors.secondary,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Join Room',
                    style: GoogleFonts.luckiestGuy(
                      fontSize: 17,
                      color: AppColors.secondary,
                      letterSpacing: 1,
                    ),
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

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.danger.withOpacity(0.10),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.danger.withOpacity(0.35),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.danger.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.warning_rounded,
              color: AppColors.danger,
              size: 18,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.outfit(
                color: AppColors.danger,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GameCard extends StatelessWidget {
  const _GameCard({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.14),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _CardLabel extends StatelessWidget {
  const _CardLabel({required this.label, required this.icon});
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primary, size: 16),
        const SizedBox(width: 6),
        Text(
          label,
          style: GoogleFonts.luckiestGuy(
            fontSize: 13,
            color: AppColors.primary,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Container(
            height: 1.5,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary.withOpacity(0.3),
                  Colors.transparent,
                ],
              ),
              borderRadius: BorderRadius.circular(1),
            ),
          ),
        ),
      ],
    );
  }
}

class _PlayerCountCard extends StatelessWidget {
  const _PlayerCountCard({
    required this.value,
    required this.onChanged,
  });
  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return _GameCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _CardLabel(
            label: 'Players',
            icon: Icons.groups_rounded,
          ),
          const SizedBox(height: 6),
          Text(
            'How many players in this room?',
            style: GoogleFonts.outfit(
              fontSize: 12,
              color: AppColors.onSurfaceMuted,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              for (final count in const [2, 3, 4, 5, 6]) ...[
                Expanded(
                  child: _PlayerCountChip(
                    count: count,
                    selected: value == count,
                    onTap: () => onChanged(count),
                  ),
                ),
                if (count != 6) const SizedBox(width: 8),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _BoardSizeCard extends StatelessWidget {
  const _BoardSizeCard({required this.boardSize, required this.onChanged});
  final int boardSize;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return _GameCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _CardLabel(label: 'Board Size', icon: Icons.grid_4x4_rounded),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${AppConstants.minBoardSize}×${AppConstants.minBoardSize}',
                style: GoogleFonts.outfit(
                  fontSize: 11,
                  color: AppColors.onSurfaceMuted,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, AppColors.sColor],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.4),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Text(
                  '$boardSize × $boardSize',
                  style: GoogleFonts.luckiestGuy(
                    fontSize: 16,
                    color: Colors.white,
                    letterSpacing: 1,
                  ),
                ),
              ),
              Text(
                '${AppConstants.maxBoardSize}×${AppConstants.maxBoardSize}',
                style: GoogleFonts.outfit(
                  fontSize: 11,
                  color: AppColors.onSurfaceMuted,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: AppColors.primary,
              inactiveTrackColor: AppColors.primary.withOpacity(0.15),
              thumbColor: AppColors.primary,
              overlayColor: AppColors.primary.withOpacity(0.12),
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
              trackHeight: 5,
            ),
            child: Slider(
              value: boardSize.toDouble(),
              min: AppConstants.minBoardSize.toDouble(),
              max: AppConstants.maxBoardSize.toDouble(),
              divisions: AppConstants.maxBoardSize - AppConstants.minBoardSize,
              label: '$boardSize × $boardSize',
              onChanged: (v) => onChanged(v.round()),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlayerCountChip extends StatelessWidget {
  const _PlayerCountChip({
    required this.count,
    required this.selected,
    required this.onTap,
  });
  final int count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withOpacity(0.14)
              : AppColors.primary.withOpacity(0.04),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected
                ? AppColors.primary
                : AppColors.primary.withOpacity(0.18),
            width: selected ? 2 : 1.5,
          ),
        ),
        child: Column(
          children: [
            Icon(
              Icons.person_rounded,
              size: 20,
              color: selected ? AppColors.primary : AppColors.onSurfaceMuted,
            ),
            const SizedBox(height: 4),
            Text(
              '$count',
              style: GoogleFonts.luckiestGuy(
                fontSize: 20,
                color: selected ? AppColors.primary : AppColors.onSurface,
              ),
            ),
            Text(
              count == 2 ? 'Duel' : 'Players',
              style: GoogleFonts.outfit(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: AppColors.onSurfaceMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MagicSpellsCard extends StatelessWidget {
  const _MagicSpellsCard({
    required this.enabled,
    required this.onChanged,
  });
  final bool enabled;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return _GameCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _CardLabel(
            label: 'Match Settings',
            icon: Icons.settings_rounded,
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.auto_awesome,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Allow Magic Spells',
                      style: GoogleFonts.luckiestGuy(
                        fontSize: 14,
                        color: AppColors.onSurface,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Enable undo, erase, and hints during gameplay',
                      style: GoogleFonts.outfit(
                        color: AppColors.onSurfaceMuted,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Switch.adaptive(
                value: enabled,
                activeTrackColor: AppColors.primary,
                onChanged: onChanged,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BoardThemeCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(boardThemeProvider);
    return _GameCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _CardLabel(
            label: 'Board Theme',
            icon: Icons.palette_rounded,
          ),
          const SizedBox(height: 14),
          InkWell(
            onTap: () {
              HapticFeedback.lightImpact();
              BoardThemeSelectionSheet.show(context);
            },
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: theme.boardBgColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: theme.boardBorderColor,
                  width: theme.isGlossy ? 2 : 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: theme.cellBgColor,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: theme.highlightColor.withOpacity(0.5)),
                    ),
                    child: Center(
                      child: Text(
                        'S',
                        style: GoogleFonts.luckiestGuy(
                          fontSize: 16,
                          color: theme.sColor,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          theme.name,
                          style: GoogleFonts.luckiestGuy(
                            fontSize: 16,
                            color: theme.sColor,
                            letterSpacing: 0.5,
                          ),
                        ),
                        Text(
                          'Tap to change theme',
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            color: theme.oColor.withOpacity(0.8),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: theme.sColor,
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
