import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../art/characters.dart';
import '../art/palette.dart';
import '../core/ads.dart';
import '../core/audio.dart';
import '../core/save.dart';
import 'widgets.dart';

const _titleStyleColor = Color(0xFFF26B7A);

/// Base layout shared by the reward screens: dim backdrop, coin counter, title.
class _RewardFrame extends StatelessWidget {
  final String title;
  final int coins;
  final Widget child;
  final VoidCallback? onClose;
  final List<Widget> buttons;
  const _RewardFrame(
      {required this.title,
      required this.coins,
      required this.child,
      this.onClose,
      this.buttons = const []});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Material(
      color: Colors.transparent,
      child: SizedBox(
        width: size.width,
        height: size.height,
        child: Stack(
          children: [
            Positioned(
              left: s(24),
              top: s(14),
              child: Row(children: [
                CoinIcon(size: s(30)),
                SizedBox(width: s(8)),
                Text('$coins', style: TextStyle(color: Colors.white, fontSize: s(20))),
              ]),
            ),
            Positioned(
              top: s(28),
              left: 0,
              right: 0,
              child: Center(
                child: Text(title,
                    style: TextStyle(
                        color: _titleStyleColor,
                        fontSize: s(34),
                        fontWeight: FontWeight.w500,
                        shadows: const [Shadow(color: Colors.black26, offset: Offset(1, 1))])),
              ),
            ),
            Positioned.fill(top: s(70), bottom: s(70), child: Center(child: child)),
            if (onClose != null)
              Positioned(
                left: size.width / 2 + s(176),
                top: s(90),
                child: Tap(
                  onTap: onClose,
                  child: Container(
                    width: s(38),
                    height: s(38),
                    decoration: const BoxDecoration(color: Color(0xFFF5A43A), shape: BoxShape.circle),
                    child: Icon(Icons.close_rounded, color: Colors.white, size: s(30)),
                  ),
                ),
              ),
            Positioned(
              bottom: s(26),
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 0; i < buttons.length; i++) ...[
                    if (i > 0) SizedBox(width: s(18)),
                    buttons[i],
                  ]
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class VideoBadge extends StatelessWidget {
  final double size;
  const VideoBadge({super.key, this.size = 22});
  @override
  Widget build(BuildContext context) => Container(
        width: s(size * 1.25),
        height: s(size),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.white, width: s(2)),
          borderRadius: BorderRadius.circular(s(3)),
        ),
        child: Icon(Icons.play_arrow_rounded, color: Colors.white, size: s(size * 0.8)),
      );
}

// ------------------------------------------------------------------ wheel

class _Seg {
  final String label;
  final Color color;
  final int coins; // 0 = free item
  final String? item; // 'ball' / 'pen'
  const _Seg(this.label, this.color, this.coins, [this.item]);
}

const _segs = [
  _Seg('+150', Color(0xFFFFD43B), 150),
  _Seg('+120', Color(0xFF4DABF7), 120),
  _Seg('+200', Color(0xFFB45BDB), 200),
  _Seg('+110', Color(0xFF82C91E), 110),
  _Seg('FREE', Color(0xFFFF6B4A), 0, 'ball'),
  _Seg('FREE', Color(0xFF3BC9DB), 0, 'pen'),
];

class LuckyWheel extends StatefulWidget {
  final VoidCallback onNext;
  const LuckyWheel({super.key, required this.onNext});

  @override
  State<LuckyWheel> createState() => _LuckyWheelState();
}

class _LuckyWheelState extends State<LuckyWheel> with TickerProviderStateMixin {
  late final AnimationController _spin =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 3800));
  late final AnimationController _fly =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
  double _from = 0, _to = 0;
  int _lastTick = 0;
  bool _done = false;
  bool _spunAgain = false;
  int _shownCoins = Save.I.coins;
  String? _prize;
  final _rnd = math.Random();

  @override
  void initState() {
    super.initState();
    _spin.addListener(() {
      final a = _angle;
      final tick = (a / (math.pi / 3)).floor();
      if (tick != _lastTick) {
        _lastTick = tick;
        Audio.I.play(Sfx.tick);
      }
      setState(() {});
    });
    _spin.addStatusListener((s) {
      if (s == AnimationStatus.completed) _land();
    });
    _fly.addListener(() => setState(() {}));
    Future.delayed(const Duration(milliseconds: 350), _go);
  }

  double get _angle => _from + (_to - _from) * Curves.easeOutCubic.transform(_spin.value);

  void _go() {
    if (!mounted) return;
    final target = _rnd.nextInt(_segs.length);
    _from = _angle % (math.pi * 2);
    final want = (math.pi * 2 - target * math.pi / 3) % (math.pi * 2);
    var delta = want - _from % (math.pi * 2);
    if (delta < 0) delta += math.pi * 2;
    _to = _from + math.pi * 2 * 5 + delta + (_rnd.nextDouble() - 0.5) * 0.5;
    _done = false;
    _prize = null;
    _spin.forward(from: 0);
  }

  void _land() {
    var a = (-_angle) % (math.pi * 2);
    if (a < 0) a += math.pi * 2;
    final idx = ((a + math.pi / 6) / (math.pi / 3)).floor() % _segs.length;
    final seg = _segs[idx];
    Audio.I.play(Sfx.wheel);
    if (seg.coins > 0) {
      Save.I.update(() => Save.I.coins += seg.coins);
      _prize = '+${seg.coins}';
      _fly.forward(from: 0).then((_) {
        if (mounted) setState(() => _shownCoins = Save.I.coins);
      });
      Audio.I.play(Sfx.coin);
    } else {
      _prize = grantFreeItem(seg.item!);
      _shownCoins = Save.I.coins;
    }
    setState(() => _done = true);
    if (_prize != null && seg.coins == 0) showToast(context, _prize!);
  }

  @override
  void dispose() {
    _spin.dispose();
    _fly.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final r = s(162);
    return _RewardFrame(
      title: 'Lucky Wheel',
      coins: _fly.isAnimating ? _shownCoins : Save.I.coins,
      onClose: _done ? () => Navigator.of(context).pop() : null,
      buttons: _done
          ? [
              Pill('NEXT',
                  color: const Color(0xFFF0B13C),
                  width: 146,
                  height: 40,
                  font: 18,
                  icon: Icon(Icons.arrow_forward_rounded, color: Colors.white, size: s(26)),
                  onTap: () {
                    Navigator.of(context).pop();
                    widget.onNext();
                  }),
              if (!_spunAgain)
                Pill('SPIN AGAIN',
                    color: C.blueBtn,
                    width: 196,
                    height: 40,
                    font: 18,
                    icon: const VideoBadge(size: 20),
                    onTap: () => Ads.I.showRewarded(context, () {
                          if (!mounted || _spunAgain) return;
                          _spunAgain = true;
                          _go();
                        })),
            ]
          : const [],
      child: SizedBox(
        width: r * 2.3,
        height: r * 2.3,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            Transform.rotate(
              angle: _angle,
              child: CustomPaint(size: Size.square(r * 2), painter: _WheelPainter()),
            ),
            CustomPaint(size: Size.square(r * 2), painter: _RimPainter(_spin.value)),
            Positioned(
              top: r * 0.15 - s(26),
              child: CustomPaint(size: Size(s(36), s(48)), painter: _PinPainter()),
            ),
            if (_fly.isAnimating)
              for (var i = 0; i < 8; i++) _flyingCoin(i, r),
          ],
        ),
      ),
    );
  }

  Widget _flyingCoin(int i, double r) {
    final t = (_fly.value * 1.4 - i * 0.05).clamp(0.0, 1.0);
    final size = MediaQuery.of(context).size;
    final start = Offset(r * 1.15 + math.cos(i * 0.8) * r * 0.3, r * 1.15 + math.sin(i * 0.8) * r * 0.3);
    // target: top-left counter, expressed in the wheel box's coordinates
    final boxLeft = (size.width - r * 2.3) / 2;
    final boxTop = s(70) + ((size.height - s(140)) - r * 2.3) / 2;
    final end = Offset(s(38) - boxLeft, s(28) - boxTop);
    final p = Offset.lerp(start, end, Curves.easeIn.transform(t))!;
    return Positioned(
      left: p.dx - s(14),
      top: p.dy - s(14),
      child: Opacity(opacity: t >= 1 ? 0 : 1, child: CoinIcon(size: s(28))),
    );
  }
}

