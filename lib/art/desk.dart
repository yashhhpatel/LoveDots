import 'dart:math' as math;

import 'package:flutter/material.dart';

/// The cork/craft desk with stationery that surrounds the paper.
class DeskPainter extends CustomPainter {
  final Rect paper;
  DeskPainter(this.paper);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFFD99F5E));
    final grid = Paint()
      ..color = const Color(0xFFBF8344)
      ..strokeWidth = h * 0.003;
    final step = h * 0.052;
    for (var x = 0.0; x < w; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, h), grid);
    }
    for (var y = 0.0; y < h; y += step) {
      canvas.drawLine(Offset(0, y), Offset(w, y), grid);
    }

    final u = h / 100;
    final lx = paper.left; // width of the left margin
    final rx = paper.right;

    // ---- left side ----
    _sheet(canvas, Offset(lx * 0.35, h * 0.14), lx * 0.9, h * 0.3, -0.25,
        const Color(0xFFF7E8B0));
    _torn(canvas, Rect.fromLTWH(-u * 2, h * 0.02, lx * 0.38, h * 0.55),
        const Color(0xFF38C6E6), 0.12);
    _sheet(canvas, Offset(lx * 0.3, h * 0.78), lx * 0.9, h * 0.32, 0.2,
        const Color(0xFFF6E9C4));
    _torn(canvas, Rect.fromLTWH(lx * 0.05, h * 0.62, lx * 0.5, h * 0.3),
        const Color(0xFF38C6E6), -0.08);
    _sheet(canvas, Offset(lx * 0.25, h * 0.98), lx * 1.2, h * 0.16, 0.1,
        const Color(0xFFE3A869));
    _pencil(canvas, Offset(lx * 0.12, -u * 2), Offset(lx * 0.78, h * 0.37), u);
    _blob(canvas, Offset(lx * 0.28, h * 0.7), u * 4.2, const Color(0xFF9B3FC0));
    _clip(canvas, Offset(lx * 0.62, h * 0.24), u, 0.5);
    _clip(canvas, Offset(lx * 0.62, h * 0.53), u, 0.45);
    _sheet(canvas, Offset(lx * 0.5, h * 0.3), lx * 0.5, h * 0.06, 0.6,
        const Color(0xFFF0A23A));

    // ---- right side ----
    final rw = w - rx;
    _sheet(canvas, Offset(rx + rw * 0.5, h * 0.12), rw * 1.1, h * 0.28, 0.35,
        const Color(0xFFF8F0D8));
    _sheet(canvas, Offset(rx + rw * 0.55, h * 0.5), rw * 1.1, h * 0.36, -0.2,
        const Color(0xFFF6EAC7));
    _sheet(canvas, Offset(rx + rw * 0.5, h * 0.86), rw * 1.1, h * 0.3, 0.15,
        const Color(0xFFF8F0D8));
    _torn(canvas, Rect.fromLTWH(rx + rw * 0.55, h * 0.4, rw * 0.5, h * 0.62),
        const Color(0xFF38C6E6), 0.0);
    _torn(canvas, Rect.fromLTWH(w - rw * 0.25, -u * 2, rw * 0.35, h * 0.7),
        const Color(0xFFF07CC3), 0.0);
    _tape(canvas, Offset(rx + rw * 0.55, h * 0.27), u * 6.2);
    _pin(canvas, Offset(rx + rw * 0.5, h * 0.54), u);
    _pin(canvas, Offset(rx + rw * 0.45, h * 0.82), u);
    _clip(canvas, Offset(rx + rw * 0.3, h * 0.92), u, -0.6);
  }

  void _sheet(Canvas c, Offset center, double w, double h, double rot, Color col) {
    c.save();
    c.translate(center.dx, center.dy);
    c.rotate(rot);
    final r = Rect.fromCenter(center: Offset.zero, width: w, height: h);
    c.drawRect(r.shift(const Offset(2, 3)), Paint()..color = Colors.black12);
    c.drawRect(r, Paint()..color = col);
    c.restore();
  }

  void _torn(Canvas c, Rect r, Color col, double rot) {
    c.save();
    c.translate(r.center.dx, r.center.dy);
    c.rotate(rot);
    final hw = r.width / 2, hh = r.height / 2;
    final p = Path()..moveTo(-hw, -hh);
    p.lineTo(hw * 0.6, -hh);
    final teeth = 18;
    for (var i = 0; i <= teeth; i++) {
      final y = -hh + r.height * i / teeth;
      p.lineTo(i.isEven ? hw : hw * 0.75, y);
    }
    p.lineTo(-hw, hh);
    p.close();
    c.drawPath(p.shift(const Offset(2, 2)), Paint()..color = Colors.black12);
    c.drawPath(p, Paint()..color = col);
    final line = Paint()
      ..color = Colors.white.withOpacity(0.35)
      ..strokeWidth = 1;
    for (var y = -hh + 8; y < hh; y += 10) {
      c.drawLine(Offset(-hw, y), Offset(hw * 0.7, y), line);
    }
    c.restore();
  }

  void _pencil(Canvas c, Offset a, Offset b, double u) {
    final d = b - a;
    final len = d.distance;
    c.save();
    c.translate(a.dx, a.dy);
    c.rotate(math.atan2(d.dy, d.dx));
    final t = u * 3.2;
    c.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(0, -t / 2 + 3, len, t),
            Radius.circular(t / 3)),
        Paint()..color = Colors.black12);
    c.drawRect(Rect.fromLTWH(0, -t / 2, len * 0.82, t),
        Paint()..color = const Color(0xFFF46D9C));
    c.drawRect(Rect.fromLTWH(0, -t / 2, len * 0.82, t * 0.33),
        Paint()..color = const Color(0xFFF896B8));
    final tip = Path()
      ..moveTo(len * 0.82, -t / 2)
      ..lineTo(len, 0)
      ..lineTo(len * 0.82, t / 2)
      ..close();
    c.drawPath(tip, Paint()..color = const Color(0xFFF5C98B));
    final lead = Path()
      ..moveTo(len * 0.95, -t * 0.14)
      ..lineTo(len, 0)
      ..lineTo(len * 0.95, t * 0.14)
      ..close();
    c.drawPath(lead, Paint()..color = const Color(0xFFE0457B));
    c.drawRect(Rect.fromLTWH(len * 0.04, -t / 2, len * 0.05, t),
        Paint()..color = const Color(0xFFE8E8E8));
    c.restore();
  }

  void _blob(Canvas c, Offset o, double r, Color col) {
    final p = Path();
    for (var i = 0; i <= 24; i++) {
      final a = i / 24 * math.pi * 2;
      final rr = r * (1 + 0.18 * math.sin(a * 3) + 0.1 * math.cos(a * 5));
      final pt = o + Offset(math.cos(a) * rr * 1.25, math.sin(a) * rr);
      i == 0 ? p.moveTo(pt.dx, pt.dy) : p.lineTo(pt.dx, pt.dy);
    }
    p.close();
    c.drawPath(p, Paint()..color = col);
    c.drawCircle(o + Offset(r * 1.9, r * 0.4), r * 0.28, Paint()..color = col);
    c.drawCircle(o + Offset(-r * 0.4, -r * 0.4), r * 0.3,
        Paint()..color = Colors.white24);
  }

  void _clip(Canvas c, Offset o, double u, double rot) {
    c.save();
    c.translate(o.dx, o.dy);
    c.rotate(rot);
    final body = RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset.zero, width: u * 9, height: u * 6),
        Radius.circular(u));
    c.drawRRect(body.shift(const Offset(2, 2)), Paint()..color = Colors.black12);
    c.drawRRect(body, Paint()..color = const Color(0xFFDD4FB0));
    c.drawRect(Rect.fromLTWH(-u * 4.5, -u * 3, u * 9, u * 1.2),
        Paint()..color = const Color(0xFFB83A93));
    final wire = Paint()
      ..color = const Color(0xFF7FD1C4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = u * 0.5;
    c.drawPath(
        Path()
          ..moveTo(-u * 2.5, -u * 3)
          ..lineTo(-u * 3.5, -u * 7)
          ..lineTo(u * 3.5, -u * 7)
          ..lineTo(u * 2.5, -u * 3),
        wire);
    c.restore();
  }

  void _tape(Canvas c, Offset o, double r) {
    c.drawCircle(o + const Offset(2, 3), r, Paint()..color = Colors.black12);
    c.drawCircle(o, r, Paint()..color = const Color(0xFF4D8FD9));
    c.drawCircle(o, r * 0.82, Paint()..color = const Color(0xFFE8B04A));
    c.drawCircle(o, r * 0.6, Paint()..color = const Color(0xFFF3E3B5));
    c.drawCircle(o, r * 0.42, Paint()..color = const Color(0xFFD99F5E));
    final dots = Paint()..color = const Color(0xFFFFE27A);
    for (var i = 0; i < 12; i++) {
      final a = i / 12 * math.pi * 2;
      c.drawCircle(o + Offset(math.cos(a), math.sin(a)) * r * 0.91, r * 0.05, dots);
    }
    final strip = Path()
      ..moveTo(o.dx - r * 0.6, o.dy + r * 0.7)
      ..quadraticBezierTo(o.dx - r * 1.1, o.dy + r * 1.5, o.dx - r * 0.5, o.dy + r * 2.0)
      ..lineTo(o.dx - r * 0.2, o.dy + r * 1.8)
      ..quadraticBezierTo(o.dx - r * 0.7, o.dy + r * 1.4, o.dx - r * 0.3, o.dy + r * 0.85)
      ..close();
    c.drawPath(strip, Paint()..color = const Color(0xFF3F7FC9));
  }

  void _pin(Canvas c, Offset o, double u) {
    c.drawOval(Rect.fromCenter(center: o + Offset(u * 1.5, u * 1.8), width: u * 5, height: u * 2),
        Paint()..color = Colors.black12);
    final cone = Path()
      ..moveTo(o.dx - u * 2.2, o.dy + u * 1.4)
      ..lineTo(o.dx, o.dy - u * 3.2)
      ..lineTo(o.dx + u * 2.2, o.dy + u * 1.4)
      ..close();
    c.drawPath(cone, Paint()..color = const Color(0xFF1E9C90));
    c.drawOval(Rect.fromCenter(center: o + Offset(0, u * 1.4), width: u * 4.4, height: u * 1.5),
        Paint()..color = const Color(0xFF167A70));
    c.drawCircle(o + Offset(0, -u * 3.2), u * 0.9, Paint()..color = const Color(0xFF26B5A6));
  }

  @override
  bool shouldRepaint(DeskPainter old) => old.paper != paper;
}

/// Light sheets peeking out under the play paper.
void paintPaperStack(Canvas c, Rect paper) {
  for (final s in [
    (0.012, const Color(0xFFE4E4E4), const Offset(6, 4)),
    (-0.008, const Color(0xFFF0F0F0), const Offset(-4, 3)),
  ]) {
    c.save();
    c.translate(paper.center.dx + s.$3.dx, paper.center.dy + s.$3.dy);
    c.rotate(s.$1);
    final r = Rect.fromCenter(
        center: Offset.zero, width: paper.width * 1.01, height: paper.height * 1.02);
    c.drawRect(r.shift(const Offset(2, 3)), Paint()..color = Colors.black12);
    c.drawRect(r, Paint()..color = s.$2);
    c.restore();
  }
}
