import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:universal_html/html.dart' as html;

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
  versus('versus.mp3'),
  flap('flappy_bird_sound.mp3'),
  buttonClick('button_click.mp3');

  final String fileName;
  const AppSound(this.fileName);
}

class SoundService with WidgetsBindingObserver {
  SoundService(this._prefs) {
    _soundEnabled = _prefs.getBool(AppConstants.prefsSoundEnabled) ?? true;
    _soundVolume = _prefs.getDouble(AppConstants.prefsSoundVolume) ?? 1.0;
    _musicEnabled = _prefs.getBool(AppConstants.prefsMusicEnabled) ?? true;
    _musicVolume = _prefs.getDouble(AppConstants.prefsMusicVolume) ?? 0.5;
  }

  final SharedPreferences _prefs;
  final Map<AppSound, AudioPlayer> _players = {};

  AudioPlayer? _bgmPlayer;
  bool _bgmPlaying = false;
  bool _bgmStarting = false;

  bool _soundEnabled = true;
  double _soundVolume = 1.0;

  bool _musicEnabled = true;
  double _musicVolume = 0.5;

  int _activeGameScreens = 0;
  bool _ready = false;

  bool get enabled => _soundEnabled;
  bool get soundEnabled => _soundEnabled;
  double get soundVolume => _soundVolume;

  bool get musicEnabled => _musicEnabled;
  double get musicVolume => _musicVolume;
  bool get inGame => _activeGameScreens > 0;

  Future<void> init() async {
    _soundEnabled = _prefs.getBool(AppConstants.prefsSoundEnabled) ?? true;
    _soundVolume = _prefs.getDouble(AppConstants.prefsSoundVolume) ?? 1.0;
    _musicEnabled = _prefs.getBool(AppConstants.prefsMusicEnabled) ?? true;
    _musicVolume = _prefs.getDouble(AppConstants.prefsMusicVolume) ?? 0.5;

    WidgetsBinding.instance.addObserver(this);

    if (!kIsWeb) {
      try {
        await AudioPlayer.global.setAudioContext(
          AudioContext(
            android: const AudioContextAndroid(
              isSpeakerphoneOn: false,
              stayAwake: false,
              contentType: AndroidContentType.music,
              usageType: AndroidUsageType.game,
              audioFocus: AndroidAudioFocus.gainTransientMayDuck,
            ),
            iOS: AudioContextIOS(
              category: AVAudioSessionCategory.ambient,
              options: const {AVAudioSessionOptions.mixWithOthers},
            ),
          ),
        );
      } catch (e) {
        appLogger.d('Global AudioContext setup skipped: $e');
      }
    }

    if (kIsWeb) {
      try {
        html.window.onClick.first.then((_) => onFirstUserInteraction());
        html.window.onTouchStart.first.then((_) => onFirstUserInteraction());
        html.window.onKeyDown.first.then((_) => onFirstUserInteraction());
      } catch (e) {
        appLogger.d('Web DOM audio listener registration skipped: $e');
      }
    }

    try {
      final bgm = AudioPlayer();
      await _configureBgmPlayer(bgm);
      await bgm.setReleaseMode(ReleaseMode.loop);
      await bgm.setVolume(_musicEnabled ? _musicVolume : 0.0);
      await bgm.setSource(AssetSource('sounds/theme.mp3'));
      _bgmPlayer = bgm;
    } catch (e) {
      appLogger.d('Theme BGM preload skipped: $e');
    }

    await Future.wait(
      AppSound.values.map((sound) async {
        try {
          final player = AudioPlayer();
          await _configureSfxPlayer(player);
          await player.setReleaseMode(ReleaseMode.stop);
          await player.setVolume(_soundVolume);
          await player.setSource(AssetSource('sounds/${sound.fileName}'));
          _players[sound] = player;
        } catch (e) {
          appLogger.d('Sound ${sound.fileName} preload skipped: $e');
        }
      }),
    );
    _ready = true;
  }

