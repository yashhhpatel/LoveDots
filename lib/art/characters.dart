import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'palette.dart';

class SkinItem {
  final String id;
  final int price;
  const SkinItem(this.id, this.price);
}

const ballItems = [
  SkinItem('classic', 0),
  SkinItem('witch', 1000),
  SkinItem('ninja', 1000),
  SkinItem('ladybug', 2000),
  SkinItem('cat', 2000),
  SkinItem('crown', 4000),
  SkinItem('glasses', 2000),
  SkinItem('bunny', 4000),
  SkinItem('devil', 4000),
];

const penItems = [
  SkinItem('classic', 0),
  SkinItem('heart', 1000),
  SkinItem('rose', 4000),
  SkinItem('bear', 2000),
  SkinItem('reindeer', 2000),
  SkinItem('candy', 4000),
  SkinItem('snowman', 4000),
];

Color _grey(Color c) {
  final l = (0.3 * c.red + 0.59 * c.green + 0.11 * c.blue).round();
  final g = (l * 0.55 + 60).clamp(0, 255).toInt();
  return Color.fromARGB(c.alpha, g, g, g);
}

/// Draws one ball. [look] is the direction the eyes look at.
void paintBall(Canvas c, Offset o, double r,
    {required bool blue,
    String skin = 'classic',
    Offset look = Offset.zero,
    bool happy = false,
    bool grey = false}) {
  Color k(Color col) => grey ? _grey(col) : col;
  var body = blue ? C.ballBlue : C.ballPink;
  var edge = blue ? C.ballBlueEdge : C.ballPinkEdge;
  if (skin == 'ladybug') {
    body = blue ? const Color(0xFF2FB5E8) : const Color(0xFFE53935);
    edge = blue ? const Color(0xFF1C8DBA) : const Color(0xFFB71C1C);
  } else if (skin == 'ninja') {
    body = blue ? const Color(0xFF3A3F55) : const Color(0xFF5B2A86);
    edge = blue ? const Color(0xFF23263A) : const Color(0xFF3E1A5E);
  }

  // accessories behind the body
  if (skin == 'bunny') {
    for (final s in [-1.0, 1.0]) {
      final ear = RRect.fromRectAndRadius(
          Rect.fromCenter(
              center: o + Offset(s * r * 0.42, -r * 1.25),
              width: r * 0.55,
              height: r * 1.3),
          Radius.circular(r * 0.3));
      c.drawRRect(ear, Paint()..color = k(Colors.white));
      c.drawRRect(ear.deflate(r * 0.12), Paint()..color = k(const Color(0xFFF8B6C8)));
    }
  }
  if (skin == 'cat') {
    for (final s in [-1.0, 1.0]) {
      final ear = Path()
        ..moveTo(o.dx + s * r * 0.95, o.dy - r * 0.2)
        ..lineTo(o.dx + s * r * 0.75, o.dy - r * 1.25)
        ..lineTo(o.dx + s * r * 0.15, o.dy - r * 0.85)
        ..close();
      c.drawPath(ear, Paint()..color = k(edge));
    }
  }

  c.drawCircle(o, r, Paint()..color = k(edge));
  c.drawCircle(o, r * 0.9, Paint()..color = k(body));
  c.drawCircle(o + Offset(-r * 0.35, -r * 0.4), r * 0.22,
      Paint()..color = Colors.white.withOpacity(0.35));

  if (skin == 'ladybug' && !blue) {
    final sp = Paint()..color = k(Colors.black87);
    for (final d in [
      const Offset(-0.55, 0.35),
      const Offset(0.55, 0.35),
      const Offset(0, 0.62),
      const Offset(-0.25, -0.62),
      const Offset(0.4, -0.55)
    ]) {
      c.drawCircle(o + d * r, r * 0.14, sp);
    }
  }

  // face
  final dir = look.distance > 0.001 ? look / look.distance : Offset.zero;
  final faceO = o + dir * r * 0.18 + Offset(0, -r * 0.05);
  final eyeDx = r * 0.32;
  if (happy) {
    final p = Paint()
      ..color = k(Colors.black)
      ..style = PaintingStyle.stroke
      ..strokeWidth = r * 0.14
      ..strokeCap = StrokeCap.round;
    for (final s in [-1.0, 1.0]) {
      final e = faceO + Offset(s * eyeDx, -r * 0.08);
      c.drawArc(Rect.fromCircle(center: e, radius: r * 0.2), math.pi * 1.1,
          math.pi * 0.8, false, p);
    }
    c.drawArc(Rect.fromCircle(center: faceO + Offset(0, r * 0.2), radius: r * 0.25),
        math.pi * 0.15, math.pi * 0.7, false, p);
  } else {
    for (final s in [-1.0, 1.0]) {
      final e = faceO + Offset(s * eyeDx, -r * 0.05);
      c.drawCircle(e, r * 0.3, Paint()..color = k(Colors.white));
      c.drawCircle(
          e,
          r * 0.3,
          Paint()
            ..color = k(Colors.black)
            ..style = PaintingStyle.stroke
            ..strokeWidth = r * 0.07);
      final pupil = e + dir * r * 0.1;
      c.drawCircle(pupil, r * 0.17, Paint()..color = k(Colors.black));
      c.drawCircle(pupil + Offset(r * 0.06, -r * 0.06), r * 0.06,
          Paint()..color = Colors.white);
    }
    if (!blue) {
      c.drawCircle(faceO + Offset(-r * 0.62, r * 0.32), r * 0.12,
          Paint()..color = k(const Color(0x66FFFFFF)));
    }
  }

  // accessories in front
  switch (skin) {
    case 'witch':
      final hat = Path()
        ..moveTo(o.dx - r * 1.05, o.dy - r * 0.6)
        ..lineTo(o.dx + r * 1.05, o.dy - r * 0.6)
        ..lineTo(o.dx + r * 0.45, o.dy - r * 0.85)
        ..lineTo(o.dx + r * 0.35, o.dy - r * 1.9)
        ..lineTo(o.dx - r * 0.45, o.dy - r * 0.85)
        ..close();
      c.drawPath(hat, Paint()..color = k(blue ? const Color(0xFF5B3A8E) : const Color(0xFF3D2466)));
      c.drawRect(Rect.fromLTWH(o.dx - r * 0.5, o.dy - r * 0.95, r, r * 0.16),
          Paint()..color = k(const Color(0xFFFFC83D)));
    case 'ninja':
      c.drawRect(Rect.fromLTWH(o.dx - r * 0.95, o.dy - r * 0.42, r * 1.9, r * 0.22),
          Paint()..color = k(const Color(0xFFE53935)));
      c.drawLine(o + Offset(r * 0.9, -r * 0.3), o + Offset(r * 1.4, -r * 0.05),
          Paint()
            ..color = k(const Color(0xFFE53935))
            ..strokeWidth = r * 0.14);
    case 'crown':
      final cr = Path()
        ..moveTo(o.dx - r * 0.55, o.dy - r * 0.75)
        ..lineTo(o.dx - r * 0.6, o.dy - r * 1.35)
        ..lineTo(o.dx - r * 0.25, o.dy - r * 1.05)
        ..lineTo(o.dx, o.dy - r * 1.45)
        ..lineTo(o.dx + r * 0.25, o.dy - r * 1.05)
        ..lineTo(o.dx + r * 0.6, o.dy - r * 1.35)
        ..lineTo(o.dx + r * 0.55, o.dy - r * 0.75)
        ..close();
      c.drawPath(cr, Paint()..color = k(C.gold));
    case 'glasses':
      final g = Paint()..color = k(Colors.black);
      for (final s in [-1.0, 1.0]) {
        c.drawOval(
            Rect.fromCenter(
                center: faceO + Offset(s * eyeDx, -r * 0.05),
                width: r * 0.62,
                height: r * 0.48),
            g);
      }
      c.drawLine(faceO + Offset(-eyeDx * 0.4, -r * 0.1), faceO + Offset(eyeDx * 0.4, -r * 0.1),
          g..strokeWidth = r * 0.08);
    case 'devil':
      for (final s in [-1.0, 1.0]) {
        final horn = Path()
          ..moveTo(o.dx + s * r * 0.25, o.dy - r * 0.85)
          ..quadraticBezierTo(o.dx + s * r * 0.75, o.dy - r * 1.1,
              o.dx + s * r * 0.75, o.dy - r * 1.55)
          ..quadraticBezierTo(o.dx + s * r * 0.75, o.dy - r * 1.0,
              o.dx + s * r * 0.65, o.dy - r * 0.62)
          ..close();
        c.drawPath(horn, Paint()..color = k(const Color(0xFFC62828)));
      }
  }
}

