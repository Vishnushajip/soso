import 'package:flutter/material.dart';

/// Centralized palette for SOS Arena. Never hardcode a Color in screen code.
class AppColors {
  AppColors._();

  static const bg = Color(0xFF0F172A);
  static const board = Color(0xFF1E293B);
  static const grid = Color(0xFF334155);

  static const sColor = Color(0xFF38BDF8);
  static const oColor = Color(0xFFF59E0B);

  static const success = Color(0xFF22C55E);
  static const danger = Color(0xFFEF4444);
  static const highlight = Color(0xFFA855F7);

  // Derived / supporting tones, kept here so nothing leaks outside.
  static const surface = Color(0xFF1E293B);
  static const surfaceAlt = Color(0xFF273449);
  static const onSurface = Color(0xFFE2E8F0);
  static const onSurfaceMuted = Color(0xFF94A3B8);
  static const divider = Color(0xFF334155);
  static const overlay = Color(0xCC0F172A);

  // Player accents for 2-4 player local games.
  static const player1 = sColor;
  static const player2 = oColor;
  static const player3 = highlight;
  static const player4 = success;

  static const List<Color> playerPalette = [player1, player2, player3, player4];
}
