import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../art/backgrounds.dart';
import '../art/characters.dart';
import '../art/desk.dart';
import '../art/palette.dart';
import 'geometry.dart';
import 'levels.dart';
import 'sim.dart';

class FxHeart {
  Offset p;
  Offset v;
  double life;
  final double max;
  final double size;
  final double rot;
  final Color color;
  FxHeart(this.p, this.v, this.max, this.size, this.rot, this.color) : life = 0;
}

/// Everything that is drawn on the paper during play.
class SceneState extends ChangeNotifier {
  Sim? sim;
  Level? level;
  String bg = 'notebook';
  String balls = 'classic';
  String pen = 'classic';
  bool hintVisible = false;
  double hintPen = -1; // 0..1 while the pen traces the hint
  final List<FxHeart> hearts = [];
  double ringT = -1;
  Offset ringC = Offset.zero;
  bool penVisible = true;

  void tick() => notifyListeners();
}

Path heartPath(Offset c, double s) {
  final p = Path()
    ..moveTo(c.dx, c.dy + s * 0.9)
    ..cubicTo(c.dx - s * 1.6, c.dy - s * 0.1, c.dx - s * 0.7, c.dy - s * 1.3, c.dx, c.dy - s * 0.45)
    ..cubicTo(c.dx + s * 0.7, c.dy - s * 1.3, c.dx + s * 1.6, c.dy - s * 0.1, c.dx, c.dy + s * 0.9);
  return p;
}

/// Point at fraction [t] of the poly-line [pts].
Offset alongPath(List<Offset> pts, double t, {bool closed = false}) {
  final list = closed ? [...pts, pts.first] : pts;
  if (list.length == 1) return list.first;
  var total = 0.0;
  for (var i = 1; i < list.length; i++) {
    total += (list[i] - list[i - 1]).distance;
  }
  var d = total * t.clamp(0.0, 1.0);
  for (var i = 1; i < list.length; i++) {
    final l = (list[i] - list[i - 1]).distance;
    if (d <= l) return Offset.lerp(list[i - 1], list[i], l == 0 ? 0 : d / l)!;
    d -= l;
  }
  return list.last;
}

List<Offset> partialPath(List<Offset> pts, double t, {bool closed = false}) {
  final list = closed ? [...pts, pts.first] : pts;
  var total = 0.0;
  for (var i = 1; i < list.length; i++) {
    total += (list[i] - list[i - 1]).distance;
  }
  var d = total * t.clamp(0.0, 1.0);
  final out = [list.first];
  for (var i = 1; i < list.length; i++) {
    final l = (list[i] - list[i - 1]).distance;
    if (d <= l) {
      out.add(Offset.lerp(list[i - 1], list[i], l == 0 ? 0 : d / l)!);
      return out;
    }
    out.add(list[i]);
    d -= l;
  }
  return out;
}

class ScenePainter extends CustomPainter {
  final SceneState st;
  final Rect paper;
  ScenePainter(this.st, this.paper) : super(repaint: st);

