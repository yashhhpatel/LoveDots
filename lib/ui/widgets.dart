import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../art/palette.dart';
import '../core/audio.dart';

/// Scale helper: sizes from the 1152x520 reference frames.
class S {
  static double k = 1;
  static double of(double v) => v * k;
}

double s(double v) => v * S.k;

class Tap extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final bool sound;
  const Tap({super.key, required this.child, this.onTap, this.sound = true});

  @override
  State<Tap> createState() => _TapState();
}

class _TapState extends State<Tap> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _down = true),
      onTapCancel: () => setState(() => _down = false),
      onTapUp: (_) => setState(() => _down = false),
      onTap: widget.onTap == null
          ? null
          : () {
              if (widget.sound) Audio.I.play(Sfx.click);
              widget.onTap!();
            },
      child: AnimatedScale(
        scale: _down ? 0.9 : 1,
        duration: const Duration(milliseconds: 90),
        child: widget.child,
      ),
    );
  }
}

class Pill extends StatelessWidget {
  final String text;
  final Color color;
  final double width;
  final double height;
  final double font;
  final Widget? icon;
  final VoidCallback? onTap;
  const Pill(this.text,
      {super.key,
      required this.color,
      required this.width,
      required this.height,
      this.font = 15,
      this.icon,
      this.onTap});

  @override
  Widget build(BuildContext context) {
    return Tap(
      onTap: onTap,
      child: Container(
        width: s(width),
        height: s(height),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(s(height)),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.15), offset: Offset(0, s(2)))
          ],
        ),
        alignment: Alignment.center,
        padding: EdgeInsets.symmetric(horizontal: s(height * 0.35)),
        // Translations can be much longer than English: shrink to fit.
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[icon!, SizedBox(width: s(8))],
              Text(text,
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: s(font),
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Round outlined icon button used in the game HUD.
class RoundBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool filled;
  final bool off;
  final double size;
  final Color color;
  const RoundBtn(this.icon,
      {super.key,
      required this.onTap,
      this.filled = false,
      this.off = false,
      this.size = 40,
      this.color = C.iconDark});

  @override
  Widget build(BuildContext context) {
    return Tap(
      onTap: onTap,
      child: Container(
        width: s(size),
        height: s(size),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: filled ? const Color(0xFFA9E4F2) : Colors.transparent,
          border: Border.all(color: color, width: s(2.4)),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(icon, color: color, size: s(size * 0.55)),
            if (off)
              Transform.rotate(
                angle: -math.pi / 4,
                child: Container(width: s(size * 0.85), height: s(2.6), color: color),
              ),
          ],
        ),
      ),
    );
  }
}

class CoinIcon extends StatelessWidget {
  final double size;
  final bool plus;
  const CoinIcon({super.key, this.size = 20, this.plus = false});

  @override
  Widget build(BuildContext context) => CustomPaint(
      size: Size.square(size), painter: _CoinPainter(plus));
}

