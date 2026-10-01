import 'package:flutter/material.dart';

import '../art/characters.dart';
import '../game/scene.dart';
import 'widgets.dart';
import '../core/l10n.dart';

/// Brand splash followed by the "Loading" screen.
class LoadingScreen extends StatefulWidget {
  final VoidCallback onDone;
  const LoadingScreen({super.key, required this.onDone});

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _a =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 3200));

  @override
  void initState() {
    super.initState();
    _a.addListener(() => setState(() {}));
    _a.forward().then((_) => widget.onDone());
  }

  @override
  void dispose() {
    _a.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = _a.value;
    if (t < 0.32) {
      // brand splash
      return ColoredBox(
        color: Colors.black,
        child: Center(
          child: Opacity(
            opacity: (t < 0.05 ? t / 0.05 : (t > 0.27 ? (0.32 - t) / 0.05 : 1.0)).clamp(0.0, 1.0),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              CustomPaint(size: Size(s(120), s(70)), painter: _Logo()),
              SizedBox(height: s(14)),
              Text('LOVE DOTS',
                  style: TextStyle(
                      color: Colors.white, fontSize: s(34), fontWeight: FontWeight.w800, letterSpacing: 3)),
              Text('GAMES', style: TextStyle(color: Colors.white70, fontSize: s(16), letterSpacing: 6)),
            ]),
          ),
        ),
      );
    }
    final p = ((t - 0.32) / 0.68).clamp(0.0, 1.0);
    return ColoredBox(
      color: Colors.white,
      child: Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          CustomPaint(size: Size(s(150), s(110)), painter: _Logo()),
          SizedBox(height: s(26)),
          Text(tr('loading'), style: TextStyle(fontSize: s(17), color: const Color(0xFF333333))),
          SizedBox(height: s(14)),
          Container(
            width: s(278),
            height: s(14),
            decoration: BoxDecoration(
              color: const Color(0xFFB9B9B9),
              borderRadius: BorderRadius.circular(s(7)),
              border: Border.all(color: const Color(0xFF666666), width: s(1.2)),
            ),
            alignment: Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: Curves.easeInOut.transform(p),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF7CC8EE),
                  borderRadius: BorderRadius.circular(s(7)),
                ),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}

/// Two kissing balls resting on a smile, with hearts.
class _Logo extends CustomPainter {
  @override
  void paint(Canvas c, Size sz) {
    final w = sz.width, h = sz.height;
    c.drawArc(Rect.fromCenter(center: Offset(w * 0.5, h * 0.2), width: w * 0.85, height: h * 1.4),
        0.35, 2.44, false,
        Paint()
          ..color = const Color(0xFF555555)
          ..style = PaintingStyle.stroke
          ..strokeWidth = h * 0.05
          ..strokeCap = StrokeCap.round);
    final r = h * 0.24;
    paintBall(c, Offset(w * 0.4, h * 0.5), r, blue: true, look: const Offset(1, 0.2));
    paintBall(c, Offset(w * 0.6, h * 0.58), r, blue: false, look: const Offset(-1, -0.2));
    for (final hp in [(0.72, 0.12, 0.07), (0.84, 0.04, 0.05), (0.62, 0.0, 0.045)]) {
      c.drawPath(heartPath(Offset(w * hp.$1, h * hp.$2 + h * 0.08), h * hp.$3 * 1.3),
          Paint()..color = const Color(0xFFF0487A));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
