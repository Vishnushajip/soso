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
///
/// Each sound gets its own preloaded [AudioPlayer]. This matters on web:
/// reusing a single player and re-playing an [AssetSource] every time
/// forces the browser to re-fetch and re-decode the file on each call,
/// which makes effects stutter, arrive late, or silently drop. By setting
/// the source once and replaying with seek(0)+resume(), the audio is
/// cached and fires instantly on every platform — and independent sounds
/// no longer cut each other off.
class SoundService {
  SoundService(this._prefs);
  final SharedPreferences _prefs;
  final Map<AppSound, AudioPlayer> _players = {};
  bool _enabled = true;
  bool _ready = false;

  bool get enabled => _enabled;

  Future<void> init() async {
    _enabled = _prefs.getBool(AppConstants.prefsSoundEnabled) ?? true;

    // Preload every sound into its own player so playback is instant and
    // never refetches the asset (critical for smooth web audio).
    await Future.wait(
      AppSound.values.map((sound) async {
        try {
          final player = AudioPlayer();
          await player.setReleaseMode(ReleaseMode.stop);
          await player.setSource(AssetSource('sounds/${sound.fileName}'));
          _players[sound] = player;
        } catch (e) {
          // Asset missing or platform unsupported — skip this one.
          appLogger.d('Sound ${sound.fileName} preload skipped: $e');
        }
      }),
    );
    _ready = true;
  }

  Future<void> setEnabled(bool value) async {
    _enabled = value;
    await _prefs.setBool(AppConstants.prefsSoundEnabled, value);
  }

  Future<void> play(AppSound sound) async {
    if (!_enabled || !_ready) return;
    final player = _players[sound];
    if (player == null) return;
    try {
      // Restart from the beginning, then resume the already-loaded source.
      // No new fetch/decode happens here — so web effects play reliably.
      await player.seek(Duration.zero);
      await player.resume();
    } catch (e) {
      // Never let audio crash gameplay (e.g. web autoplay policy before a gesture).
      appLogger.d('Sound ${sound.fileName} skipped: $e');
    }
  }

  Future<void> dispose() async {
    for (final player in _players.values) {
      await player.dispose();
    }
    _players.clear();
  }
}
