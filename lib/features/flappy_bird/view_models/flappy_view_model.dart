import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:soso/core/theme/app_colors.dart';

enum FlappyStatus { idle, playing, gameOver }

enum FlappyDifficulty { easy, medium, hard }

class FlappyDifficultyConfig {
  const FlappyDifficultyConfig({
    required this.difficulty,
    required this.label,
    required this.tagline,
    required this.icon,
    required this.color,
    required this.level,
    required this.baseGap,
    required this.minGap,
    required this.baseSpacing,
    required this.minSpacing,
    required this.baseSpeed,
    required this.maxSpeed,
  });

  final FlappyDifficulty difficulty;
  final String label;
  final String tagline;
  final IconData icon;
  final Color color;
  final int level;
  final double baseGap;
  final double minGap;
  final double baseSpacing;
  final double minSpacing;
  final double baseSpeed;
  final double maxSpeed;

  static const easy = FlappyDifficultyConfig(
    difficulty: FlappyDifficulty.easy,
    label: 'Easy',
    tagline: 'Wide gaps, gentle pace',
    icon: Icons.spa_rounded,
    color: AppColors.tertiary,
    level: 1,
    baseGap: 0.40,
    minGap: 0.33,
    baseSpacing: 0.88,
    minSpacing: 0.64,
    baseSpeed: 0.0050,
    maxSpeed: 0.0078,
  );

  static const medium = FlappyDifficultyConfig(
    difficulty: FlappyDifficulty.medium,
    label: 'Medium',
    tagline: 'Balanced challenge',
    icon: Icons.bolt_rounded,
    color: AppColors.secondary,
    level: 2,
    baseGap: 0.34,
    minGap: 0.27,
    baseSpacing: 0.70,
    minSpacing: 0.51,
    baseSpeed: 0.0059,
    maxSpeed: 0.0092,
  );

  static const hard = FlappyDifficultyConfig(
    difficulty: FlappyDifficulty.hard,
    label: 'Hard',
    tagline: 'Tight gaps, full throttle',
    icon: Icons.whatshot_rounded,
    color: AppColors.primary,
    level: 3,
    baseGap: 0.29,
    minGap: 0.23,
    baseSpacing: 0.56,
    minSpacing: 0.43,
    baseSpeed: 0.0069,
    maxSpeed: 0.0106,
  );

  static const all = [easy, medium, hard];

  static FlappyDifficultyConfig of(FlappyDifficulty d) {
    switch (d) {
      case FlappyDifficulty.easy:
        return easy;
      case FlappyDifficulty.medium:
        return medium;
      case FlappyDifficulty.hard:
        return hard;
    }
  }
}

const double kPipeWidth = 0.16;
const double kBirdX = 0.28;
const double kBirdRadius = 0.045;
const double kGravity = 0.00045;
const double kFlapImpulse = -0.011;
const double kMaxFall = 0.025;

class Pipe {
  Pipe({required this.x, required this.gapCenter, required this.gap});
  double x;
  final double gapCenter;
  final double gap;
  bool scored = false;
}

class FlappyState {
  const FlappyState({
    required this.status,
    required this.birdY,
    required this.birdVel,
    required this.pipes,
    required this.score,
    required this.best,
  });

  final FlappyStatus status;
  final double birdY;
  final double birdVel;
  final List<Pipe> pipes;
  final int score;
  final int best;

  factory FlappyState.initial() => const FlappyState(
    status: FlappyStatus.idle,
    birdY: 0.5,
    birdVel: 0,
    pipes: [],
    score: 0,
    best: 0,
  );

  FlappyState copyWith({
    FlappyStatus? status,
    double? birdY,
    double? birdVel,
    List<Pipe>? pipes,
    int? score,
    int? best,
  }) {
    return FlappyState(
      status: status ?? this.status,
      birdY: birdY ?? this.birdY,
      birdVel: birdVel ?? this.birdVel,
      pipes: pipes ?? this.pipes,
      score: score ?? this.score,
      best: best ?? this.best,
    );
  }
}

class FlappyController extends StateNotifier<FlappyState> {
  FlappyController(this.config) : super(FlappyState.initial());

  final FlappyDifficultyConfig config;
  final _rng = Random();
  Timer? _ticker;

  double get _gapNow => (config.baseGap - state.score * 0.0055).clamp(
    config.minGap,
    config.baseGap,
  );

  double get _spacingNow => (config.baseSpacing - state.score * 0.014).clamp(
    config.minSpacing,
    config.baseSpacing,
  );

  double get _speedNow => (config.baseSpeed + state.score * 0.00019).clamp(
    config.baseSpeed,
    config.maxSpeed,
  );

  void start() {
    _ticker?.cancel();
    state = FlappyState.initial().copyWith(
      status: FlappyStatus.playing,
      best: state.best,
      pipes: [_spawnPipe(1.0), _spawnPipe(1.0 + config.baseSpacing)],
    );
    _ticker = Timer.periodic(const Duration(milliseconds: 16), (_) => _tick());
  }

  void flap() {
    if (state.status == FlappyStatus.idle ||
        state.status == FlappyStatus.gameOver) {
      start();
      return;
    }
    state = state.copyWith(birdVel: kFlapImpulse);
  }

  Pipe _spawnPipe(double x) {
    final gap = _gapNow;
    final center = (gap / 2 + 0.05) + _rng.nextDouble() * (1.0 - gap - 0.10);
    return Pipe(x: x, gapCenter: center, gap: gap);
  }

  void _tick() {
    if (state.status != FlappyStatus.playing) return;

    final vel = (state.birdVel + kGravity).clamp(-1.0, kMaxFall);
    final y = state.birdY + vel;

    final speed = _speedNow;
    final pipes = state.pipes.map((p) => p..x -= speed).toList();
    var score = state.score;

    for (final p in pipes) {
      if (!p.scored && p.x + kPipeWidth < kBirdX) {
        p.scored = true;
        score++;
      }
    }

    pipes.removeWhere((p) => p.x + kPipeWidth < -0.05);
    if (pipes.isNotEmpty) {
      final last = pipes.last;
      if (last.x < 1.0 - _spacingNow) {
        pipes.add(_spawnPipe(last.x + _spacingNow));
      }
    }

    bool dead = false;
    if (y - kBirdRadius <= 0 || y + kBirdRadius >= 1.0) dead = true;

    for (final p in pipes) {
      final withinX =
          kBirdX + kBirdRadius > p.x &&
          kBirdX - kBirdRadius < p.x + kPipeWidth;
      if (withinX) {
        final gapTop = p.gapCenter - p.gap / 2;
        final gapBottom = p.gapCenter + p.gap / 2;
        if (y - kBirdRadius < gapTop || y + kBirdRadius > gapBottom) {
          dead = true;
        }
      }
    }

    if (dead) {
      _ticker?.cancel();
      state = state.copyWith(
        status: FlappyStatus.gameOver,
        best: max(state.best, score),
        score: score,
        birdY: y.clamp(0.0, 1.0),
        birdVel: vel,
        pipes: pipes,
      );
      return;
    }

    state = state.copyWith(birdY: y, birdVel: vel, pipes: pipes, score: score);
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }
}

final flappyControllerProvider = StateNotifierProvider.autoDispose
    .family<FlappyController, FlappyState, FlappyDifficulty>(
      (ref, difficulty) =>
          FlappyController(FlappyDifficultyConfig.of(difficulty)),
    );
