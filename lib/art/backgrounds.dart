import 'dart:math' as math;

import 'package:flutter/material.dart';

class BgItem {
  final String id;
  final int price;
  final bool iap;
  const BgItem(this.id, this.price, {this.iap = false});
}

const bgItems = [
  BgItem('notebook', 0),
  BgItem('beach', 200),
  BgItem('football', 500),
  BgItem('carnival', 1000),
  BgItem('ocean', 2000),
  BgItem('hawaii', 2000),
  BgItem('farm', 2000),
  BgItem('egypt', 4000),
  BgItem('temple', 4000),
  BgItem('christmas', 4000, iap: true),
];

/// Paints a paper background into [r] (screen space).
void paintPaper(Canvas c, Rect r, String id) {
  c.save();
  c.clipRect(r);
  c.drawRect(r, Paint()..color = const Color(0xFFFEFEFE));
  final u = r.width / 100;
  switch (id) {
    case 'notebook':
      _lines(c, r, u);
      _notebookDoodles(c, r, u);
    case 'beach':
      _dots(c, r, u);
      _beach(c, r, u);
    default:
      _dots(c, r, u);
      _themed(c, r, u, id);
  }
  c.restore();
}

void _lines(Canvas c, Rect r, double u) {
  final p = Paint()
    ..color = const Color(0xFFD5E4F0)
    ..strokeWidth = math.max(0.6, u * 0.12);
  for (var y = r.top + u * 2.2; y < r.bottom; y += u * 2.2) {
    c.drawLine(Offset(r.left, y), Offset(r.right, y), p);
  }
}

void _dots(Canvas c, Rect r, double u) {
  final p = Paint()..color = const Color(0xFFC3D9EA);
  final rad = math.max(0.5, u * 0.16);
  for (var y = r.top + u * 1.6; y < r.bottom; y += u * 2.6) {
    for (var x = r.left + u * 1.3; x < r.right; x += u * 2.6) {
      c.drawCircle(Offset(x, y), rad, p);
    }
  }
}

Paint _stroke(Color col, double w) => Paint()
  ..color = col
  ..style = PaintingStyle.stroke
  ..strokeWidth = w
  ..strokeCap = StrokeCap.round
  ..strokeJoin = StrokeJoin.round;

void _cloud(Canvas c, Offset o, double s, Paint p) {
  final path = Path()
    ..moveTo(o.dx - s * 2, o.dy)
    ..arcToPoint(Offset(o.dx - s, o.dy - s * 0.8), radius: Radius.circular(s * 0.6))
    ..arcToPoint(Offset(o.dx + s * 0.5, o.dy - s * 0.9), radius: Radius.circular(s * 0.9))
    ..arcToPoint(Offset(o.dx + s * 2, o.dy), radius: Radius.circular(s * 0.8))
    ..close();
  c.drawPath(path, p);
}

void _notebookDoodles(Canvas c, Rect r, double u) {
  final p = _stroke(const Color(0xFFBFE3E3), u * 0.18);
  Offset at(double x, double y) => Offset(r.left + x * u, r.top + y * u);
  _cloud(c, at(25, 7), u * 3, p);
  _cloud(c, at(72, 6), u * 2.5, p);
  // little tree
  c.drawPath(
      Path()
        ..moveTo(at(10, 44).dx, at(10, 44).dy)
        ..lineTo(at(14, 36).dx, at(14, 36).dy)
        ..lineTo(at(18, 44).dx, at(18, 44).dy)
        ..close(),
      p);
  c.drawPath(
      Path()
        ..moveTo(at(11, 39).dx, at(11, 39).dy)
        ..lineTo(at(14, 32).dx, at(14, 32).dy)
        ..lineTo(at(17, 39).dx, at(17, 39).dy),
      p);
  // house
  c.drawRect(Rect.fromPoints(at(6, 18), at(13, 24)), p);
  c.drawPath(
      Path()
        ..moveTo(at(5, 18).dx, at(5, 18).dy)
        ..lineTo(at(9.5, 13.5).dx, at(9.5, 13.5).dy)
        ..lineTo(at(14, 18).dx, at(14, 18).dy),
      p);
  // cat face
  c.drawCircle(at(90, 18), u * 3, p);
  c.drawPath(
      Path()
        ..moveTo(at(87.5, 16).dx, at(87.5, 16).dy)
        ..lineTo(at(87.5, 13).dx, at(87.5, 13).dy)
        ..lineTo(at(89.5, 15.2).dx, at(89.5, 15.2).dy),
      p);
  c.drawPath(
      Path()
        ..moveTo(at(92.5, 16).dx, at(92.5, 16).dy)
        ..lineTo(at(92.5, 13).dx, at(92.5, 13).dy)
        ..lineTo(at(90.5, 15.2).dx, at(90.5, 15.2).dy),
      p);
  // lamp + triangle
  c.drawPath(
      Path()
        ..moveTo(at(55, 40).dx, at(55, 40).dy)
        ..lineTo(at(58, 34).dx, at(58, 34).dy)
        ..lineTo(at(61, 40).dx, at(61, 40).dy)
        ..close(),
      p);
  c.drawCircle(at(80, 40), u * 2, p);
  c.drawLine(at(80, 42), at(80, 46), p);
}

