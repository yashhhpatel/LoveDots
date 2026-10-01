import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';

import 'save.dart';

enum Sfx { click, win, star, coin, tick, page, pop, wheel }

/// Sound effects, the looping pen-scratch sound and background music.
class Audio {
  Audio._();
  static final Audio I = Audio._();

  final Map<Sfx, List<AudioPlayer>> _pool = {};
  final Map<Sfx, int> _next = {};
  late final AudioPlayer _music;
  late final AudioPlayer _draw;
  bool _drawing = false;

  Future<void> init() async {
    // No audio focus, so sound effects never interrupt the music loop.
    await AudioPlayer.global.setAudioContext(const AudioContext(
      android: AudioContextAndroid(
        isSpeakerphoneOn: false,
        stayAwake: false,
        contentType: AndroidContentType.music,
        usageType: AndroidUsageType.game,
        audioFocus: AndroidAudioFocus.none,
      ),
    ));
    for (final s in Sfx.values) {
      final n = (s == Sfx.tick || s == Sfx.coin || s == Sfx.star) ? 3 : 1;
      final list = <AudioPlayer>[];
      for (var i = 0; i < n; i++) {
        final p = AudioPlayer();
        await p.setPlayerMode(PlayerMode.lowLatency);
        await p.setReleaseMode(ReleaseMode.stop);
        await p.setSource(AssetSource('sfx/${s.name}.wav'));
        list.add(p);
      }
      _pool[s] = list;
      _next[s] = 0;
    }
    _draw = AudioPlayer();
    await _draw.setReleaseMode(ReleaseMode.loop);
    await _draw.setSource(AssetSource('sfx/draw.wav'));
    await _draw.setVolume(0.55);
    _music = AudioPlayer();
    await _music.setReleaseMode(ReleaseMode.loop);
    await _music.setSource(AssetSource('sfx/music.wav'));
    await _music.setVolume(0.35);
    refreshMusic();
  }

  void play(Sfx s) {
    if (!Save.I.sound) return;
    final list = _pool[s];
    if (list == null) return;
    final i = _next[s]!;
    _next[s] = (i + 1) % list.length;
    final p = list[i];
    p.stop().then((_) => p.resume());
  }

  void startDraw() {
    if (!Save.I.sound || _drawing) return;
    _drawing = true;
    _draw.resume();
  }

  void stopDraw() {
    if (!_drawing) return;
    _drawing = false;
    _draw.pause();
  }

  void refreshMusic() {
    if (Save.I.music) {
      _music.resume();
    } else {
      _music.pause();
    }
  }

  void pauseAll() {
    _music.pause();
    stopDraw();
  }

  void vibrate() {
    if (Save.I.vibration) HapticFeedback.mediumImpact();
  }
}
