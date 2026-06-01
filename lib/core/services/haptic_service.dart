import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/app_constants.dart';

enum HapticEvent { tap, point, sos, win, lose, error, selection }

/// Tactile feedback layer. Mirrors [SoundService] structure so callers can
/// pair `sound.play(...)` with `haptic.fire(...)`. Uses Flutter's built-in
/// [HapticFeedback] API — no extra plugin required. Silently no-ops if the
/// platform doesn't support haptics (web, desktop) so gameplay never crashes.
class HapticService {
  HapticService(this._prefs);
  final SharedPreferences _prefs;
  bool _enabled = true;

  bool get enabled => _enabled;

  Future<void> init() async {
    _enabled = _prefs.getBool(AppConstants.prefsHapticsEnabled) ?? true;
  }

  Future<void> setEnabled(bool value) async {
    _enabled = value;
    await _prefs.setBool(AppConstants.prefsHapticsEnabled, value);
  }

  Future<void> fire(HapticEvent event) async {
    if (!_enabled) return;
    try {
      switch (event) {
        case HapticEvent.tap:
        case HapticEvent.point:
          await HapticFeedback.lightImpact();
        case HapticEvent.sos:
          await HapticFeedback.mediumImpact();
        case HapticEvent.win:
          await HapticFeedback.heavyImpact();
          await Future<void>.delayed(const Duration(milliseconds: 120));
          await HapticFeedback.heavyImpact();
          await Future<void>.delayed(const Duration(milliseconds: 120));
          await HapticFeedback.mediumImpact();
        case HapticEvent.lose:
          await HapticFeedback.heavyImpact();
        case HapticEvent.error:
          await HapticFeedback.vibrate();
        case HapticEvent.selection:
          await HapticFeedback.selectionClick();
      }
    } catch (_) {
      // unsupported platform — ignore
    }
  }
}