void _beach(Canvas c, Rect r, double u) {
  Offset at(double x, double y) => Offset(r.left + x * u, r.top + y * u);
  // sand
  final sand = Path()
    ..moveTo(at(0, 50).dx, at(0, 50).dy)
    ..quadraticBezierTo(at(40, 40).dx, at(40, 40).dy, at(100, 44).dx, at(100, 44).dy)
    ..lineTo(r.right, r.bottom)
    ..lineTo(r.left, r.bottom)
    ..close();
  c.drawPath(sand, Paint()..color = const Color(0x55F9E7A6));
  // sea lines
  final sea = _stroke(const Color(0x6688C6E8), u * 0.18);
  for (var i = 0; i < 3; i++) {
    final y = 32.0 + i * 3;
    final p = Path()..moveTo(at(8, y).dx, at(8, y).dy);
    for (var x = 8.0; x < 90; x += 4) {
      p.quadraticBezierTo(at(x + 1, y - 0.8).dx, at(x + 1, y - 0.8).dy,
          at(x + 2, y).dx, at(x + 2, y).dy);
      p.quadraticBezierTo(at(x + 3, y + 0.8).dx, at(x + 3, y + 0.8).dy,
          at(x + 4, y).dx, at(x + 4, y).dy);
    }
    c.drawPath(p, sea);
  }
  // boat
  final hull = Path()
    ..moveTo(at(26, 22).dx, at(26, 22).dy)
    ..lineTo(at(70, 25).dx, at(70, 25).dy)
    ..quadraticBezierTo(at(66, 33).dx, at(66, 33).dy, at(56, 34).dx, at(56, 34).dy)
    ..lineTo(at(36, 33).dx, at(36, 33).dy)
    ..quadraticBezierTo(at(28, 30).dx, at(28, 30).dy, at(26, 22).dx, at(26, 22).dy)
    ..close();
  c.drawPath(hull, Paint()..color = const Color(0x66BFE3F7));
  c.drawPath(hull, _stroke(const Color(0x8899C5E2), u * 0.22));
  final cabin = Path()
    ..moveTo(at(34, 22.4).dx, at(34, 22.4).dy)
    ..lineTo(at(42, 15).dx, at(42, 15).dy)
    ..lineTo(at(56, 16).dx, at(56, 16).dy)
    ..lineTo(at(62, 24.5).dx, at(62, 24.5).dy)
    ..close();
  c.drawPath(cabin, Paint()..color = const Color(0x55DDF0FB));
  c.drawPath(cabin, _stroke(const Color(0x8899C5E2), u * 0.22));
  for (var x = 44.0; x < 56; x += 3) {
    c.drawLine(at(x, 16.5), at(x + 1.5, 21.5), _stroke(const Color(0x8899C5E2), u * 0.18));
  }
  c.drawPath(
      Path()
        ..moveTo(at(28, 26).dx, at(28, 26).dy)
        ..lineTo(at(68, 28).dx, at(68, 28).dy),
      _stroke(const Color(0x66F0B57A), u * 0.5));
  // sun
  final sun = _stroke(const Color(0x88F5D76E), u * 0.25);
  c.drawCircle(at(42, 3), u * 2.5, sun);
  for (var i = 0; i < 8; i++) {
    final a = i / 8 * math.pi * 2;
    c.drawLine(at(42 + math.cos(a) * 3.4, 3 + math.sin(a) * 3.4),
        at(42 + math.cos(a) * 4.6, 3 + math.sin(a) * 4.6), sun);
  }
  // umbrella
  final um = Path()
    ..moveTo(at(76, 20).dx, at(76, 20).dy)
    ..quadraticBezierTo(at(86, 8).dx, at(86, 8).dy, at(99, 14).dx, at(99, 14).dy)
    ..close();
  c.drawPath(um, Paint()..color = const Color(0x5582C8EA));
  c.drawPath(
      Path()
        ..moveTo(at(80, 13).dx, at(80, 13).dy)
        ..quadraticBezierTo(at(88, 9).dx, at(88, 9).dy, at(97, 12).dx, at(97, 12).dy),
      _stroke(const Color(0x66A7D88C), u * 0.9));
  c.drawLine(at(88, 15), at(84, 44), _stroke(const Color(0x8899C5E2), u * 0.25));
  // surfboard
  final sb = Path()
    ..moveTo(at(4, 56).dx, at(4, 56).dy)
    ..quadraticBezierTo(at(6, 34).dx, at(6, 34).dy, at(13, 30).dx, at(13, 30).dy)
    ..quadraticBezierTo(at(14, 44).dx, at(14, 44).dy, at(11, 56).dx, at(11, 56).dy)
    ..close();
  c.drawPath(sb, Paint()..color = const Color(0x5582C8EA));
  // sand castle + ball
  final sc = _stroke(const Color(0x88DCC17B), u * 0.2);
  c.drawRect(Rect.fromPoints(at(52, 42), at(60, 47)), sc);
  c.drawRect(Rect.fromPoints(at(54, 39), at(58, 42)), sc);
  c.drawCircle(at(94, 46), u * 2.4, _stroke(const Color(0x88E88AA0), u * 0.25));
  c.drawLine(at(91.8, 45), at(96.2, 47), _stroke(const Color(0x88E88AA0), u * 0.25));
  _cloud(c, at(22, 9), u * 3.6, _stroke(const Color(0x66A9CFE6), u * 0.2));
  _cloud(c, at(86, 4), u * 3, _stroke(const Color(0x66A9CFE6), u * 0.2));
}

