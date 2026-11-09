import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/constants/env.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/providers/service_providers.dart';
import '../../../core/providers/user_providers.dart';
import '../../../core/routes/route_names.dart';
import '../../../core/services/sound_service.dart';
import '../../../core/theme/board_theme.dart';
import '../widgets/board_theme_selection_sheet.dart';

class LocalGameSetupScreen extends ConsumerStatefulWidget {
  const LocalGameSetupScreen({super.key});

  @override
  ConsumerState<LocalGameSetupScreen> createState() =>
      _LocalGameSetupScreenState();
}

class _LocalGameSetupScreenState extends ConsumerState<LocalGameSetupScreen>
    with SingleTickerProviderStateMixin {
  int _playerCount = 2;
  int _boardSize = Env.boardSize;
  bool _magicEnabled = true;
  late final List<TextEditingController> _names = List.generate(
    AppConstants.maxPlayersLocal,
    (i) => TextEditingController(text: 'Player ${i + 1}'),
  );
  bool _prefilledFromAuth = false;
  late final AnimationController _bounceCtrl;
  late final Animation<double> _bounceAnim;

  @override
  void initState() {
    super.initState();
    _bounceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _bounceAnim = Tween<double>(
      begin: 1.0,
      end: 1.04,
    ).animate(CurvedAnimation(parent: _bounceCtrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _bounceCtrl.dispose();
    for (final c in _names) c.dispose();
    super.dispose();
  }

  void _triggerBounce() {
    _bounceCtrl.forward().then((_) => _bounceCtrl.reverse());
  }

  @override
  Widget build(BuildContext context) {
    if (!_prefilledFromAuth) {
      final user = ref.read(currentUserProvider).valueOrNull;
      if (user != null && user.name.trim().isNotEmpty) {
        _names[0].text = user.name;
        _prefilledFromAuth = true;
      }
    }

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
        title: Text(
          'Pass & Play',
          style: GoogleFonts.luckiestGuy(
            fontSize: 22,
            color: AppColors.primary,
            letterSpacing: 1.5,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _InfoBanner(),
            const SizedBox(height: 16),
            _PlayerCountCard(
              playerCount: _playerCount,
              onChanged: (i) {
                HapticFeedback.selectionClick();
                setState(() => _playerCount = i);
                _triggerBounce();
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
            _NamesCard(playerCount: _playerCount, controllers: _names),
            const SizedBox(height: 14),
            _BoardThemeCard(),
            const SizedBox(height: 28),
            _StartButton(
              bounceAnim: _bounceAnim,
              onTap: () {
                ref.read(soundServiceProvider).play(AppSound.buttonClick);
                HapticFeedback.heavyImpact();
                _triggerBounce();
                ref.read(trackingServiceProvider).matchStarted(
                      mode: 'local',
                      boardSize: _boardSize,
                    );
                final names = _names
                    .take(_playerCount)
                    .map(
                      (c) => c.text.trim().isEmpty ? 'Player' : c.text.trim(),
                    );
                context.push(
                  '${RouteNames.localBoard}?size=$_boardSize&names=${names.join(',')}&magicEnabled=$_magicEnabled',
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withOpacity(0.12),
            AppColors.oColor.withOpacity(0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.20),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.emoji_events_rounded,
              color: AppColors.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'You play as Player 1 — your wins earn profile points!',
              style: GoogleFonts.outfit(
                color: AppColors.onSurfaceMuted,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlayerCountCard extends StatelessWidget {
  const _PlayerCountCard({required this.playerCount, required this.onChanged});
  final int playerCount;
  final void Function(int) onChanged;

  @override
  Widget build(BuildContext context) {
    return _GameCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _CardLabel(label: 'Players', icon: Icons.people_alt_rounded),
          const SizedBox(height: 14),
          Row(
            children: [
              for (
                var i = AppConstants.minPlayersLocal;
                i <= AppConstants.maxPlayersLocal;
                i++
              )
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      right: i < AppConstants.maxPlayersLocal ? 8 : 0,
                    ),
                    child: _PlayerChip(
                      count: i,
                      isSelected: playerCount == i,
                      onTap: () => onChanged(i),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PlayerChip extends StatelessWidget {
  const _PlayerChip({
    required this.count,
    required this.isSelected,
    required this.onTap,
  });
  final int count;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutBack,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withOpacity(0.14)
              : AppColors.bg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : AppColors.onSurfaceMuted.withOpacity(0.2),
            width: isSelected ? 2 : 1.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.20),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Column(
          children: [
            AnimatedScale(
              scale: isSelected ? 1.15 : 1.0,
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutBack,
              child: Text(
                '$count',
                style: GoogleFonts.luckiestGuy(
                  fontSize: 22,
                  color: isSelected
                      ? AppColors.primary
                      : AppColors.onSurfaceMuted,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              count == 1 ? 'Solo' : 'Players',
              style: GoogleFonts.outfit(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: isSelected
                    ? AppColors.primary
                    : AppColors.onSurfaceMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BoardSizeCard extends StatelessWidget {
  const _BoardSizeCard({required this.boardSize, required this.onChanged});
  final int boardSize;
  final void Function(int) onChanged;

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
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 6,
                ),
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
          _MiniBoard(size: boardSize.clamp(3, 6)),
        ],
      ),
    );
  }
}

class _MiniBoard extends StatelessWidget {
  const _MiniBoard({required this.size});
  final int size;

  @override
  Widget build(BuildContext context) {
    final show = size.clamp(3, 5);
    return Center(
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: AppColors.board,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: AppColors.grid.withOpacity(0.4),
            width: 1.5,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(
            show,
            (r) => Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(show, (c) {
                const letters = ['S', 'O', '', 'S', '', 'O', '', 'S', 'O'];
                final idx = (r * show + c) % letters.length;
                final letter = letters[idx];
                return Container(
                  width: 20,
                  height: 20,
                  margin: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: letter.isEmpty
                        ? AppColors.surface
                        : letter == 'S'
                        ? AppColors.sColor.withOpacity(0.15)
                        : AppColors.oColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: letter.isEmpty
                          ? AppColors.grid.withOpacity(0.3)
                          : letter == 'S'
                          ? AppColors.sColor.withOpacity(0.4)
                          : AppColors.oColor.withOpacity(0.4),
                      width: 1,
                    ),
                  ),
                  child: Center(
                    child: letter.isNotEmpty
                        ? Text(
                            letter,
                            style: GoogleFonts.luckiestGuy(
                              fontSize: 9,
                              color: letter == 'S'
                                  ? AppColors.sColor
                                  : AppColors.oColor,
                            ),
                          )
                        : null,
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

class _NamesCard extends StatelessWidget {
  const _NamesCard({required this.playerCount, required this.controllers});
  final int playerCount;
  final List<TextEditingController> controllers;

  @override
  Widget build(BuildContext context) {
    return _GameCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _CardLabel(label: 'Player Names', icon: Icons.edit_rounded),
          const SizedBox(height: 14),
          for (var i = 0; i < playerCount; i++) ...[
            _PlayerNameField(index: i, controller: controllers[i]),
            if (i < playerCount - 1) const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}

class _PlayerNameField extends StatelessWidget {
  const _PlayerNameField({required this.index, required this.controller});
  final int index;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    final color = AppColors.playerPalette[index];
    return TextField(
      controller: controller,
      style: GoogleFonts.outfit(
        fontWeight: FontWeight.w700,
        fontSize: 14,
        color: AppColors.onSurface,
      ),
      decoration: InputDecoration(
        filled: true,
        fillColor: color.withOpacity(0.06),
        prefixIcon: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: color.withOpacity(0.18),
              shape: BoxShape.circle,
              border: Border.all(color: color.withOpacity(0.5), width: 2),
            ),
            child: Center(
              child: Text(
                '${index + 1}',
                style: GoogleFonts.luckiestGuy(fontSize: 13, color: color),
              ),
            ),
          ),
        ),
        labelText: 'Player ${index + 1}',
        labelStyle: GoogleFonts.outfit(
          fontSize: 12,
          color: color.withOpacity(0.7),
          fontWeight: FontWeight.w600,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: color.withOpacity(0.25), width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: color, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
      ),
    );
  }
}

class _StartButton extends StatelessWidget {
  const _StartButton({required this.bounceAnim, required this.onTap});
  final Animation<double> bounceAnim;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: bounceAnim,
      builder: (_, child) =>
          Transform.scale(scale: bounceAnim.value, child: child),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.primary, AppColors.sColor],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.25), width: 2),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.5),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: AppColors.sColor.withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, 4),
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
                'Start Match!',
                style: GoogleFonts.luckiestGuy(
                  fontSize: 20,
                  color: Colors.white,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(width: 8),
              const Text('⚔', style: TextStyle(fontSize: 18)),
            ],
          ),
        ),
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
            fontSize: 14,
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