class _CoinPainter extends CustomPainter {
  final bool plus;
  _CoinPainter(this.plus);
  @override
  void paint(Canvas c, Size sz) {
    final r = sz.width / 2;
    final o = Offset(r, r);
    c.drawCircle(o, r, Paint()..color = C.goldDark);
    c.drawCircle(o - Offset(0, r * 0.08), r * 0.88, Paint()..color = C.gold);
    c.drawCircle(o - Offset(0, r * 0.08), r * 0.55,
        Paint()
          ..color = const Color(0xFFFFE08A)
          ..style = PaintingStyle.stroke
          ..strokeWidth = r * 0.14);
    if (plus) {
      final g = Paint()..color = const Color(0xFF3DBE5A);
      final po = o + Offset(r * 0.25, r * 0.45);
      c.drawCircle(po, r * 0.45, Paint()..color = Colors.white);
      c.drawRect(Rect.fromCenter(center: po, width: r * 0.6, height: r * 0.18), g);
      c.drawRect(Rect.fromCenter(center: po, width: r * 0.18, height: r * 0.6), g);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class StarShape extends StatelessWidget {
  final double size;
  final bool on;
  final bool badge; // small gold coin-like star used on the ink bar
  const StarShape({super.key, required this.size, this.on = true, this.badge = false});

  @override
  Widget build(BuildContext context) =>
      CustomPaint(size: Size.square(size), painter: _StarPainter(on, badge));
}

class _StarPainter extends CustomPainter {
  final bool on, badge;
  _StarPainter(this.on, this.badge);

  @override
  void paint(Canvas c, Size sz) {
    final r = sz.width / 2;
    final o = Offset(r, r);
    if (badge) {
      c.drawCircle(o, r, Paint()..color = on ? const Color(0xFF8A6A1E) : const Color(0xFF5A5A5A));
      c.drawCircle(o, r * 0.82, Paint()..color = on ? C.gold : const Color(0xFF8A8A8A));
      c.drawPath(starPath(o, r * 0.62, r * 0.28), Paint()..color = on ? const Color(0xFFB8860B) : const Color(0xFF5A5A5A));
      return;
    }
    final path = starPath(o, r, r * 0.48, round: true);
    if (on) {
      c.drawPath(path.shift(Offset(0, r * 0.06)), Paint()..color = C.goldDark);
      c.drawPath(path, Paint()..color = C.gold);
      c.drawPath(starPath(o - Offset(0, r * 0.1), r * 0.55, r * 0.25),
          Paint()..color = const Color(0x55FFFFFF));
    } else {
      c.drawPath(path, Paint()..color = C.starOff);
    }
  }

  @override
  bool shouldRepaint(_StarPainter o) => o.on != on;
}

Path starPath(Offset o, double r, double ri, {bool round = false}) {
  final p = Path();
  for (var i = 0; i < 10; i++) {
    final a = -math.pi / 2 + i * math.pi / 5;
    final rr = i.isEven ? r : ri;
    final pt = o + Offset(math.cos(a) * rr, math.sin(a) * rr);
    i == 0 ? p.moveTo(pt.dx, pt.dy) : p.lineTo(pt.dx, pt.dy);
  }
  p.close();
  return p;
}

/// Cyan tutorial bubble with an arrow pointing up at something.
class Callout extends StatelessWidget {
  final String text;
  final double width;
  final double arrowX; // relative 0..1 along the top edge
  final bool flip; // arrow points up-right instead of up-left
  const Callout(this.text,
      {super.key, required this.width, this.arrowX = 0.3, this.flip = false});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: EdgeInsets.only(left: s(width) * arrowX - s(16)),
          child: Transform.flip(
            flipX: flip,
            child: CustomPaint(size: Size(s(32), s(40)), painter: _ArrowPainter()),
          ),
        ),
        Transform.rotate(
          angle: -0.03,
          child: Container(
            width: s(width),
            padding: EdgeInsets.symmetric(horizontal: s(12), vertical: s(10)),
            decoration: BoxDecoration(
              color: C.callout,
              borderRadius: BorderRadius.circular(s(8)),
              boxShadow: [BoxShadow(color: Colors.black12, offset: Offset(s(2), s(3)))],
            ),
            child: Text(text,
                style: TextStyle(color: Colors.white, fontSize: s(14.5), height: 1.25)),
          ),
        ),
      ],
    );
  }
}