/// Unlocks a random locked ball/pen skin, falling back to coins.
String grantFreeItem(String kind) {
  final rnd = math.Random();
  if (kind == 'ball') {
    final locked = ballItems.where((e) => !Save.I.ownedBalls.contains(e.id)).toList();
    if (locked.isNotEmpty) {
      final it = locked[rnd.nextInt(locked.length)];
      Save.I.update(() => Save.I.ownedBalls.add(it.id));
      return 'New ball skin unlocked!';
    }
  } else {
    final locked = penItems.where((e) => !Save.I.ownedPens.contains(e.id)).toList();
    if (locked.isNotEmpty) {
      final it = locked[rnd.nextInt(locked.length)];
      Save.I.update(() => Save.I.ownedPens.add(it.id));
      return 'New pen unlocked!';
    }
  }
  Save.I.update(() => Save.I.coins += 200);
  return '+200';
}

class _WheelPainter extends CustomPainter {
  @override
  void paint(Canvas c, Size sz) {
    final r = sz.width / 2;
    final o = Offset(r, r);
    final inner = r * 0.84;
    for (var i = 0; i < _segs.length; i++) {
      final a0 = -math.pi / 2 + (i - 0.5) * math.pi / 3;
      c.drawArc(Rect.fromCircle(center: o, radius: inner), a0, math.pi / 3, true,
          Paint()..color = _segs[i].color);
      c.drawLine(o, o + Offset(math.cos(a0), math.sin(a0)) * inner,
          Paint()
            ..color = Colors.white
            ..strokeWidth = r * 0.015);
      c.save();
      c.translate(o.dx, o.dy);
      c.rotate(i * math.pi / 3);
      final seg = _segs[i];
      final tp = TextPainter(
        text: TextSpan(
            text: seg.label,
            style: TextStyle(
                color: const Color(0xFF222222), fontSize: r * 0.12, fontWeight: FontWeight.w700)),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(c, Offset(-tp.width / 2, -inner * 0.92));
      if (seg.coins > 0) {
        final n = 2 + (seg.coins ~/ 60);
        for (var k = 0; k < n; k++) {
          final co = Offset((k - (n - 1) / 2) * r * 0.06, -inner * 0.52 + (k % 2) * r * 0.05);
          c.drawCircle(co, r * 0.065, Paint()..color = C.goldDark);
          c.drawCircle(co - Offset(0, r * 0.01), r * 0.055, Paint()..color = C.gold);
        }
      } else if (seg.item == 'pen') {
        c.save();
        c.scale(1);
        paintPen(c, Offset(-r * 0.12, -inner * 0.42), r * 0.42, 'classic', shadow: false);
        c.restore();
      } else {
        paintBall(c, Offset(-r * 0.08, -inner * 0.55), r * 0.07, blue: true, skin: 'ninja');
        paintBall(c, Offset(r * 0.08, -inner * 0.45), r * 0.07, blue: false, skin: 'ninja');
      }
      c.restore();
    }
    c.drawCircle(o, r * 0.14, Paint()..color = Colors.white);
    c.drawCircle(o, r * 0.12, Paint()..color = const Color(0xFFE53935));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _RimPainter extends CustomPainter {
  final double t;
  _RimPainter(this.t);
  @override
  void paint(Canvas c, Size sz) {
    final r = sz.width / 2;
    final o = Offset(r, r);
    c.drawCircle(
        o,
        r * 0.92,
        Paint()
          ..color = const Color(0xFFF5A43A)
          ..style = PaintingStyle.stroke
          ..strokeWidth = r * 0.16);
    c.drawCircle(
        o,
        r * 1.0,
        Paint()
          ..color = const Color(0xFFE08A1E)
          ..style = PaintingStyle.stroke
          ..strokeWidth = r * 0.02);
    for (var i = 0; i < 18; i++) {
      final a = i / 18 * math.pi * 2;
      final lit = ((i + (t * 30).floor()) % 2) == 0;
      c.drawCircle(o + Offset(math.cos(a), math.sin(a)) * r * 0.92, r * 0.035,
          Paint()..color = lit ? Colors.white : const Color(0xFFFFF3C4));
    }
  }

  @override
  bool shouldRepaint(_RimPainter old) => old.t != t;
}

class _PinPainter extends CustomPainter {
  @override
  void paint(Canvas c, Size sz) {
    final w = sz.width, h = sz.height;
    final p = Path()
      ..moveTo(w / 2, h)
      ..cubicTo(w * 0.1, h * 0.6, 0, h * 0.45, 0, w / 2)
      ..arcToPoint(Offset(w, w / 2), radius: Radius.circular(w / 2))
      ..cubicTo(w, h * 0.45, w * 0.9, h * 0.6, w / 2, h)
      ..close();
    c.drawPath(p, Paint()..color = const Color(0xFFE53935));
    c.drawCircle(Offset(w / 2, w / 2), w * 0.2, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ------------------------------------------------------------------ draw

class LuckyDraw extends StatefulWidget {
  final VoidCallback onNext;
  const LuckyDraw({super.key, required this.onNext});
  @override
  State<LuckyDraw> createState() => _LuckyDrawState();
}

class _LuckyDrawState extends State<LuckyDraw> with SingleTickerProviderStateMixin {
  late final AnimationController _flip =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
  final List<int> _values = [50, 100, 200]..shuffle();
  int? _picked;

  @override
  void initState() {
    super.initState();
    _flip.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _flip.dispose();
    super.dispose();
  }

  void _pick(int i) {
    if (_picked != null) return;
    _picked = i;
    Save.I.update(() => Save.I.coins += _values[i]);
    _flip.forward().then((_) => Audio.I.play(Sfx.coin));
  }

  @override
  Widget build(BuildContext context) {
    return _RewardFrame(
      title: 'Lucky Draw',
      coins: Save.I.coins,
      buttons: _picked != null && _flip.isCompleted
          ? [
              Pill('NEXT',
                  color: const Color(0xFFF0B13C),
                  width: 146,
                  height: 40,
                  font: 18,
                  icon: Icon(Icons.arrow_forward_rounded, color: Colors.white, size: s(26)),
                  onTap: () {
                    Navigator.of(context).pop();
                    widget.onNext();
                  }),
            ]
          : const [],
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < 3; i++)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: s(16)),
              child: Tap(onTap: () => _pick(i), child: _card(i)),
            ),
        ],
      ),
    );
  }

  Widget _card(int i) {
    final t = _picked == null ? 0.0 : (_picked == i ? _flip.value : (_flip.value - 0.4).clamp(0.0, 0.6) / 0.6);
    final showFront = t > 0.5;
    final sx = (math.cos(t * math.pi)).abs();
    return Transform(
      alignment: Alignment.center,
      transform: Matrix4.diagonal3Values(math.max(0.02, sx), 1, 1),
      child: Container(
        width: s(130),
        height: s(180),
        decoration: BoxDecoration(
          color: showFront ? Colors.white : const Color(0xFFF07A4A),
          borderRadius: BorderRadius.circular(s(12)),
          border: Border.all(color: showFront ? const Color(0xFFF07A4A) : Colors.white, width: s(5)),
          boxShadow: [BoxShadow(color: Colors.black26, offset: Offset(s(3), s(4)))],
        ),
        alignment: Alignment.center,
        child: showFront
            ? Opacity(
                opacity: _picked == i ? 1 : 0.5,
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  CoinIcon(size: s(48)),
                  SizedBox(height: s(8)),
                  Text('+${_values[i]}',
                      style: TextStyle(fontSize: s(26), color: C.goldDark, fontWeight: FontWeight.w700)),
                ]),
              )
            : Stack(alignment: Alignment.center, children: [
                Icon(Icons.favorite_rounded, color: Colors.white, size: s(96)),
                Text('?',
                    style: TextStyle(
                        fontSize: s(46), color: const Color(0xFFF07A4A), fontWeight: FontWeight.w800)),
              ]),
      ),
    );
  }
}