  Future<void> _configureBgmPlayer(AudioPlayer player) async {
    if (!kIsWeb) {
      try {
        await player.setAudioContext(
          AudioContext(
            android: const AudioContextAndroid(
              isSpeakerphoneOn: false,
              stayAwake: false,
              contentType: AndroidContentType.music,
              usageType: AndroidUsageType.game,
              audioFocus: AndroidAudioFocus.gain,
            ),
            iOS: AudioContextIOS(
              category: AVAudioSessionCategory.ambient,
              options: const {AVAudioSessionOptions.mixWithOthers},
            ),
          ),
        );
      } catch (e) {
        appLogger.d('BGM player AudioContext skipped: $e');
      }
    }
  }

  Future<void> _configureSfxPlayer(AudioPlayer player) async {
    if (!kIsWeb) {
      try {
        await player.setAudioContext(
          AudioContext(
            android: const AudioContextAndroid(
              isSpeakerphoneOn: false,
              stayAwake: false,
              contentType: AndroidContentType.sonification,
              usageType: AndroidUsageType.game,
              audioFocus: AndroidAudioFocus.none,
            ),
            iOS: AudioContextIOS(
              category: AVAudioSessionCategory.ambient,
              options: const {AVAudioSessionOptions.mixWithOthers},
            ),
          ),
        );
      } catch (e) {
        appLogger.d('SFX player AudioContext skipped: $e');
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        _pauseBgmInternal();
        break;
      case AppLifecycleState.resumed:
        if (_musicEnabled && _activeGameScreens == 0) {
          startBgm();
        }
        break;
    }
  }

  Future<void> startBgm() async {
    if (!_musicEnabled || _activeGameScreens > 0) {
      await _stopBgmInternal();
      return;
    }
    if (_bgmStarting) return;
    if (_bgmPlayer != null && _bgmPlayer!.state == PlayerState.playing) {
      _bgmPlaying = true;
      return;
    }

    _bgmStarting = true;
    try {
      final player = _bgmPlayer ?? AudioPlayer();
      _bgmPlayer = player;
      await _configureBgmPlayer(player);

      if (!_musicEnabled || _activeGameScreens > 0) {
        await _stopBgmInternal();
        return;
      }

      await player.setReleaseMode(ReleaseMode.loop);
      await player.setVolume(_musicVolume);

      if (!_musicEnabled || _activeGameScreens > 0) {
        await _stopBgmInternal();
        return;
      }

      if (player.source != null) {
        try {
          await player.resume();
        } catch (_) {
          if (!_musicEnabled || _activeGameScreens > 0) {
            await _stopBgmInternal();
            return;
          }
          await player.play(AssetSource('sounds/theme.mp3'));
        }
      } else {
        await player.play(AssetSource('sounds/theme.mp3'));
      }

      if (!_musicEnabled || _activeGameScreens > 0) {
        await _stopBgmInternal();
        return;
      }

      _bgmPlaying = true;
    } catch (e) {
      _bgmPlaying = false;
      appLogger.d('Theme BGM start skipped (e.g. autoplay gesture needed): $e');
    } finally {
      _bgmStarting = false;
    }
  }

  Future<void> _stopBgmInternal() async {
    _bgmPlaying = false;
    _bgmStarting = false;
    if (_bgmPlayer != null) {
      try {
        await _bgmPlayer!.setVolume(0);
        await _bgmPlayer!.stop();
        await _bgmPlayer!.pause();
      } catch (e) {
        appLogger.d('Theme BGM stop skipped: $e');
      }
    }

    if (kIsWeb) {
      try {
        final audios = html.document.querySelectorAll('audio');
        for (final el in audios) {
          if (el is html.AudioElement) {
            final src = (el.src.isNotEmpty ? el.src : el.currentSrc).toLowerCase();
            if (src.contains('theme') || el.loop) {
              el.pause();
              el.currentTime = 0;
              el.volume = 0;
            }
          }
        }
      } catch (_) {}
    }
  }

  Future<void> _pauseBgmInternal() async {
    _bgmPlaying = false;
    if (_bgmPlayer == null) return;
    try {
      await _bgmPlayer!.setVolume(0);
      await _bgmPlayer!.pause();
    } catch (e) {
      appLogger.d('Theme BGM pause skipped: $e');
    }

    if (kIsWeb) {
      try {
        final audios = html.document.querySelectorAll('audio');
        for (final el in audios) {
          if (el is html.AudioElement) {
            final src = (el.src.isNotEmpty ? el.src : el.currentSrc).toLowerCase();
            if (src.contains('theme') || el.loop) {
              el.pause();
              el.volume = 0;
            }
          }
        }
      } catch (_) {}
    }
  }

  Future<void> pauseBgm() async => _pauseBgmInternal();

  Future<void> stopBgm() async => _stopBgmInternal();

  void onGameStarted() {
    _activeGameScreens++;
    _pauseBgmInternal();
  }

  void onGameEnded() {
    if (_activeGameScreens > 0) {
      _activeGameScreens--;
    }
    if (_activeGameScreens == 0 && _musicEnabled) {
      startBgm();
    }
  }

  void onFirstUserInteraction() {
    if (_musicEnabled && _activeGameScreens == 0 && !_bgmPlaying) {
      startBgm();
    }
  }

  Future<void> setMusicEnabled(bool value) async {
    _musicEnabled = value;
    await _prefs.setBool(AppConstants.prefsMusicEnabled, value);
    if (value) {
      if (_activeGameScreens == 0) {
        await startBgm();
      }
    } else {
      await _stopBgmInternal();
    }
  }

  Future<void> setMusicVolume(double volume) async {
    _musicVolume = volume.clamp(0.0, 1.0);
    await _prefs.setDouble(AppConstants.prefsMusicVolume, _musicVolume);
    try {
      if (_musicEnabled && _bgmPlaying) {
        await _bgmPlayer?.setVolume(_musicVolume);
      } else {
        await _bgmPlayer?.setVolume(0);
      }
    } catch (e) {
      appLogger.d('Theme BGM volume update skipped: $e');
    }
  }

  Future<void> setSoundEnabled(bool value) async {
    _soundEnabled = value;
    await _prefs.setBool(AppConstants.prefsSoundEnabled, value);
  }

  Future<void> setEnabled(bool value) => setSoundEnabled(value);

  Future<void> setSoundVolume(double volume) async {
    _soundVolume = volume.clamp(0.0, 1.0);
    await _prefs.setDouble(AppConstants.prefsSoundVolume, _soundVolume);
    for (final player in _players.values) {
      try {
        await player.setVolume(_soundVolume);
      } catch (_) {}
    }
  }

  Future<void> play(AppSound sound) async {
    if (!_soundEnabled || !_ready) return;

    var player = _players[sound];
    if (player == null) {
      try {
        player = AudioPlayer();
        await _configureSfxPlayer(player);
        await player.setReleaseMode(ReleaseMode.stop);
        await player.setVolume(_soundVolume);
        await player.setSource(AssetSource('sounds/${sound.fileName}'));
        _players[sound] = player;
      } catch (e) {
        appLogger.d('Sound ${sound.fileName} setup skipped: $e');
        return;
      }
    }

    try {
      await player.setVolume(_soundVolume);
      if (player.state == PlayerState.playing) {
        await player.seek(Duration.zero);
      } else {
        await player.seek(Duration.zero);
        await player.resume();
      }
    } catch (e) {
      try {
        await player.play(
          AssetSource('sounds/${sound.fileName}'),
          volume: _soundVolume,
        );
      } catch (e2) {
        appLogger.d('Sound ${sound.fileName} playback skipped: $e2');
      }
    }
  }

  Future<void> stop(AppSound sound) async {
    if (!_ready) return;
    final player = _players[sound];
    if (player == null) return;
    try {
      await player.stop();
    } catch (e) {
      appLogger.d('Sound ${sound.fileName} stop skipped: $e');
    }
  }

  Future<void> dispose() async {
    WidgetsBinding.instance.removeObserver(this);
    if (_bgmPlayer != null) {
      try {
        await _bgmPlayer!.dispose();
      } catch (_) {}
      _bgmPlayer = null;
    }
    for (final player in _players.values) {
      try {
        await player.dispose();
      } catch (_) {}
    }
    _players.clear();
  }
}