class _ArrowPainter extends CustomPainter {
  @override
  void paint(Canvas c, Size sz) {
    final w = sz.width, h = sz.height;
    final p = Path()
      ..moveTo(w * 0.15, 0)
      ..lineTo(w * 0.95, h * 0.45)
      ..lineTo(w * 0.62, h * 0.52)
      ..lineTo(w * 0.85, h * 0.95)
      ..lineTo(w * 0.6, h)
      ..lineTo(w * 0.42, h * 0.58)
      ..lineTo(w * 0.15, h * 0.75)
      ..close();
    c.drawPath(p, Paint()..color = C.callout);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// White popup card with the yellow header, as used by shops and settings.
class PopupCard extends StatelessWidget {
  final String title;
  final Widget child;
  final double width;
  final double height;
  final VoidCallback onClose;
  final Widget? headerLeft;
  const PopupCard(
      {super.key,
      required this.title,
      required this.child,
      required this.width,
      required this.height,
      required this.onClose,
      this.headerLeft});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: s(width),
      height: s(height),
      child: CustomPaint(
        painter: _CardPainter(),
        child: Column(
          children: [
            Container(
              height: s(50),
              color: C.header,
              padding: EdgeInsets.symmetric(horizontal: s(20)),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Text(title,
                      style: TextStyle(
                          fontSize: s(22),
                          color: const Color(0xFF3A3A3A),
                          fontWeight: FontWeight.w500)),
                  if (headerLeft != null)
                    Align(alignment: Alignment.centerLeft, child: headerLeft!),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Tap(
                      onTap: onClose,
                      child: Container(
                        width: s(38),
                        height: s(38),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.4),
                          border: Border.all(color: const Color(0xFF333333), width: s(2.6)),
                        ),
                        child: Icon(Icons.close_rounded,
                            color: const Color(0xFF333333), size: s(28)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(child: child),
          ],
        ),
      ),
    );
  }
}

class _CardPainter extends CustomPainter {
  @override
  void paint(Canvas c, Size sz) {
    final r = Offset.zero & sz;
    c.drawRect(r.shift(const Offset(3, 4)), Paint()..color = Colors.black26);
    c.drawRect(r, Paint()..color = Colors.white);
    // folded corners
    final f = sz.shortestSide * 0.05;
    final fold = Paint()..color = const Color(0xFFE6E6E6);
    c.drawPath(
        Path()
          ..moveTo(sz.width - f, sz.height)
          ..lineTo(sz.width, sz.height - f)
          ..lineTo(sz.width - f * 0.8, sz.height - f * 0.8)
          ..close(),
        fold);
    c.drawPath(
        Path()
          ..moveTo(0, f)
          ..lineTo(f, 0)
          ..lineTo(f * 0.8, f * 0.8)
          ..close(),
        fold);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Coin balance pill shown in shop headers.
class CoinPill extends StatelessWidget {
  final int coins;
  const CoinPill(this.coins, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: s(150),
      height: s(34),
      decoration: BoxDecoration(
        color: const Color(0xFFC9A355),
        borderRadius: BorderRadius.circular(s(17)),
      ),
      padding: EdgeInsets.only(left: s(4)),
      child: Row(children: [
        CoinIcon(size: s(30), plus: true),
        SizedBox(width: s(6)),
        Text('$coins', style: TextStyle(color: Colors.white, fontSize: s(20))),
      ]),
    );
  }
}

void showToast(BuildContext context, String msg) {
  final overlay = Overlay.of(context);
  late OverlayEntry e;
  e = OverlayEntry(
    builder: (_) => Positioned(
      left: 0,
      right: 0,
      top: MediaQuery.of(context).size.height * 0.22,
      child: IgnorePointer(
        child: Center(
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: s(24), vertical: s(10)),
            color: Colors.black.withOpacity(0.55),
            child: Text(msg, style: TextStyle(color: Colors.white, fontSize: s(16))),
          ),
        ),
      ),
    ),
  );
  overlay.insert(e);
  Future.delayed(const Duration(milliseconds: 1800), e.remove);
}

/// Shows [child] centered above a dimmed backdrop.
Future<T?> showPopup<T>(BuildContext context, Widget child) {
  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.black.withOpacity(0.38),
    transitionDuration: const Duration(milliseconds: 180),
    pageBuilder: (_, __, ___) => Center(child: child),
    transitionBuilder: (_, a, __, child) => Opacity(
      opacity: a.value,
      child: Transform.scale(scale: 0.85 + 0.15 * Curves.easeOutBack.transform(a.value), child: child),
    ),
  );
}
