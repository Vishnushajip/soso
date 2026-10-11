import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/models/match_record.dart';
import '../../../core/providers/match_history_providers.dart';
import '../../../core/providers/service_providers.dart';
import '../../../core/services/sound_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/format_utils.dart';
import '../../../core/utils/sos_engine.dart';
import '../../../core/widgets/app_loader.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/user_avatar.dart';
import '../../game/widgets/game_board_widget.dart';

final _matchFilterProvider = StateProvider.autoDispose<String>((ref) => 'all');

class MatchHistoryScreen extends ConsumerWidget {
  const MatchHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final matchesAsync = ref.watch(matchHistoryProvider);
    final filter = ref.watch(_matchFilterProvider);

    return Scaffold(
      backgroundColor: AppColors.arenaBgBottom,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            context.pop();
          },
          child: Container(
            margin: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.arenaStone,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.arenaGold.withValues(alpha: 0.35),
                width: 1.5,
              ),
            ),
            child: const Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 16,
              color: AppColors.arenaGold,
            ),
          ),
        ),
        title: Text(
          'Match History',
          style: GoogleFonts.luckiestGuy(
            fontSize: 20,
            color: AppColors.arenaGold,
            letterSpacing: 1.2,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Filter Chips (Scrollable so chips never squeeze or clip on mobile)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
            child: Row(
              children: [
                _FilterChip(
                  label: 'All Matches',
                  value: 'all',
                  current: filter,
                  onSelect: (val) => ref.read(_matchFilterProvider.notifier).state = val,
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Online 🌐',
                  value: 'online',
                  current: filter,
                  onSelect: (val) => ref.read(_matchFilterProvider.notifier).state = val,
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'VS Bot 🤖',
                  value: 'ai',
                  current: filter,
                  onSelect: (val) => ref.read(_matchFilterProvider.notifier).state = val,
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Local 👥',
                  value: 'local',
                  current: filter,
                  onSelect: (val) => ref.read(_matchFilterProvider.notifier).state = val,
                ),
              ],
            ),
          ),

          // Matches List
          Expanded(
            child: matchesAsync.when(
              loading: () => const Center(child: AppLoader()),
              error: (e, st) => Center(
                child: ErrorView(
                  message: 'Failed to load match history: $e',
                  onRetry: () => ref.invalidate(matchHistoryProvider),
                ),
              ),
              data: (matches) {
                final filtered = matches.where((m) {
                  if (filter == 'all') return true;
                  if (filter == 'online') return m.isOnline;
                  if (filter == 'ai') return m.isAi;
                  if (filter == 'local') return m.isLocal;
                  return true;
                }).toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('📜', style: TextStyle(fontSize: 64)),
                          const SizedBox(height: 16),
                          Text(
                            'NO MATCHES PLAYED YET',
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            style: GoogleFonts.luckiestGuy(
                              fontSize: 18,
                              color: AppColors.arenaGold,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            filter == 'all'
                                ? 'Play an Online, Bot, or Local match! Every match is automatically saved in your match history.'
                                : 'No matches found under this filter.',
                            maxLines: 3,
                            style: GoogleFonts.outfit(
                              fontSize: 14,
                              color: Colors.white70,
                              height: 1.3,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return RefreshIndicator(
                  color: AppColors.arenaGold,
                  backgroundColor: AppColors.arenaStone,
                  onRefresh: () async {
                    ref.invalidate(matchHistoryProvider);
                  },
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                    itemCount: filtered.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 12),
                    itemBuilder: (ctx, i) {
                      final match = filtered[i];
                      return _MatchCard(match: match);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.value,
    required this.current,
    required this.onSelect,
  });

  final String label;
  final String value;
  final String current;
  final void Function(String) onSelect;

  @override
  Widget build(BuildContext context) {
    final isSel = current == value;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onSelect(value);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSel ? AppColors.arenaGold : AppColors.arenaStone,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSel ? AppColors.arenaGold : Colors.white12,
            width: 1.5,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: GoogleFonts.luckiestGuy(
            fontSize: 12,
            color: isSel ? AppColors.arenaStone : Colors.white70,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}

class _MatchCard extends ConsumerWidget {
  const _MatchCard({required this.match});
  final MatchRecord match;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isWin = match.player1Won;
    final isDraw = match.isDraw;
    final isAi = match.isAi;

    Color outcomeColor;
    String outcomeText;
    if (isDraw) {
      outcomeColor = AppColors.arenaBlue;
      outcomeText = 'DRAW';
    } else if (isWin) {
      outcomeColor = AppColors.arenaGold;
      outcomeText = 'VICTORY';
    } else {
      outcomeColor = AppColors.danger;
      outcomeText = 'DEFEAT';
    }

    String modeLabel = match.gameType.toUpperCase();
    if (match.isAi) modeLabel = 'VS BOT';
    if (match.isLocal) modeLabel = 'LOCAL';

    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        ref.read(soundServiceProvider).play(AppSound.buttonClick);
        _MatchDetailSheet.show(context, match);
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.arenaStone,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: outcomeColor.withValues(alpha: 0.35),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top Row: Mode badge, Board size, Outcome
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.arenaBgBottom,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Text(
                    modeLabel,
                    style: GoogleFonts.luckiestGuy(
                      fontSize: 10,
                      color: Colors.white70,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${match.boardSize}x${match.boardSize} Grid',
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    color: Colors.white60,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: outcomeColor.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: outcomeColor, width: 1),
                  ),
                  child: Text(
                    outcomeText,
                    style: GoogleFonts.luckiestGuy(
                      fontSize: 11,
                      color: outcomeColor,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Scores & Players Row (Responsive text: wraps up to 2-3 lines without ellipsis truncation)
            Row(
              children: [
                // Player 1
                Expanded(
                  child: Row(
                    children: [
                      UserAvatar(
                        photoUrl: match.p1PhotoUrl,
                        name: match.p1Name,
                        size: 34,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          match.p1Name,
                          maxLines: 2,
                          softWrap: true,
                          style: GoogleFonts.luckiestGuy(
                            fontSize: 13,
                            color: Colors.white,
                            height: 1.2,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Score pill
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.arenaBgBottom,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Text(
                    '${match.p1Score} - ${match.p2Score}',
                    style: GoogleFonts.luckiestGuy(
                      fontSize: 18,
                      color: AppColors.arenaGold,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),

                // Player 2
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Text(
                          match.p2Name,
                          maxLines: 2,
                          softWrap: true,
                          textAlign: TextAlign.end,
                          style: GoogleFonts.luckiestGuy(
                            fontSize: 13,
                            color: Colors.white,
                            height: 1.2,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (isAi)
                        Container(
                          width: 34,
                          height: 34,
                          decoration: const BoxDecoration(
                            color: Color(0xFF673AB7),
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: const Text('🤖', style: TextStyle(fontSize: 18)),
                        )
                      else
                        UserAvatar(
                          photoUrl: match.p2PhotoUrl,
                          name: match.p2Name,
                          size: 34,
                        ),
                    ],
                  ),
                ),
              ],
            ),

            if (match.winnerName != null && !isDraw) ...[
              const SizedBox(height: 8),
              Text(
                '👑 Winner: ${match.winnerName}',
                maxLines: 2,
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.arenaGold,
                ),
              ),
            ],

            const SizedBox(height: 10),
            const Divider(color: Colors.white10, height: 1),
            const SizedBox(height: 10),

            // Bottom Action Row
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${match.totalMoves} moves · ${FormatUtils.relativeTime(match.playedAt)}',
                    maxLines: 2,
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      color: Colors.white60,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: AppColors.arenaGold,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.arenaGold.withValues(alpha: 0.35),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.receipt_long_rounded,
                        size: 15,
                        color: AppColors.arenaStone,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        'DETAILS',
                        style: GoogleFonts.luckiestGuy(
                          fontSize: 11,
                          color: AppColors.arenaStone,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MatchDetailSheet extends StatelessWidget {
  const _MatchDetailSheet({required this.match});
  final MatchRecord match;

  static void show(BuildContext context, MatchRecord match) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _MatchDetailSheet(match: match),
    );
  }

  @override
  Widget build(BuildContext context) {
    final boardLen = match.boardSize * match.boardSize;
    final finalBoard = List<String>.filled(boardLen, '');
    final finalLines = <SosLine, int>{};
    for (final m in match.moves) {
      if (m.position >= 0 && m.position < boardLen) {
        finalBoard[m.position] = m.letter;
      }
      for (final line in m.linesCreated) {
        finalLines[line] = m.playerIndex;
      }
    }

    final isWin = match.player1Won;
    final isDraw = match.isDraw;
    Color outcomeColor;
    String outcomeText;
    if (isDraw) {
      outcomeColor = AppColors.arenaBlue;
      outcomeText = 'DRAW';
    } else if (isWin) {
      outcomeColor = AppColors.arenaGold;
      outcomeText = 'VICTORY';
    } else {
      outcomeColor = AppColors.danger;
      outcomeText = 'DEFEAT';
    }

    String modeLabel = match.gameType.toUpperCase();
    if (match.isAi) modeLabel = 'VS BOT';
    if (match.isLocal) modeLabel = 'LOCAL';

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.90,
      ),
      decoration: BoxDecoration(
        color: AppColors.arenaBgBottom,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(
          color: AppColors.arenaGold.withValues(alpha: 0.35),
          width: 2,
        ),
      ),
      child: Column(
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 10, bottom: 6),
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'MATCH DETAILS',
                        style: GoogleFonts.luckiestGuy(
                          fontSize: 20,
                          color: AppColors.arenaGold,
                          letterSpacing: 1.0,
                        ),
                      ),
                      Text(
                        '${FormatUtils.relativeTime(match.playedAt)} · $modeLabel · ${match.boardSize}x${match.boardSize} Grid',
                        maxLines: 2,
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.white70),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),

          const Divider(color: Colors.white12, height: 1),

          // Scrollable Body
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Score Banner
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.arenaStone,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: outcomeColor.withValues(alpha: 0.4),
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: outcomeColor.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: outcomeColor, width: 1.2),
                        ),
                        child: Text(
                          outcomeText,
                          style: GoogleFonts.luckiestGuy(
                            fontSize: 14,
                            color: outcomeColor,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              children: [
                                UserAvatar(
                                  photoUrl: match.p1PhotoUrl,
                                  name: match.p1Name,
                                  size: 44,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  match.p1Name,
                                  textAlign: TextAlign.center,
                                  maxLines: 3,
                                  style: GoogleFonts.luckiestGuy(
                                    fontSize: 13,
                                    color: Colors.white,
                                    height: 1.2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: AppColors.arenaBgBottom,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.white12),
                              ),
                              child: Text(
                                '${match.p1Score} - ${match.p2Score}',
                                style: GoogleFonts.luckiestGuy(
                                  fontSize: 24,
                                  color: AppColors.arenaGold,
                                  letterSpacing: 1.5,
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: Column(
                              children: [
                                if (match.isAi)
                                  Container(
                                    width: 44,
                                    height: 44,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF673AB7),
                                      shape: BoxShape.circle,
                                    ),
                                    alignment: Alignment.center,
                                    child: const Text('🤖', style: TextStyle(fontSize: 24)),
                                  )
                                else
                                  UserAvatar(
                                    photoUrl: match.p2PhotoUrl,
                                    name: match.p2Name,
                                    size: 44,
                                  ),
                                const SizedBox(height: 6),
                                Text(
                                  match.p2Name,
                                  textAlign: TextAlign.center,
                                  maxLines: 3,
                                  style: GoogleFonts.luckiestGuy(
                                    fontSize: 13,
                                    color: Colors.white,
                                    height: 1.2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      if (match.winnerName != null && !isDraw) ...[
                        const SizedBox(height: 12),
                        Text(
                          '👑 Winner: ${match.winnerName}',
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          style: GoogleFonts.outfit(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.arenaGold,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 18),

                // Final Board Section
                Text(
                  'FINAL BOARD',
                  style: GoogleFonts.luckiestGuy(
                    fontSize: 16,
                    color: AppColors.arenaGold,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 8),

                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.arenaStone,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: GameBoardWidget(
                    size: match.boardSize,
                    board: finalBoard,
                    disabled: true,
                    sosLines: finalLines.keys.toList(),
                    lineColors: finalLines.map(
                      (line, pIdx) => MapEntry(
                        line,
                        AppColors.playerPalette[pIdx % AppColors.playerPalette.length],
                      ),
                    ),
                    onTap: (_) {},
                  ),
                ),

                const SizedBox(height: 18),

                // Move History Timeline
                Text(
                  'MOVE TIMELINE (${match.moves.length} MOVES)',
                  style: GoogleFonts.luckiestGuy(
                    fontSize: 16,
                    color: AppColors.arenaGold,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 8),

                if (match.moves.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.arenaStone,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Center(
                      child: Text(
                        'No detailed moves logged for this match.',
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          color: Colors.white60,
                        ),
                      ),
                    ),
                  )
                else
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.arenaStone,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: match.moves.length,
                      separatorBuilder: (ctx, idx) => const Divider(color: Colors.white10, height: 1),
                      itemBuilder: (ctx, idx) {
                        final m = match.moves[idx];
                        final isP1 = m.playerIndex == 0;
                        final playerName = isP1 ? match.p1Name : match.p2Name;
                        final color = isP1 ? AppColors.player1 : AppColors.player2;
                        final scored = m.sosCount > 0;

                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          child: Row(
                            children: [
                              Container(
                                width: 26,
                                height: 26,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.08),
                                  shape: BoxShape.circle,
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  '${idx + 1}',
                                  style: GoogleFonts.luckiestGuy(
                                    fontSize: 11,
                                    color: Colors.white60,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '$playerName placed "${m.letter}"',
                                      maxLines: 2,
                                      style: GoogleFonts.outfit(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: color,
                                      ),
                                    ),
                                    if (scored)
                                      Text(
                                        '⚡ Formed ${m.sosCount} SOS line${m.sosCount > 1 ? "s" : ""} (+${m.sosCount} pt${m.sosCount > 1 ? "s" : ""})',
                                        maxLines: 2,
                                        style: GoogleFonts.outfit(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w800,
                                          color: AppColors.arenaGold,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: color.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: color.withValues(alpha: 0.3)),
                                ),
                                child: Text(
                                  m.letter,
                                  style: GoogleFonts.luckiestGuy(
                                    fontSize: 14,
                                    color: color,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