// ------------------------------------------------------------------ chest

class ChestReward extends StatefulWidget {
  final VoidCallback onNext;
  const ChestReward({super.key, required this.onNext});
  @override
  State<ChestReward> createState() => _ChestRewardState();
}

class _ChestRewardState extends State<ChestReward> with SingleTickerProviderStateMixin {
  late final AnimationController _a =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1400));
  final int _amount = [80, 100, 120, 150][math.Random().nextInt(4)];

  @override
  void initState() {
    super.initState();
    _a.addListener(() => setState(() {}));
    _a.forward().then((_) {
      Save.I.update(() => Save.I.coins += _amount);
      Audio.I.play(Sfx.coin);
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _a.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final shake = _a.value < 0.6 ? math.sin(_a.value * 60) * 0.06 : 0.0;
    final open = ((_a.value - 0.6) / 0.4).clamp(0.0, 1.0);
    return _RewardFrame(
      title: 'Reward',
      coins: Save.I.coins,
      buttons: _a.isCompleted
          ? [
              Pill('NEXT',
                  color: const Color(0xFFF0B13C),
                  width: 146,
                  height: 40,
                  font: 18,
                  icon: Icon(Icons.arrow_forward_rounded, color: Colors.white, size: s(26)),
                  onTap: () {
                    Navigator.of(context).pop();
                    widget.onNext();
                  }),
            ]
          : const [],
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Opacity(
            opacity: open,
            child: Text('+$_amount',
                style: TextStyle(fontSize: s(34), color: C.gold, fontWeight: FontWeight.w700)),
          ),
          SizedBox(height: s(8)),
          Transform.rotate(
            angle: shake,
            child: CustomPaint(size: Size(s(200), s(160)), painter: ChestPainter(open)),
          ),
        ],
      ),
    );
  }
}

