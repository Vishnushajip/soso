import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/user_avatar.dart';

/// Painted dark "stone + lava" arena backdrop shared by the online and local
/// match screens.
class ArenaBackground extends StatelessWidget {
  const ArenaBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.arenaBgTop, AppColors.arenaBgBottom],
        ),
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0, 0.3),
            radius: 1.1,
            colors: [Color(0x33FF6A00), Color(0x00FF6A00)],
            stops: [0.0, 0.72],
          ),
        ),
        child: SizedBox.expand(),
      ),
    );
  }
}

/// Lightweight player descriptor for the battle header (works for both online
/// `GameRoom` players and local match players).
class BattlePlayer {
  const BattlePlayer({required this.name, required this.score, this.photoUrl});
  final String name;
  final int score;
  final String? photoUrl;
}

/// Top "VS" battle banner. 1v1 matches get the mirrored hero layout; other
/// player counts fall back to a scrollable row of banners so no player is
/// ever hidden. [activeIndex] is the player to highlight (-1 = none).
class BattleHeader extends StatelessWidget {
  const BattleHeader({
    super.key,
    required this.players,
    required this.activeIndex,
  });

  final List<BattlePlayer> players;
  final int activeIndex;

  @override
  Widget build(BuildContext context) {
    int maxScore = 1;
    for (final p in players) {
      if (p.score > maxScore) maxScore = p.score;
    }

    Color colorFor(int i) =>
        AppColors.playerPalette[i % AppColors.playerPalette.length];

    if (players.length == 2) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: _PlayerBattleCard(
              name: players[0].name,
              photoUrl: players[0].photoUrl,
              score: players[0].score,
              color: colorFor(0),
              isCurrentTurn: activeIndex == 0,
              fill: players[0].score / maxScore,
              mirrored: false,
            ),
          ),
          const _VsBadge(),
          Expanded(
            child: _PlayerBattleCard(
              name: players[1].name,
              photoUrl: players[1].photoUrl,
              score: players[1].score,
              color: colorFor(1),
              isCurrentTurn: activeIndex == 1,
              fill: players[1].score / maxScore,
              mirrored: true,
            ),
          ),
        ],
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (var i = 0; i < players.length; i++) ...[
            SizedBox(
              width: 180,
              child: _PlayerBattleCard(
                name: players[i].name,
                photoUrl: players[i].photoUrl,
                score: players[i].score,
                color: colorFor(i),
                isCurrentTurn: activeIndex == i,
                fill: players[i].score / maxScore,
                mirrored: false,
              ),
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }
}

/// A single player's battle banner: gradient plate, ringed avatar, trophy +
/// name, and a glowing energy bar tracking their score against the leader.
class _PlayerBattleCard extends StatelessWidget {
  const _PlayerBattleCard({
    required this.name,
    required this.photoUrl,
    required this.score,
    required this.color,
    required this.isCurrentTurn,
    required this.fill,
    required this.mirrored,
  });

  final String name;
  final String? photoUrl;
  final int score;
  final Color color;
  final bool isCurrentTurn;
  final double fill;
  final bool mirrored;

  @override
  Widget build(BuildContext context) {
    final avatar = Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withValues(alpha: 0.85), width: 2),
        boxShadow: [
          BoxShadow(color: color.withValues(alpha: 0.6), blurRadius: 8),
        ],
      ),
      child: UserAvatar(name: name, photoUrl: photoUrl, size: 32),
    );

    final info = Column(
      crossAxisAlignment:
          mirrored ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment:
              mirrored ? MainAxisAlignment.end : MainAxisAlignment.start,
          children: [
            const Icon(Icons.emoji_events, size: 13, color: AppColors.arenaGold),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: mirrored ? TextAlign.right : TextAlign.left,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        // Energy / score bar.
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Container(
            height: 8,
            color: Colors.black.withValues(alpha: 0.35),
            child: Align(
              alignment:
                  mirrored ? Alignment.centerRight : Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: fill.clamp(0.04, 1.0),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color.lerp(color, Colors.white, 0.4)!, color],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          child: Text(
            '$score pts',
            key: ValueKey(score),
            style: TextStyle(
              color: AppColors.onArena.withValues(alpha: 0.85),
              fontWeight: FontWeight.w800,
              fontSize: 11,
            ),
          ),
        ),
      ],
    );

    final children = <Widget>[
      avatar,
      const SizedBox(width: 10),
      Expanded(child: info),
    ];

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 220),
      opacity: isCurrentTurn ? 1.0 : 0.6,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: mirrored ? Alignment.centerRight : Alignment.centerLeft,
            end: mirrored ? Alignment.centerLeft : Alignment.centerRight,
            colors: [
              color.withValues(alpha: 0.55),
              color.withValues(alpha: 0.12),
            ],
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isCurrentTurn ? color : color.withValues(alpha: 0.3),
            width: isCurrentTurn ? 2.2 : 1,
          ),
          boxShadow: isCurrentTurn
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.45),
                    blurRadius: 14,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        child: Row(
          children: mirrored ? children.reversed.toList() : children,
        ),
      ),
    );
  }
}

/// The central gold "VS" emblem between the two battle banners.
class _VsBadge extends StatelessWidget {
  const _VsBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 6),
      padding: const EdgeInsets.all(9),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.arenaGold, AppColors.arenaGlow],
        ),
        border: Border.all(color: Colors.white.withValues(alpha: 0.6), width: 2),
        boxShadow: [
          BoxShadow(
            color: AppColors.arenaGlow.withValues(alpha: 0.5),
            blurRadius: 12,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Text(
        'VS',
        style: GoogleFonts.luckiestGuy(
          fontSize: 14,
          color: Colors.white,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
