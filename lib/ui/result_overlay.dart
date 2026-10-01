import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../art/characters.dart';
import '../art/palette.dart';
import '../core/audio.dart';
import '../core/save.dart';
import '../game/levels.dart';
import 'rewards.dart';
import 'widgets.dart';

/// Level-complete screen: stars, coins, thumbnail card, reward, SHARE / NEXT.
class ResultOverlay extends StatefulWidget {
  final int levelIndex;
  final int stars;
  final int coins;
  final ui.Image? thumb;
  final Rect paper;
  final bool daily;
  final VoidCallback onNext, onBack, onRetry, onShop, onShare, onLeaderboard;

  const ResultOverlay({
    super.key,
    required this.levelIndex,
    required this.stars,
    required this.coins,
    required this.thumb,
    required this.paper,
    required this.daily,
    required this.onNext,
    required this.onBack,
    required this.onRetry,
    required this.onShop,
    required this.onShare,
    required this.onLeaderboard,
  });

  @override
  State<ResultOverlay> createState() => _ResultOverlayState();
}

class _ResultOverlayState extends State<ResultOverlay> with TickerProviderStateMixin {
  late final AnimationController _in =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1600))..forward();
  int _shownStars = 0;
  bool _claimed = false;

  Level get level => levels[widget.levelIndex];

  @override
  void initState() {
    super.initState();
    for (var i = 0; i < widget.stars; i++) {
      Future.delayed(Duration(milliseconds: 380 + i * 300), () {
        if (!mounted) return;
        setState(() => _shownStars = i + 1);
        Audio.I.play(Sfx.star);
      });
    }
  }

  @override
  void dispose() {
    _in.dispose();
    super.dispose();
  }

  void _openReward() {
    if (_claimed) return;
    switch (level.reward) {
      case Reward.wheel:
        setState(() => _claimed = true);
        showPopup(context, LuckyWheel(onNext: widget.onNext));
      case Reward.draw:
        setState(() => _claimed = true);
        showPopup(context, LuckyDraw(onNext: widget.onNext));
      case Reward.chest:
        setState(() => _claimed = true);
        showPopup(context, ChestReward(onNext: widget.onNext));
      case Reward.coins:
        Save.I.update(() => Save.I.coins += 250);
        Audio.I.play(Sfx.coin);
        setState(() => _claimed = true);
        showToast(context, '+250');
      case Reward.skin:
        final id = level.skinReward!;
        Save.I.update(() => Save.I.trials[id] =
            DateTime.now().add(const Duration(hours: 24)).millisecondsSinceEpoch);
        Audio.I.play(Sfx.coin);
        setState(() => _claimed = true);
        showToast(context, 'Bonus skin unlocked for 24h!');
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final cx = size.width / 2;
    final fade = CurvedAnimation(parent: _in, curve: const Interval(0, 0.2));
    final pop = CurvedAnimation(parent: _in, curve: const Interval(0.05, 0.35, curve: Curves.easeOutBack));
    return FadeTransition(
      opacity: fade,
      child: Stack(
        children: [
          Positioned.fill(child: Container(color: Colors.black.withOpacity(0.42))),
          Positioned(left: s(19), top: s(8), child: RoundBtn(Icons.chevron_left_rounded, size: 38, color: Colors.white70, onTap: widget.onBack)),
          Positioned(right: s(158), top: s(8), child: RoundBtn(Icons.leaderboard_rounded, size: 38, color: Colors.white70, onTap: widget.onLeaderboard)),
          Positioned(right: s(89), top: s(8), child: RoundBtn(Icons.checkroom_rounded, size: 38, color: Colors.white70, onTap: widget.onShop)),
          Positioned(right: s(21), top: s(8), child: RoundBtn(Icons.refresh_rounded, size: 38, color: Colors.white70, onTap: widget.onRetry)),
          if (widget.daily)
            Positioned(
              top: s(8),
              left: 0,
              right: 0,
              child: Center(
                child: Text('Daily Challenge Activated!',
                    style: TextStyle(color: Colors.white, fontSize: s(17))),
              ),
            ),
          // stars
          for (var i = 0; i < 3; i++)
            Positioned(
              left: cx + s(-101 + i * 101) - s(26),
              top: s(46),
              child: _AnimatedStar(on: i < _shownStars),
            ),
          Positioned(
            left: cx - s(40),
            top: s(103),
            child: Row(children: [
              Text('+${widget.coins}',
                  style: TextStyle(color: C.gold, fontSize: s(26), fontWeight: FontWeight.w500)),
              SizedBox(width: s(4)),
              CoinIcon(size: s(26)),
            ]),
          ),
          Positioned(
            left: cx - s(254),
            top: s(138),
            child: ScaleTransition(scale: pop, child: _card()),
          ),
          Positioned(
            left: cx - s(181),
            top: s(366),
            child: ScaleTransition(
              scale: pop,
              child: Pill('SHARE', color: C.pinkBtn, width: 150, height: 36, font: 16, onTap: widget.onShare),
            ),
          ),
          Positioned(
            left: cx + s(31),
            top: s(366),
            child: ScaleTransition(
              scale: pop,
              child: Pill('NEXT', color: C.yellowBtn, width: 150, height: 36, font: 22, onTap: widget.onNext),
            ),
          ),
        ],
      ),
    );
  }

  Widget _card() {
    final num = (widget.levelIndex + 1).toString().padLeft(2, '0');
    return SizedBox(
      width: s(526),
      height: s(206),
      child: Stack(
        children: [
          Positioned.fill(child: Container(color: Colors.white)),
          // thumbnail
          Positioned(
            left: s(10),
            top: s(10),
            width: s(340),
            height: s(186),
            child: widget.thumb == null
                ? const SizedBox()
                : CustomPaint(painter: _ThumbPainter(widget.thumb!, widget.paper)),
          ),
          Positioned(
            left: s(16),
            top: s(16),
            child: Text('Level $num', style: TextStyle(fontSize: s(12), color: const Color(0xFF444444))),
          ),
          if (_shownStars > 0)
            Positioned(
              left: s(320),
              top: s(14),
              child: Container(
                width: s(22),
                height: s(22),
                decoration: const BoxDecoration(color: Color(0xFF8BC34A), shape: BoxShape.circle),
                child: Icon(Icons.check_rounded, color: Colors.white, size: s(18)),
              ),
            ),
          Positioned(
            left: s(356),
            top: s(8),
            bottom: s(8),
            child: CustomPaint(size: Size(s(2), s(190)), painter: _DottedLine()),
          ),
          Positioned(left: s(358), top: 0, right: 0, bottom: 0, child: _rewardPanel()),
          Positioned(
            right: 0,
            top: 0,
            child: CustomPaint(size: Size(s(22), s(22)), painter: _CornerFold()),
          ),
        ],
      ),
    );
  }

  Widget _rewardPanel() {
    final (String title, Widget art) = switch (level.reward) {
      Reward.wheel => ('Lucky Wheel', CustomPaint(size: Size.square(s(64)), painter: _MiniWheel())),
      Reward.draw => ('Lucky Draw', _miniCards()),
      Reward.chest => ('Reward', CustomPaint(size: Size(s(80), s(64)), painter: ChestPainter(0))),
      Reward.coins => (
          '',
          Column(mainAxisSize: MainAxisSize.min, children: [
            Stack(alignment: Alignment.center, children: [
              Container(
                width: s(80),
                height: s(70),
                decoration: const BoxDecoration(
                  gradient: RadialGradient(colors: [Color(0xFFFFF3C4), Colors.white]),
                ),
              ),
              for (var i = 0; i < 3; i++)
                Positioned(
                  left: s(18 + i * 10.0),
                  top: s(14 + (i % 2) * 10.0),
                  child: CoinIcon(size: s(30)),
                ),
            ]),
            Text('+250', style: TextStyle(color: C.gold, fontSize: s(20))),
          ])),
      Reward.skin => ('BONUS SKIN', _skinArt()),
    };
    final isSkin = level.reward == Reward.skin;
    return Column(
      children: [
        SizedBox(height: s(14)),
        if (title.isNotEmpty)
          Text(title, style: TextStyle(color: C.orangeText, fontSize: s(15))),
        Expanded(child: Center(child: art)),
        if (isSkin)
          Text('Limit:24h', style: TextStyle(color: C.orangeText, fontSize: s(10))),
        SizedBox(height: s(4)),
        Opacity(
          opacity: _claimed ? 0.5 : 1,
          child: Pill(isSkin ? 'CLAIM' : 'OPEN',
              color: C.blueBtn,
              width: 130,
              height: 30,
              font: 15,
              icon: _claimed
                  ? Icon(Icons.check_rounded, color: Colors.white, size: s(20))
                  : const VideoBadge(size: 18),
              onTap: _openReward),
        ),
        SizedBox(height: s(14)),
      ],
    );
  }

  Widget _skinArt() {
    final id = level.skinReward!;
    if (id.startsWith('pen:')) {
      return CustomPaint(
          size: Size(s(80), s(70)),
          painter: _FnPainter((c, sz) => paintPen(c, Offset(sz.width * 0.25, sz.height * 0.95), sz.height * 1.1, id.substring(4))));
    }
    final skin = id.substring(5);
    return CustomPaint(
        size: Size(s(80), s(50)),
        painter: _FnPainter((c, sz) {
          paintBall(c, Offset(sz.width * 0.32, sz.height * 0.55), sz.height * 0.25, blue: true, skin: skin, look: const Offset(1, 0));
          paintBall(c, Offset(sz.width * 0.68, sz.height * 0.55), sz.height * 0.25, blue: false, skin: skin, look: const Offset(-1, 0));
        }));
  }

  Widget _miniCards() {
    return SizedBox(
      width: s(90),
      height: s(70),
      child: Stack(children: [
        for (var i = 0; i < 3; i++)
          Positioned(
            left: s(12.0 + i * 16),
            top: s(4.0 + (i == 1 ? 0 : 4)),
            child: Transform.rotate(
              angle: (i - 1) * 0.25,
              child: Container(
                width: s(42),
                height: s(58),
                decoration: BoxDecoration(
                  color: const Color(0xFFF07A4A),
                  borderRadius: BorderRadius.circular(s(4)),
                  border: Border.all(color: Colors.white, width: s(2)),
                ),
                child: Stack(alignment: Alignment.center, children: [
                  Icon(Icons.favorite_rounded, color: Colors.white, size: s(32)),
                  Text('?', style: TextStyle(color: const Color(0xFFF07A4A), fontSize: s(16), fontWeight: FontWeight.w800)),
                ]),
              ),
            ),
          ),
      ]),
    );
  }
}

