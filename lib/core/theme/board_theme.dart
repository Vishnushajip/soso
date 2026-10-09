import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:soso/core/providers/firebase_providers.dart';

import '../../core/theme/app_colors.dart';

class BoardTheme {
  final String id;
  final String name;
  final Color boardBgColor;
  final Color boardBorderColor;
  final Color cellBgColor;
  final Color sColor;
  final Color oColor;
  final Color highlightColor;
  final bool isGlossy;

  const BoardTheme({
    required this.id,
    required this.name,
    required this.boardBgColor,
    required this.boardBorderColor,
    required this.cellBgColor,
    required this.sColor,
    required this.oColor,
    required this.highlightColor,
    required this.isGlossy,
  });

  static const classic = BoardTheme(
    id: 'classic',
    name: 'Classic',
    boardBgColor: AppColors.board,
    boardBorderColor: AppColors.divider,
    cellBgColor: AppColors.grid,
    sColor: AppColors.sColor,
    oColor: AppColors.oColor,
    highlightColor: AppColors.primary,
    isGlossy: false,
  );

  static const arena = BoardTheme(
    id: 'arena',
    name: 'Dark Arena',
    boardBgColor: AppColors.arenaStone,
    boardBorderColor: AppColors.arenaStoneEdge,
    cellBgColor: AppColors.arenaCell,
    sColor: AppColors.sColor,
    oColor: AppColors.oColor,
    highlightColor: AppColors.arenaGold,
    isGlossy: true,
  );

  static const ice = BoardTheme(
    id: 'ice',
    name: 'Ice Frost',
    boardBgColor: Color(0xFFE0F7FA), // Light cyan
    boardBorderColor: Color(0xFFB2EBF2),
    cellBgColor: Color(0xFFB2EBF2), // Slightly darker cyan
    sColor: Color(0xFF0277BD), // Blue
    oColor: Color(0xFF00695C), // Teal
    highlightColor: Color(0xFF4FC3F7),
    isGlossy: true,
  );

  static const sun = BoardTheme(
    id: 'sun',
    name: 'Solar Flare',
    boardBgColor: Color(0xFFFFF3E0), // Light orange
    boardBorderColor: Color(0xFFFFE0B2),
    cellBgColor: Color(0xFFFFCC80),
    sColor: Color(0xFFD84315), // Deep red/orange
    oColor: Color(0xFFEF6C00),
    highlightColor: Color(0xFFFFCA28),
    isGlossy: true,
  );

  static const marble = BoardTheme(
    id: 'marble',
    name: 'White Marble',
    boardBgColor: Color(0xFFFAFAFA),
    boardBorderColor: Color(0xFFE0E0E0),
    cellBgColor: Color(0xFFEEEEEE),
    sColor: Color(0xFF212121), // Near black
    oColor: Color(0xFFD4AF37), // Metallic Gold
    highlightColor: Color(0xFFD4AF37),
    isGlossy: false,
  );

  static const allThemes = [classic, arena, ice, sun, marble];

  static BoardTheme fromId(String id) {
    return allThemes.firstWhere((t) => t.id == id, orElse: () => classic);
  }
}

class BoardThemeNotifier extends StateNotifier<BoardTheme> {
  final SharedPreferences _prefs;
  static const _key = 'selected_board_theme';

  BoardThemeNotifier(this._prefs) : super(_loadTheme(_prefs));

  static BoardTheme _loadTheme(SharedPreferences prefs) {
    final savedId = prefs.getString(_key);
    if (savedId != null) {
      return BoardTheme.fromId(savedId);
    }
    return BoardTheme.classic;
  }

  void setTheme(BoardTheme theme) {
    state = theme;
    _prefs.setString(_key, theme.id);
  }
}

final boardThemeProvider = StateNotifierProvider<BoardThemeNotifier, BoardTheme>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return BoardThemeNotifier(prefs);
});
