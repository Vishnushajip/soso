import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/app_constants.dart';
import '../utils/logger.dart';

enum AppSound {
  sos('sos.mp3'),
  point('point.mp3'),
  win('win.mp3'),
  lose('lose.mp3'),
  friendSent('friend_sent.mp3'),
  friendAccept('friend_accept.mp3'),
  notify('notify.mp3'),
  rankUp('rank_up.mp3'),
  versus('versus.mp3');

  final String fileName;
  const AppSound(this.fileName);
}

/// Centralized sound player. Reads the on/off preference once at init,
/// and silently no-ops if an asset file is missing — so the game
/// keeps working before the user has dropped sound files in.
class SoundService {
  SoundService(this._prefs);
  final SharedPreferences _prefs;
  final AudioPlayer _player = AudioPlayer();
  bool _enabled = true;

  bool get enabled => _enabled;

  Future<void> init() async {
    _enabled = _prefs.getBool(AppConstants.prefsSoundEnabled) ?? true;
    await _player.setReleaseMode(ReleaseMode.stop);
  }

  Future<void> setEnabled(bool value) async {
    _enabled = value;
    await _prefs.setBool(AppConstants.prefsSoundEnabled, value);
  }

  Future<void> play(AppSound sound) async {
    if (!_enabled) return;
    try {
      await _player.stop();
      await _player.play(AssetSource('sounds/${sound.fileName}'));
    } catch (e) {
      // Asset missing or platform unsupported — never let audio crash gameplay.
      appLogger.d('Sound ${sound.fileName} skipped: $e');
    }
  }

  Future<void> dispose() => _player.dispose();
}