void _themed(Canvas c, Rect r, double u, String id) {
  Offset at(double x, double y) => Offset(r.left + x * u, r.top + y * u);
  final (Color tint, Color line) = switch (id) {
    'football' => (const Color(0x33B8C4C8), const Color(0x88A0AAB0)),
    'carnival' => (const Color(0x33F5A7C8), const Color(0x8897C7E8)),
    'ocean' => (const Color(0x3390D4F2), const Color(0x8862B5DD)),
    'hawaii' => (const Color(0x33B6E39A), const Color(0x8886C46A)),
    'farm' => (const Color(0x33C3EAA0), const Color(0x8892C774)),
    'egypt' => (const Color(0x33F7E199), const Color(0x88D8B759)),
    'temple' => (const Color(0x33F9C6A2), const Color(0x88E48E6C)),
    _ => (const Color(0x33C9B8F2), const Color(0x88A58BE0)),
  };
  c.drawRect(r, Paint()..color = tint);
  final p = _stroke(line, u * 0.3);
  final f = Paint()..color = line.withOpacity(0.25);
  switch (id) {
    case 'football':
      c.drawRect(Rect.fromPoints(at(8, 8), at(92, 50)), p);
      c.drawLine(at(50, 8), at(50, 50), p);
      c.drawCircle(at(50, 29), u * 7, p);
      c.drawRect(Rect.fromPoints(at(8, 20), at(18, 38)), p);
      c.drawRect(Rect.fromPoints(at(82, 20), at(92, 38)), p);
    case 'carnival':
      c.drawCircle(at(32, 24), u * 15, p);
      for (var i = 0; i < 10; i++) {
        final a = i / 10 * math.pi * 2;
        c.drawLine(at(32, 24), at(32 + math.cos(a) * 15, 24 + math.sin(a) * 15), p);
        c.drawCircle(at(32 + math.cos(a) * 15, 24 + math.sin(a) * 15), u * 1.6, f);
      }
      c.drawLine(at(32, 24), at(24, 54), p);
      c.drawLine(at(32, 24), at(40, 54), p);
      final tent = Path()
        ..moveTo(at(60, 52).dx, at(60, 52).dy)
        ..lineTo(at(60, 36).dx, at(60, 36).dy)
        ..lineTo(at(72, 26).dx, at(72, 26).dy)
        ..lineTo(at(84, 36).dx, at(84, 36).dy)
        ..lineTo(at(84, 52).dx, at(84, 52).dy);
      c.drawPath(tent, p);
    case 'ocean':
      final whale = Path()
        ..moveTo(at(30, 30).dx, at(30, 30).dy)
        ..quadraticBezierTo(at(45, 10).dx, at(45, 10).dy, at(65, 26).dx, at(65, 26).dy)
        ..lineTo(at(75, 18).dx, at(75, 18).dy)
        ..lineTo(at(72, 30).dx, at(72, 30).dy)
        ..quadraticBezierTo(at(50, 42).dx, at(50, 42).dy, at(30, 30).dx, at(30, 30).dy);
      c.drawPath(whale, f);
      c.drawPath(whale, p);
      for (var i = 0; i < 4; i++) {
        c.drawCircle(at(15 + i * 22, 48 - (i % 2) * 3), u * 1.4, p);
      }
    case 'hawaii':
    case 'farm':
      final roof = Path()
        ..moveTo(at(30, 28).dx, at(30, 28).dy)
        ..lineTo(at(50, 14).dx, at(50, 14).dy)
        ..lineTo(at(70, 28).dx, at(70, 28).dy)
        ..close();
      c.drawPath(roof, f);
      c.drawPath(roof, p);
      c.drawRect(Rect.fromPoints(at(36, 28), at(64, 46)), p);
      c.drawRect(Rect.fromPoints(at(46, 34), at(54, 46)), p);
      if (id == 'hawaii') {
        c.drawLine(at(82, 50), at(86, 22), p);
        for (var i = 0; i < 5; i++) {
          final a = math.pi + i * math.pi / 4;
          c.drawLine(at(86, 22), at(86 + math.cos(a) * 9, 22 + math.sin(a) * 5 + 4), p);
        }
      } else {
        c.drawLine(at(4, 46), at(96, 46), p);
        for (var x = 8.0; x < 30; x += 4) {
          c.drawLine(at(x, 46), at(x, 40), p);
        }
      }
    case 'egypt':
      for (final py in [(30.0, 20.0, 18.0), (62.0, 26.0, 13.0)]) {
        final tri = Path()
          ..moveTo(at(py.$1 - py.$3, 48).dx, at(py.$1 - py.$3, 48).dy)
          ..lineTo(at(py.$1, py.$2).dx, at(py.$1, py.$2).dy)
          ..lineTo(at(py.$1 + py.$3, 48).dx, at(py.$1 + py.$3, 48).dy)
          ..close();
        c.drawPath(tri, f);
        c.drawPath(tri, p);
      }
      c.drawCircle(at(84, 12), u * 4, p);
    case 'temple':
      for (var i = 0; i < 3; i++) {
        final y = 18.0 + i * 10, w = 14.0 + i * 5;
        final roof = Path()
          ..moveTo(at(50 - w, y + 4).dx, at(50 - w, y + 4).dy)
          ..quadraticBezierTo(at(50, y - 4).dx, at(50, y - 4).dy,
              at(50 + w, y + 4).dx, at(50 + w, y + 4).dy);
        c.drawPath(roof, p);
        c.drawRect(Rect.fromPoints(at(50 - w * 0.7, y + 4), at(50 + w * 0.7, y + 9)), p);
      }
    default: // christmas
      for (var i = 0; i < 3; i++) {
        final tri = Path()
          ..moveTo(at(50 - 8 - i * 4, 22 + i * 9).dx, at(50 - 8 - i * 4, 22 + i * 9).dy)
          ..lineTo(at(50, 8 + i * 9).dx, at(50, 8 + i * 9).dy)
          ..lineTo(at(50 + 8 + i * 4, 22 + i * 9).dx, at(50 + 8 + i * 4, 22 + i * 9).dy)
          ..close();
        c.drawPath(tri, f);
        c.drawPath(tri, p);
      }
      c.drawRect(Rect.fromPoints(at(47, 40), at(53, 47)), p);
      for (final g in [(20.0, 42.0), (78.0, 40.0), (86.0, 46.0)]) {
        c.drawRect(Rect.fromCenter(center: at(g.$1, g.$2), width: u * 6, height: u * 5), p);
        c.drawLine(at(g.$1, g.$2 - 2.5), at(g.$1, g.$2 + 2.5), p);
      }
  }
  _cloud(c, at(18, 8), u * 3, _stroke(line.withOpacity(0.4), u * 0.2));
}