class ChestPainter extends CustomPainter {
  final double open;
  ChestPainter(this.open);

  @override
  void paint(Canvas c, Size sz) {
    final w = sz.width, h = sz.height;
    final body = Rect.fromLTWH(w * 0.08, h * 0.45, w * 0.84, h * 0.5);
    if (open > 0) {
      for (var i = 0; i < 6; i++) {
        final o = Offset(w * (0.3 + i * 0.08), h * (0.45 - open * (0.1 + (i % 3) * 0.06)));
        c.drawCircle(o, w * 0.06, Paint()..color = C.goldDark);
        c.drawCircle(o - Offset(0, w * 0.008), w * 0.05, Paint()..color = C.gold);
      }
    }
    c.drawRRect(RRect.fromRectAndRadius(body, Radius.circular(w * 0.03)),
        Paint()..color = const Color(0xFFC0392B));
    c.drawRect(Rect.fromLTWH(body.left, body.top, body.width, h * 0.07),
        Paint()..color = const Color(0xFFF1C40F));
    c.drawRect(Rect.fromLTWH(w * 0.44, body.top, w * 0.12, body.height),
        Paint()..color = const Color(0xFFF1C40F));
    c.save();
    c.translate(w * 0.08, h * 0.45);
    c.rotate(-open * 0.9);
    final lid = RRect.fromRectAndCorners(Rect.fromLTWH(0, -h * 0.3, w * 0.84, h * 0.3),
        topLeft: Radius.circular(w * 0.12), topRight: Radius.circular(w * 0.12));
    c.drawRRect(lid, Paint()..color = const Color(0xFFE74C3C));
    c.drawRect(Rect.fromLTWH(w * 0.36, -h * 0.3, w * 0.12, h * 0.3), Paint()..color = const Color(0xFFF1C40F));
    c.restore();
    c.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset(w * 0.5, h * 0.55), width: w * 0.14, height: h * 0.16),
            Radius.circular(w * 0.02)),
        Paint()..color = const Color(0xFF7F5A0B));
  }

  @override
  bool shouldRepaint(ChestPainter old) => old.open != open;
}
