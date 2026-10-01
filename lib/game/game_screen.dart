import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:share_plus/share_plus.dart';

import '../art/desk.dart';
import '../core/ads.dart';
import '../core/audio.dart';
import '../core/save.dart';
import '../ui/result_overlay.dart';
import '../ui/settings.dart';
import '../ui/shop.dart';
import '../ui/widgets.dart';
import 'hud.dart';
import 'levels.dart';
import 'scene.dart';
import 'sim.dart';

enum Tut { none, progress, retry, hint }

class GameScreen extends StatefulWidget {
  final int level;
  final VoidCallback onLevels;
  const GameScreen({super.key, required this.level, required this.onLevels});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with SingleTickerProviderStateMixin {
  late int li = widget.level;
  late Sim sim;
  final scene = SceneState();
  final ink = ValueNotifier<double>(1);
  final _sceneKey = GlobalKey();
  late final Ticker _ticker;
  Duration _last = Duration.zero;
  Rect _paper = Rect.zero;
  double _k = 1;

  bool _winHandled = false;
  bool _showResult = false;
  ui.Image? _thumb;
  int _resultStars = 0;
  int _resultCoins = 0;

  ui.Image? _curlImg;
  double _curlT = -1;
  double _curlPr = 1;

  Tut _tut = Tut.none;
  double _tutTimer = -1;
  double _idleHearts = 2;
  final _rnd = math.Random();

  Level get level => levels[li];

  @override
  void initState() {
    super.initState();
    _setup();
    _ticker = createTicker(_tick)..start();
    Save.I.addListener(_saveChanged);
  }

  @override
  void dispose() {
    _ticker.dispose();
    Save.I.removeListener(_saveChanged);
    Audio.I.stopDraw();
    super.dispose();
  }

  void _saveChanged() {
    scene
      ..bg = Save.I.bg
      ..balls = Save.I.activeBalls
      ..pen = Save.I.activePen;
    if (mounted) setState(() {});
  }

  void _setup({bool keepTut = false}) {
    sim = Sim(level);
    scene
      ..sim = sim
      ..level = level
      ..bg = Save.I.bg
      ..balls = Save.I.activeBalls
      ..pen = Save.I.activePen
      ..hearts.clear()
      ..ringT = -1;
    final autoHint = li <= 1;
    scene.hintVisible = autoHint;
    scene.hintPen = autoHint ? 0 : -1;
    ink.value = 1;
    _winHandled = false;
    if (!keepTut) {
      _tut = (li == 2 || li == 3) ? Tut.progress : Tut.none;
    }
    _tutTimer = -1;
    if (Save.I.lastPlayed != li) Save.I.update(() => Save.I.lastPlayed = li);
  }

  // ------------------------------------------------------------- loop

  void _tick(Duration now) {
    final dt = _last == Duration.zero ? 1 / 60 : (now - _last).inMicroseconds / 1e6;
    _last = now;
    final d = math.min(dt, 0.05);
    sim.step(d);

    if (scene.hintPen >= 0) {
      scene.hintPen += d / 1.8;
      if (scene.hintPen > 1) scene.hintPen = -1;
    }

    // hearts and ring
    for (final h in scene.hearts) {
      h.life += d;
      h.p += h.v * d;
      h.v = h.v * (1 - 1.8 * d);
    }
    scene.hearts.removeWhere((h) => h.life >= h.max);
    if (scene.ringT >= 0) {
      scene.ringT += d / 0.9;
      if (scene.ringT > 1) scene.ringT = -1;
    }

    // idle little hearts above the balls
    if (sim.state != SimState.won) {
      _idleHearts -= d;
      if (_idleHearts <= 0) {
        _idleHearts = 3 + _rnd.nextDouble() * 2;
        final b = _rnd.nextBool() ? sim.bluePos : sim.pinkPos;
        for (var i = 0; i < 2; i++) {
          scene.hearts.add(FxHeart(b + Offset(-0.6 + i * 1.2, -3.2), const Offset(0, -1.5), 1.2, 0.55,
              0, const Color(0xFFF0487A)));
        }
      }
    }

    if (sim.state == SimState.won && !_winHandled) {
      _winHandled = true;
      Audio.I.play(Sfx.win);
      Audio.I.vibrate();
      scene.ringT = 0;
      scene.ringC = sim.kiss;
      for (var i = 0; i < 18; i++) {
        final a = _rnd.nextDouble() * math.pi * 2;
        final sp = 4 + _rnd.nextDouble() * 9;
        scene.hearts.add(FxHeart(
          sim.kiss + Offset(math.cos(a), math.sin(a)) * 0.8,
          Offset(math.cos(a), math.sin(a)) * sp,
          0.9 + _rnd.nextDouble() * 0.6,
          0.5 + _rnd.nextDouble() * 0.6,
          (_rnd.nextDouble() - 0.5) * 0.8,
          [const Color(0xFFE8304A), const Color(0xFFF0487A), const Color(0xFFD81B3C)][i % 3],
        ));
      }
      _tut = Tut.none;
    }
    if (sim.state == SimState.won && sim.winTime > 1.5 && !_showResult && _curlT < 0) {
      _finishWin();
    }
    if (sim.state == SimState.failed && sim.failTime > 0.8) {
      _setup(keepTut: true);
    }

    if (_tutTimer >= 0) {
      _tutTimer += d;
      if (_tutTimer > 1.6 && sim.state == SimState.running && _tut == Tut.progress) {
        setState(() => _tut = Tut.retry);
        _tutTimer = -1;
      }
    }

    if (_curlT >= 0) {
      setState(() {
        _curlT += d / 0.85;
        if (_curlT >= 1) {
          _curlT = -1;
          _curlImg = null;
        }
      });
    }
    scene.tick();
  }

  // ------------------------------------------------------------- input

  Offset _toPaper(Offset p) => (p - _paper.topLeft) / _k;

  void _down(PointerDownEvent e) {
    if (_showResult || _curlT >= 0) return;
    if (sim.begin(_toPaper(e.localPosition))) {
      scene.hintPen = -1;
      Audio.I.startDraw();
    }
  }

  void _move(PointerMoveEvent e) {
    if (sim.state != SimState.drawing) return;
    sim.extend(_toPaper(e.localPosition));
    ink.value = sim.inkLeft;
  }

  void _up(PointerEvent e) {
    if (sim.state != SimState.drawing) return;
    sim.end();
    ink.value = sim.inkLeft;
    Audio.I.stopDraw();
    if (li == 3 && _tut == Tut.progress) _tutTimer = 0;
  }

  // ------------------------------------------------------------- actions

  Future<ui.Image?> _capture(double pr) async {
    final b = _sceneKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (b == null) return null;
    return b.toImage(pixelRatio: pr);
  }

  Future<void> _finishWin() async {
    _showResult = true; // guard
    final stars = sim.starsNow;
    final coins = stars == 3 ? 25 : 15;
    final img = await _capture(1.5);
    Save.I.update(() {
      final prev = Save.I.stars[li] ?? 0;
      Save.I.stars[li] = math.max(prev, stars);
      Save.I.coins += coins;
      Save.I.levelsSinceAd++;
      if (li == kDailyChallengeLevel) Save.I.dailyChallenge = true;
    });
    if (!mounted) return;
    setState(() {
      _thumb = img;
      _resultStars = stars;
      _resultCoins = coins;
    });
  }

  void _retry() {
    setState(() {
      _showResult = false;
      if (li == 3 && (_tut == Tut.retry || _tut == Tut.progress)) {
        _tut = Tut.hint;
        _setup(keepTut: true);
      } else {
        _setup();
      }
    });
  }

  /// NEXT: every 3rd completed level shows an interstitial first.
  void _next() => Ads.I.maybeShowInterstitial(_advance);

  Future<void> _advance() async {
    if (!mounted) return;
    if (li + 1 >= levels.length) {
      setState(() => _showResult = false);
      widget.onLevels();
      return;
    }
    _curlPr = MediaQuery.of(context).devicePixelRatio;
    final img = await _capture(_curlPr);
    if (!mounted) return;
    Audio.I.play(Sfx.page);
    setState(() {
      _showResult = false;
      li++;
      _setup();
      _curlImg = img;
      _curlT = img == null ? -1 : 0;
    });
  }

  void _hint() {
    final free = li < 6 && !Save.I.freeHintUsed.contains(li);
    if (free) {
      Save.I.update(() => Save.I.freeHintUsed.add(li));
      _revealHint();
    } else if (scene.hintVisible) {
      _revealHint(); // already paid for on this attempt: just replay it
    } else {
      Ads.I.showRewarded(context, _revealHint);
    }
  }

  void _revealHint() {
    if (!mounted) return;
    setState(() {
      scene.hintVisible = true;
      scene.hintPen = sim.state == SimState.ready ? 0 : -1;
    });
  }

  void _share() {
    Ads.I.skipNextResume();
    Share.share("I am playing #LoveDots! Let's play together! Draw one line and bump the balls!");
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final size = Size(c.maxWidth, c.maxHeight);
      _paper = paperRectFor(size, S.k);
      _k = _paper.width / kPaperW;
      final hintFree = li < 6 && !Save.I.freeHintUsed.contains(li);
      return Stack(
        children: [
          Positioned.fill(
            child: RepaintBoundary(child: CustomPaint(painter: DeskPainter(_paper))),
          ),
          Positioned.fill(
            child: Listener(
              behavior: HitTestBehavior.opaque,
              onPointerDown: _down,
              onPointerMove: _move,
              onPointerUp: _up,
              onPointerCancel: _up,
              child: RepaintBoundary(
                key: _sceneKey,
                child: CustomPaint(painter: ScenePainter(scene, _paper), size: size),
              ),
            ),
          ),
          if (!_showResult)
            Positioned(
              left: 0,
              top: 0,
              child: Hud(
                width: size.width,
                ink: ink,
                sound: Save.I.sound,
                music: Save.I.music,
                hintFree: hintFree,
                hintDisabled: li <= 1,
                onBack: widget.onLevels,
                onSound: () {
                  Save.I.update(() => Save.I.sound = !Save.I.sound);
                  if (!Save.I.sound) Audio.I.stopDraw();
                },
                onMusic: () {
                  Save.I.update(() => Save.I.music = !Save.I.music);
                  Audio.I.refreshMusic();
                },
                onHint: _hint,
                onRetry: _retry,
              ),
            ),
          if (!_showResult && _tut != Tut.none) _callout(size),
          if (_curlImg != null && _curlT >= 0)
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(painter: CurlPainter(_curlImg!, _paper, _curlT, _curlPr)),
              ),
            ),
          if (_showResult)
            Positioned.fill(
              child: ResultOverlay(
                key: ValueKey('result$li'),
                levelIndex: li,
                stars: _resultStars,
                coins: _resultCoins,
                thumb: _thumb,
                paper: _paper,
                daily: li == kDailyChallengeLevel,
                onNext: _next,
                onBack: () {
                  setState(() => _showResult = false);
                  widget.onLevels();
                },
                onRetry: _retry,
                onShop: () => showPopup(context, const ShopDialog()),
                onShare: _share,
                onLeaderboard: () => showLeaderboard(context),
              ),
            ),
        ],
      );
    });
  }

  Widget _callout(Size size) {
    return switch (_tut) {
      Tut.progress => Positioned(
          left: size.width / 2 + s(22),
          top: s(52),
          child: IgnorePointer(
            child: Callout(
                'The progress bar shows the usage of the ink, the less you use, the easier you can get 3 stars.',
                width: 300,
                arrowX: 0.27),
          ),
        ),
      Tut.retry => Positioned(
          left: size.width - s(410),
          top: s(52),
          child: IgnorePointer(
            child: Callout('You can click the Retry button to redo it.', width: 330, arrowX: 0.93, flip: true),
          ),
        ),
      Tut.hint => Positioned(
          left: size.width - s(510),
          top: s(52),
          child: IgnorePointer(
            child: Callout("If you fail to complete a level or you can't get 3 stars, tap the hint button!",
                width: 320, arrowX: 0.86, flip: true),
          ),
        ),
      Tut.none => const SizedBox(),
    };
  }
}
