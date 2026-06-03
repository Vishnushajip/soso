import 'package:flutter/material.dart';

/// "Vivid Play" palette — joyful, competitive, mobile-first social gaming.
/// Royal Purple primary, Energetic Orange secondary, Vibrant Green tertiary,
/// Electric Blue accent. Backgrounds are lavender-tinted white, never pure.
/// Never hardcode a Color in screen code — pull from here.
class AppColors {
  AppColors._();

  // ---- Brand / action accents ------------------------------------------------
  static const primary = Color(0xFF6A38D4);
  static const onPrimary = Color(0xFFFFFFFF);
  static const primaryContainer = Color(0xFF8455EE);
  static const onPrimaryContainer = Color(0xFFFFFBFF);
  static const inversePrimary = Color(0xFFD0BCFF);

  static const secondary = Color(0xFFFD9D06);
  static const onSecondary = Color(0xFFFFFFFF);
  static const secondaryContainer = Color(0xFFFFDDBB);
  static const onSecondaryContainer = Color(0xFF653C00);

  static const tertiary = Color(0xFF008730);
  static const onTertiary = Color(0xFFFFFFFF);
  static const tertiaryContainer = Color(0xFF47E266);
  static const onTertiaryContainer = Color(0xFF00531A);

  static const accent = Color(0xFF3B82F6);

  // ---- Game-piece + semantic aliases (preserved API) -------------------------
  static const bg = Color(0xFFFEF7FF);
  static const board = Color(0xFFF2EBF8);
  static const grid = Color(0xFFCBC3D7);

  static const sColor = accent;
  static const oColor = secondary;

  static const success = tertiary;
  static const danger = Color(0xFFBA1A1A);
  static const highlight = primary;

  // ---- Surface ladder --------------------------------------------------------
  static const surface = Color(0xFFFEF7FF);
  static const surfaceDim = Color(0xFFDED7E4);
  static const surfaceBright = Color(0xFFFEF7FF);
  static const surfaceContainerLowest = Color(0xFFFFFFFF);
  static const surfaceContainerLow = Color(0xFFF8F1FE);
  static const surfaceContainer = Color(0xFFF2EBF8);
  static const surfaceContainerHigh = Color(0xFFEDE5F3);
  static const surfaceContainerHighest = Color(0xFFE7E0ED);
  static const surfaceAlt = surfaceContainerHigh;

  static const onSurface = Color(0xFF1D1A23);
  static const onSurfaceMuted = Color(0xFF494454);
  static const onSurfaceVariant = Color(0xFF494454);

  static const inverseSurface = Color(0xFF322F39);
  static const inverseOnSurface = Color(0xFFF5EEFB);

  static const outline = Color(0xFF7B7486);
  static const outlineVariant = Color(0xFFCBC3D7);
  static const divider = outlineVariant;

  // Deep indigo for high-contrast modal scrims (never pure black per spec).
  static const overlay = Color(0xCC2E1A47);

  static const error = danger;
  static const onError = Color(0xFFFFFFFF);
  static const errorContainer = Color(0xFFFFDAD6);
  static const onErrorContainer = Color(0xFF93000A);

  // ---- Arena (battle-board theme for the online match screen) ----------------
  // Dark "stone + lava" world used only on the game board. Pulled from here so
  // screen code never hardcodes a Color (per spec).
  static const arenaBgTop = Color(0xFF1A1230);     // upper night sky
  static const arenaBgBottom = Color(0xFF070410);  // deep pit
  static const arenaGlow = Color(0xFFFF6A00);       // lava glow
  static const arenaStone = Color(0xFF231B3D);      // board / panel stone
  static const arenaStoneEdge = Color(0xFF3A2F5C);  // raised stone border
  static const arenaCell = Color(0xFF150F28);       // empty grid socket
  static const arenaGold = Color(0xFFFFC857);       // banners / titles
  static const arenaBlue = Color(0xFF2EA8FF);       // player 1 banner
  static const arenaPink = Color(0xFFFF3D9A);       // player 2 banner
  static const onArena = Color(0xFFF1ECFF);         // primary text on arena
  static const onArenaMuted = Color(0xFF9C92C7);    // secondary text on arena

  // ---- Player accents (visually distinct, 2–4 player local games) -----------
  static const player1 = accent;     // Electric Blue
  static const player2 = secondary;  // Energetic Orange
  static const player3 = primary;    // Royal Purple
  static const player4 = tertiary;   // Vibrant Green

  static const List<Color> playerPalette = [player1, player2, player3, player4];
}