/// Draws a pen whose nib touches [tip]. [s] is the pen length in pixels.
void paintPen(Canvas c, Offset tip, double s, String id, {bool shadow = true}) {
  const angle = -1.02; // pen leans up-right
  if (shadow) {
    c.save();
    c.translate(tip.dx, tip.dy);
    c.rotate(-0.55);
    final sh = RRect.fromRectAndRadius(
        Rect.fromLTWH(s * 0.06, -s * 0.05, s * 0.9, s * 0.1), Radius.circular(s * 0.05));
    c.drawRRect(sh, Paint()
      ..color = Colors.black.withOpacity(0.12)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, s * 0.025));
    c.restore();
  }
  c.save();
  c.translate(tip.dx, tip.dy);
  c.rotate(angle);
  final w = s * 0.085;
  final (Color shaft, Color shaftHi, Color trim) = switch (id) {
    'heart' => (const Color(0xFFB8BEC6), const Color(0xFFE9EDF1), const Color(0xFF6F757C)),
    'rose' => (const Color(0xFFF26D9A), const Color(0xFFFFB0C9), const Color(0xFFC2185B)),
    'bear' => (const Color(0xFFBFC5CC), const Color(0xFFEEF1F4), const Color(0xFF7A8189)),
    'reindeer' => (const Color(0xFFCFD3D8), const Color(0xFFF2F4F6), const Color(0xFF6D4C41)),
    'candy' => (const Color(0xFFFFFFFF), const Color(0xFFFFFFFF), const Color(0xFFD32F2F)),
    'snowman' => (const Color(0xFF3E4B5B), const Color(0xFF6F7F92), const Color(0xFFB0BEC5)),
    _ => (const Color(0xFF243B4E), const Color(0xFF4F6B82), const Color(0xFFC9D1D9)),
  };
  // nib
  final nib = Path()
    ..moveTo(0, 0)
    ..lineTo(s * 0.13, -w * 0.5)
    ..lineTo(s * 0.13, w * 0.5)
    ..close();
  c.drawPath(nib, Paint()..color = const Color(0xFFC8CDD3));
  c.drawLine(Offset.zero, Offset(s * 0.1, 0),
      Paint()
        ..color = const Color(0xFF6B7178)
        ..strokeWidth = s * 0.006);
  // grip + body
  final body = RRect.fromRectAndRadius(
      Rect.fromLTWH(s * 0.12, -w / 2, s * 0.8, w), Radius.circular(w / 2));
  c.drawRRect(
      body,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [shaftHi, shaft, shaft],
        ).createShader(body.outerRect));
  if (id == 'candy') {
    c.save();
    c.clipRRect(body);
    final st = Paint()
      ..color = trim
      ..strokeWidth = w * 0.45;
    for (var x = s * 0.1; x < s; x += w * 1.1) {
      c.drawLine(Offset(x, w), Offset(x + w, -w), st);
    }
    c.restore();
  }
  c.drawRect(Rect.fromLTWH(s * 0.36, -w / 2, s * 0.025, w), Paint()..color = trim);
  c.drawRect(Rect.fromLTWH(s * 0.78, -w / 2, s * 0.02, w), Paint()..color = trim);
  // clip on the cap
  c.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(s * 0.5, -w * 0.75, s * 0.3, w * 0.22),
          Radius.circular(w * 0.1)),
      Paint()..color = trim);

  // topper
  final top = Offset(s * 0.95, 0);
  c.translate(top.dx, top.dy);
  c.rotate(-angle); // keep toppers upright
  final tp = s * 0.11;
  switch (id) {
    case 'heart':
    case 'rose':
      final col = id == 'heart' ? const Color(0xFF212121) : const Color(0xFFE53950);
      final h = Path()
        ..moveTo(0, tp * 0.9)
        ..cubicTo(-tp * 1.6, -tp * 0.1, -tp * 0.7, -tp * 1.3, 0, -tp * 0.45)
        ..cubicTo(tp * 0.7, -tp * 1.3, tp * 1.6, -tp * 0.1, 0, tp * 0.9);
      c.drawPath(h, Paint()..color = col);
      if (id == 'heart') {
        c.drawPath(h, Paint()
          ..color = const Color(0xFFB0B6BD)
          ..style = PaintingStyle.stroke
          ..strokeWidth = tp * 0.15);
      }
    case 'bear':
      final f = Paint()..color = const Color(0xFF9E9E9E);
      c.drawCircle(Offset(-tp * 0.6, -tp * 0.6), tp * 0.35, f);
      c.drawCircle(Offset(tp * 0.6, -tp * 0.6), tp * 0.35, f);
      c.drawCircle(Offset.zero, tp * 0.75, f);
      c.drawCircle(Offset(0, tp * 0.2), tp * 0.3, Paint()..color = const Color(0xFFE0E0E0));
      c.drawCircle(Offset(-tp * 0.25, -tp * 0.15), tp * 0.08, Paint()..color = Colors.black);
      c.drawCircle(Offset(tp * 0.25, -tp * 0.15), tp * 0.08, Paint()..color = Colors.black);
    case 'reindeer':
      final f = Paint()..color = const Color(0xFF8D6E63);
      c.drawCircle(Offset.zero, tp * 0.7, f);
      final ant = Paint()
        ..color = const Color(0xFF5D4037)
        ..strokeWidth = tp * 0.15
        ..strokeCap = StrokeCap.round;
      for (final sgn in [-1.0, 1.0]) {
        c.drawLine(Offset(sgn * tp * 0.3, -tp * 0.5), Offset(sgn * tp * 0.8, -tp * 1.4), ant);
        c.drawLine(Offset(sgn * tp * 0.6, -tp * 1.0), Offset(sgn * tp * 1.1, -tp * 1.0), ant);
      }
      c.drawCircle(Offset(0, tp * 0.35), tp * 0.18, Paint()..color = const Color(0xFFE53935));
    case 'candy':
      final hook = Paint()
        ..color = const Color(0xFFD32F2F)
        ..style = PaintingStyle.stroke
        ..strokeWidth = tp * 0.35
        ..strokeCap = StrokeCap.round;
      c.drawArc(Rect.fromCircle(center: Offset(tp * 0.45, -tp * 0.2), radius: tp * 0.5),
          math.pi, math.pi, false, hook);
      c.drawCircle(Offset(tp * 0.3, tp * 0.2), tp * 0.3, Paint()..color = const Color(0xFF43A047));
    case 'snowman':
      c.drawCircle(Offset.zero, tp * 0.6, Paint()..color = Colors.white);
      c.drawCircle(Offset(0, -tp * 0.85), tp * 0.42, Paint()..color = Colors.white);
      c.drawRect(Rect.fromCenter(center: Offset(0, -tp * 1.3), width: tp * 0.8, height: tp * 0.35),
          Paint()..color = Colors.black87);
      c.drawCircle(Offset(-tp * 0.12, -tp * 0.9), tp * 0.06, Paint()..color = Colors.black);
      c.drawCircle(Offset(tp * 0.12, -tp * 0.9), tp * 0.06, Paint()..color = Colors.black);
    default:
      c.drawCircle(Offset.zero, w * 0.5, Paint()..color = shaft);
  }
  c.restore();
}
