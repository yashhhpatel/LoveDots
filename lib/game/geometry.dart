import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../art/palette.dart';
import 'levels.dart';

/// Ear-clipping triangulation for a simple polygon.
List<List<Offset>> triangulate(List<Offset> input) {
  final pts = List<Offset>.from(input);
  final res = <List<Offset>>[];
  if (pts.length < 3) return res;
  double area = 0;
  for (var i = 0; i < pts.length; i++) {
    final a = pts[i], b = pts[(i + 1) % pts.length];
    area += a.dx * b.dy - b.dx * a.dy;
  }
  final idx = List<int>.generate(pts.length, (i) => i);
  if (area < 0) idx.setAll(0, idx.reversed.toList());
  double cross(Offset o, Offset a, Offset b) =>
      (a.dx - o.dx) * (b.dy - o.dy) - (a.dy - o.dy) * (b.dx - o.dx);
  bool inTri(Offset p, Offset a, Offset b, Offset c) {
    final d1 = cross(a, b, p), d2 = cross(b, c, p), d3 = cross(c, a, p);
    return d1 > 1e-9 && d2 > 1e-9 && d3 > 1e-9;
  }

  var guard = 0;
  while (idx.length > 3 && guard++ < 5000) {
    var clipped = false;
    for (var i = 0; i < idx.length; i++) {
      final ia = idx[(i - 1 + idx.length) % idx.length];
      final ib = idx[i];
      final ic = idx[(i + 1) % idx.length];
      final a = pts[ia], b = pts[ib], c = pts[ic];
      final cr = cross(a, b, c);
      if (cr <= 1e-9) {
        if (cr.abs() <= 1e-9) {
          // collinear: drop the middle vertex
          idx.removeAt(i);
          clipped = true;
          break;
        }
        continue;
      }
      var ok = true;
      for (final j in idx) {
        if (j == ia || j == ib || j == ic) continue;
        if (inTri(pts[j], a, b, c)) {
          ok = false;
          break;
        }
      }
      if (!ok) continue;
      res.add([a, b, c]);
      idx.removeAt(i);
      clipped = true;
      break;
    }
    if (!clipped) break;
  }
  if (idx.length == 3) {
    res.add([pts[idx[0]], pts[idx[1]], pts[idx[2]]]);
  }
  return res;
}

double distToSeg(Offset p, Offset a, Offset b) {
  final ab = b - a;
  final l2 = ab.dx * ab.dx + ab.dy * ab.dy;
  if (l2 == 0) return (p - a).distance;
  var t = ((p.dx - a.dx) * ab.dx + (p.dy - a.dy) * ab.dy) / l2;
  t = t.clamp(0.0, 1.0);
  return (p - (a + ab * t)).distance;
}

bool pointInPoly(Offset p, List<Offset> poly) {
  var inside = false;
  for (var i = 0, j = poly.length - 1; i < poly.length; j = i++) {
    final a = poly[i], b = poly[j];
    if ((a.dy > p.dy) != (b.dy > p.dy) &&
        p.dx < (b.dx - a.dx) * (p.dy - a.dy) / (b.dy - a.dy) + a.dx) {
      inside = !inside;
    }
  }
  return inside;
}

/// Whether a disc of radius [r] at [p] overlaps solid geometry.
bool geoHits(Geo g, Offset p, double r) {
  if (!g.solid) return false;
  switch (g.kind) {
    case GeoKind.circle:
      return (p - g.c).distance < g.r + r;
    case GeoKind.bar:
      final n = g.pts.length;
      for (var i = 0; i < n - 1 + (g.closed ? 1 : 0); i++) {
        if (distToSeg(p, g.pts[i], g.pts[(i + 1) % n]) < g.w / 2 + r) return true;
      }
      return false;
    case GeoKind.poly:
      if (pointInPoly(p, g.pts)) return true;
      final n = g.pts.length;
      for (var i = 0; i < n; i++) {
        if (distToSeg(p, g.pts[i], g.pts[(i + 1) % n]) < r) return true;
      }
      return false;
  }
}

Path polyPath(List<Offset> pts, {bool close = true}) {
  final p = Path()..moveTo(pts.first.dx, pts.first.dy);
  for (final e in pts.skip(1)) {
    p.lineTo(e.dx, e.dy);
  }
  if (close) p.close();
  return p;
}

/// Paints level geometry in paper units (canvas must already be scaled).
void paintGeos(Canvas c, List<Geo> geos, {Color color = C.teal}) {
  final fill = Paint()
    ..color = color
    ..isAntiAlias = true;
  for (final g in geos) {
    final paint = g.white ? (Paint()..color = Colors.white) : fill;
    switch (g.kind) {
      case GeoKind.poly:
        c.drawPath(polyPath(g.pts), paint);
      case GeoKind.circle:
        c.drawCircle(g.c, g.r, paint);
      case GeoKind.bar:
        c.drawPath(
            polyPath(g.pts, close: g.closed),
            Paint()
              ..color = paint.color
              ..style = PaintingStyle.stroke
              ..strokeWidth = g.w
              ..strokeCap = StrokeCap.round
              ..strokeJoin = StrokeJoin.round);
    }
  }
}

void paintDashed(Canvas c, List<Offset> pts, bool closed, double width,
    {Color color = const Color(0xFF333333), double dash = 1.0, double gap = 0.7}) {
  final p = Paint()
    ..color = color
    ..strokeWidth = width
    ..strokeCap = StrokeCap.round;
  final list = closed ? [...pts, pts.first] : pts;
  var on = true;
  var left = dash;
  for (var i = 1; i < list.length; i++) {
    var a = list[i - 1];
    final b = list[i];
    var segLen = (b - a).distance;
    final dir = segLen == 0 ? Offset.zero : (b - a) / segLen;
    while (segLen > 0) {
      final step = math.min(left, segLen);
      final e = a + dir * step;
      if (on) c.drawLine(a, e, p);
      a = e;
      segLen -= step;
      left -= step;
      if (left <= 1e-6) {
        on = !on;
        left = on ? dash : gap;
      }
    }
  }
}

/// Simple preview of a level (used by thumbnails and the help pages).
class LevelPreviewPainter extends CustomPainter {
  final Level level;
  final bool locked;
  final Color paper;
  LevelPreviewPainter(this.level, {this.locked = false, this.paper = Colors.white});

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, Paint()..color = locked ? const Color(0xFFA9A9A9) : paper);
    final k = math.min(size.width / kPaperW, size.height / kPaperH);
    canvas.translate((size.width - kPaperW * k) / 2, (size.height - kPaperH * k) / 2);
    canvas.scale(k);
    paintGeos(canvas, level.geos, color: locked ? const Color(0xFF2E7470) : C.teal);
    final r = kBallR * 0.8;
    canvas.drawCircle(level.blue, r, Paint()..color = locked ? const Color(0xFF2E7470) : C.ballBlue);
    canvas.drawCircle(level.pink, r, Paint()..color = locked ? const Color(0xFF8E3B55) : C.ballPink);
    canvas.restore();
  }

  @override
  bool shouldRepaint(LevelPreviewPainter old) =>
      old.level != level || old.locked != locked;
}