  @override
  void paint(Canvas canvas, Size size) {
    final sim = st.sim;
    final level = st.level;
    if (level == null) return;
    paintPaperStack(canvas, paper);
    paintPaper(canvas, paper, st.bg);
    final k = paper.width / kPaperW;

    canvas.save();
    canvas.clipRect(paper);
    canvas.translate(paper.left, paper.top);
    canvas.scale(k);

    if (level.text != null) {
      final tp = TextPainter(
        text: TextSpan(
            text: level.text,
            style: const TextStyle(color: Color(0xFF333333), fontSize: 2.3, height: 1.2)),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, level.textPos);
    }

    if (st.hintVisible) {
      final pts = st.hintPen >= 0
          ? partialPath(level.hint, st.hintPen, closed: level.hintClosed)
          : level.hint;
      final closed = st.hintPen < 0 && level.hintClosed;
      if (pts.length >= 2) {
        paintDashed(canvas, pts, closed, 0.28, dash: 1.1, gap: 0.75);
      }
    }

    paintGeos(canvas, level.geos);

    if (sim != null) {
      final lp = sim.linePoints;
      if (lp.length == 1) {
        canvas.drawCircle(lp.first, kLineR, Paint()..color = C.ink);
      } else if (lp.length > 1) {
        canvas.drawPath(
            polyPath(lp, close: false),
            Paint()
              ..color = C.ink
              ..style = PaintingStyle.stroke
              ..strokeWidth = kLineR * 2
              ..strokeCap = StrokeCap.round
              ..strokeJoin = StrokeJoin.round);
      }
      final bp = sim.bluePos, pp = sim.pinkPos;
      final happy = sim.state == SimState.won;
      paintBall(canvas, bp, kBallR, blue: true, skin: st.balls, look: pp - bp, happy: happy);
      paintBall(canvas, pp, kBallR, blue: false, skin: st.balls, look: bp - pp, happy: happy);
    }

    for (final h in st.hearts) {
      final a = (1 - h.life / h.max).clamp(0.0, 1.0);
      canvas.save();
      canvas.translate(h.p.dx, h.p.dy);
      canvas.rotate(h.rot);
      canvas.drawPath(heartPath(Offset.zero, h.size),
          Paint()..color = h.color.withOpacity(a));
      canvas.restore();
    }
    canvas.restore();

    if (st.ringT >= 0) {
      final t = st.ringT;
      final c = paper.topLeft + st.ringC * k;
      final r = (3 + 32 * Curves.easeOut.transform(t.clamp(0, 1))) * k;
      canvas.drawCircle(
          c,
          r,
          Paint()
            ..color = const Color(0xFFF2808F).withOpacity((1 - t).clamp(0, 1) * 0.75)
            ..style = PaintingStyle.stroke
            ..strokeWidth = k * 1.6);
    }

    // the pen follows the finger / the hint animation
    if (st.penVisible && sim != null) {
      Offset? tip;
      if (sim.state == SimState.drawing && sim.stroke.isNotEmpty) {
        tip = sim.stroke.last;
      } else if (st.hintPen >= 0 && st.hintPen <= 1) {
        tip = alongPath(level.hint, st.hintPen, closed: level.hintClosed);
      }
      if (tip != null) {
        paintPen(canvas, paper.topLeft + tip * k, k * 21, st.pen);
      }
    }
  }

  @override
  bool shouldRepaint(ScenePainter old) => old.paper != paper || old.st != st;
}

/// Page-turn transition: the old page peels away from the bottom-right corner.
class CurlPainter extends CustomPainter {
  final ui.Image image;
  final Rect paper;
  final double t;
  final double pr;
  CurlPainter(this.image, this.paper, this.t, this.pr);

  @override
  void paint(Canvas canvas, Size size) {
    final corner = paper.bottomRight;
    final dir = Offset(-1, -0.62);
    final n = dir / dir.distance;
    final maxL = (paper.topLeft - corner).dx * n.dx + (paper.topLeft - corner).dy * n.dy;
    final L = maxL * 1.25 * Curves.easeIn.transform(t);
    // fold line: points p with dot(p - corner, n) == L/2 ; peeled part: dot < L/2
    final c = L / 2;
    final rect = [paper.topLeft, paper.topRight, paper.bottomRight, paper.bottomLeft];
    double f(Offset p) => (p - corner).dx * n.dx + (p - corner).dy * n.dy;
    final remain = _clip(rect, (p) => f(p) - c);
    final peeled = _clip(rect, (p) => c - f(p));

    if (remain.length >= 3) {
      canvas.save();
      canvas.clipPath(polyPath(remain));
      final src = Rect.fromLTWH(paper.left * pr, paper.top * pr, paper.width * pr, paper.height * pr);
      canvas.drawImageRect(image, src, paper, Paint()..filterQuality = FilterQuality.medium);
      canvas.restore();
    }
    if (peeled.length >= 3) {
      final flap = peeled.map((p) {
        final d = f(p) - c;
        return p - n * (2 * d);
      }).toList();
      final path = polyPath(flap);
      canvas.drawPath(path.shift(const Offset(-4, -3)),
          Paint()
            ..color = Colors.black.withOpacity(0.18)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6));
      canvas.drawPath(path, Paint()..color = const Color(0xFFE8E8E8));
    }
  }

  List<Offset> _clip(List<Offset> poly, double Function(Offset) side) {
    final out = <Offset>[];
    for (var i = 0; i < poly.length; i++) {
      final a = poly[i], b = poly[(i + 1) % poly.length];
      final sa = side(a), sb = side(b);
      if (sa >= 0) out.add(a);
      if ((sa >= 0) != (sb >= 0)) {
        final t = sa / (sa - sb);
        out.add(Offset.lerp(a, b, t)!);
      }
    }
    return out;
  }

  @override
  bool shouldRepaint(CurlPainter old) => old.t != t || old.image != image;
}

Rect paperRectFor(Size size, double k) {
  var h = 460 * k;
  var w = h * kPaperW / kPaperH;
  if (w > size.width * 0.78) {
    w = size.width * 0.78;
    h = w * kPaperH / kPaperW;
  }
  final top = math.max(0.0, (size.height - h) / 2);
  return Rect.fromLTWH((size.width - w) / 2, top, w, h);
}