class _AnimatedStar extends StatelessWidget {
  final bool on;
  const _AnimatedStar({required this.on});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      key: ValueKey(on),
      tween: Tween(begin: on ? 2.2 : 1, end: 1),
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutBack,
      builder: (_, v, child) => Transform.scale(scale: v, child: child),
      child: StarShape(size: s(52), on: on),
    );
  }
}

class _ThumbPainter extends CustomPainter {
  final ui.Image img;
  final Rect paper;
  _ThumbPainter(this.img, this.paper);

  @override
  void paint(Canvas c, Size sz) {
    final pr = img.width / (paper.right + paper.left); // image covers the whole screen width
    final src = Rect.fromLTWH(paper.left * pr, paper.top * pr, paper.width * pr, paper.height * pr);
    c.drawImageRect(img, src, Offset.zero & sz, Paint()..filterQuality = FilterQuality.medium);
  }

  @override
  bool shouldRepaint(_ThumbPainter old) => old.img != img;
}

class _FnPainter extends CustomPainter {
  final void Function(Canvas, Size) fn;
  _FnPainter(this.fn);
  @override
  void paint(Canvas canvas, Size size) => fn(canvas, size);
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _DottedLine extends CustomPainter {
  @override
  void paint(Canvas c, Size sz) {
    final p = Paint()
      ..color = const Color(0xFFCCCCCC)
      ..strokeWidth = sz.width;
    for (var y = 0.0; y < sz.height; y += 6) {
      c.drawLine(Offset(0, y), Offset(0, y + 3), p);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _CornerFold extends CustomPainter {
  @override
  void paint(Canvas c, Size sz) {
    c.drawPath(
        Path()
          ..moveTo(0, 0)
          ..lineTo(sz.width, sz.height)
          ..lineTo(0, sz.height)
          ..close(),
        Paint()..color = const Color(0xFFEDE3B5));
    c.drawPath(
        Path()
          ..moveTo(0, 0)
          ..lineTo(sz.width, 0)
          ..lineTo(sz.width, sz.height)
          ..close(),
        Paint()..color = const Color(0x00000000));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _MiniWheel extends CustomPainter {
  @override
  void paint(Canvas c, Size sz) {
    final r = sz.width / 2;
    final o = Offset(r, r);
    const cols = [
      Color(0xFFFFD43B),
      Color(0xFF4DABF7),
      Color(0xFFB45BDB),
      Color(0xFF82C91E),
      Color(0xFFFF6B4A),
      Color(0xFF3BC9DB)
    ];
    c.drawCircle(o, r, Paint()..color = Colors.white);
    for (var i = 0; i < 6; i++) {
      c.drawArc(Rect.fromCircle(center: o, radius: r * 0.92), -1.5708 + i * 1.0472, 1.0472, true,
          Paint()..color = cols[i]);
    }
    c.drawCircle(o, r * 0.14, Paint()..color = Colors.white);
    final pin = Path()
      ..moveTo(r, r * 0.3)
      ..lineTo(r - r * 0.18, -r * 0.05)
      ..lineTo(r + r * 0.18, -r * 0.05)
      ..close();
    c.drawPath(pin, Paint()..color = const Color(0xFFE53935));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
