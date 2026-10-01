// Generates levels 21-1000 and writes assets/levels/generated.json.
//
//   flutter test tool/gen_levels_test.dart
//
// Every level is built from one of four patterns taken from the hand-made
// levels, with difficulty rising from Easy to Very Hard. A level is only kept
// if the physics proves that:
//   * drawing its hint wins,
//   * the hint still wins when drawn a little off (a real finger is not exact),
//   * a throw-away dot does NOT win (the level can't solve itself),
//   * the win happens quickly.
// Generation is seeded, so running it again produces the same levels.
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:love_dots/game/geometry.dart';
import 'package:love_dots/game/levels.dart';
import 'package:love_dots/game/solver.dart';

const firstLevel = 21;
const lastLevel = 1000;

enum Pattern { stack, cup, bridge, hook }

Tier tierOf(int n) => n <= 200
    ? Tier.easy
    : n <= 500
        ? Tier.medium
        : n <= 800
            ? Tier.hard
            : Tier.veryHard;

/// 0 (first generated level) .. 1 (level 1000), with a 10-level rhythm:
/// a breather after each "boss" level, building up to the next one.
double difficultyOf(int n) {
  final base = math.pow((n - firstLevel) / (lastLevel - firstLevel), 0.9).toDouble();
  const wave = [-0.05, -0.03, -0.01, 0.0, 0.01, 0.0, 0.02, 0.03, 0.04, 0.07];
  return (base + wave[(n - 1) % 10]).clamp(0.0, 1.0);
}

class Candidate {
  final Pattern pattern;
  final List<Geo> geos;
  final Offset blue, pink;
  final List<Offset> hint;

  /// Regions obstacles must stay out of: rects, and paths the balls travel
  /// (each a polyline with a clearance radius).
  final List<Rect> keepOut;
  final List<(List<Offset>, double)> paths;
  Candidate(this.pattern, this.geos, this.blue, this.pink, this.hint, this.keepOut, [this.paths = const []]);
}

class Gen {
  final int n;
  final double d;
  final math.Random rnd;
  Gen(this.n, int seed)
      : d = difficultyOf(n),
        rnd = math.Random(seed);

  double lerp(double a, double b) => a + (b - a) * d;
  double range(double a, double b) => a + (b - a) * rnd.nextDouble();
  double jit(double r) => (rnd.nextDouble() * 2 - 1) * r;
  bool chance(double p) => rnd.nextDouble() < p;

  // ------------------------------------------------------------- stack
  /// Two balls fall through a gap between shelves; a catcher across the gap
  /// stops the lower one and the upper one lands on it. Later levels offset
  /// the balls (needs a V-shaped catcher) and raise lips on the shelf edges.
  Candidate? stack() {
    final gapW = lerp(13, 32) + jit(3);
    final shelfY = range(36, 46);
    final x0 = range(gapW / 2 + 12, 100 - gapW / 2 - 12);
    final gapL = x0 - gapW / 2, gapR = x0 + gapW / 2;
    final lip = n > 260 && chance(lerp(0, 0.7)) ? range(1.5, lerp(2, 4)) : 0.0;
    final needV = n > 300 && chance(lerp(0.2, 0.7));
    final bottom = Offset(x0 + jit(gapW * 0.15), shelfY - lip - range(9, 15));
    final off = needV ? (chance(.5) ? 1 : -1) * range(5, lerp(6, 11)) : jit(n < 120 ? 0.8 : 2.5);
    final top = bottom + Offset(off, -range(5.5, 9));
    if (top.dy < 5 || top.dx < gapL + 3 || top.dx > gapR - 3) return null;
    if (bottom.dx < gapL + 3 || bottom.dx > gapR - 3) return null;
    final rightDy = n > 500 && chance(lerp(0, 0.5)) ? jit(2.5) : 0.0;
    final geos = <Geo>[
      Geo.rect(chance(.5) ? 0 : 4, shelfY, gapL, shelfY + 3.2),
      Geo.rect(gapR, shelfY + rightDy, chance(.5) ? 100 : 96, shelfY + rightDy + 3.2),
      if (lip > 0) Geo.bar([Offset(gapL - 0.5, shelfY), Offset(gapL - 0.5, shelfY - lip)], 1.0),
      if (lip > 0) Geo.bar([Offset(gapR + 0.5, shelfY + rightDy), Offset(gapR + 0.5, shelfY + rightDy - lip)], 1.0),
    ];
    if (chance(.4)) {
      // rounded posts at the outer ends, like level 12
      geos.add(Geo.rect(0, shelfY - 12, 4.5, 57));
      geos.add(Geo.circle(2.25, shelfY - 12, 2.25));
    }
    final ly = shelfY - lip - 0.9, ry = shelfY + rightDy - lip - 0.9;
    final mid = (bottom.dx + top.dx) / 2;
    final depth = needV ? lerp(2, 4) : 0.0;
    final hint = needV
        ? [Offset(gapL - 1.8, ly), Offset(mid, (ly + ry) / 2 + depth), Offset(gapR + 1.8, ry)]
        : [Offset(gapL - 1.8, ly), Offset(gapR + 1.8, ry)];
    final keep = [
      Rect.fromLTRB(math.min(bottom.dx, top.dx) - 3, top.dy - 3, math.max(bottom.dx, top.dx) + 3, shelfY + 1),
      Rect.fromLTRB(gapL, shelfY - lip - 1.5, gapR, 57),
    ];
    final swap = chance(.5);
    return Candidate(Pattern.stack, geos, swap ? top : bottom, swap ? bottom : top, hint, keep);
  }

  // ------------------------------------------------------------- cup
  /// Two balls hang apart in the air. A cup drawn under both falls with them
  /// onto a floor or pedestal, and they roll together at its bottom.
  Candidate? cup() {
    final dx = lerp(9, 40) + jit(3);
    final yMid = range(13, 28);
    final dy = n < 200 ? 0.0 : jit(lerp(0, 7));
    final xL = range(10, 90 - dx), xR = xL + dx;
    final yL = yMid - dy / 2, yR = yMid + dy / 2;
    final floorY = range(48, 53);
    final armL = xL - 3.4, armR = xR + 3.4;
    final armTop = math.min(yL, yR) - 1.0;
    final yBot = math.max(yL, yR) + kBallR + 2.2;
    final vDepth = 1.0 + dx * 0.06;
    final cx = (xL + xR) / 2;
    if (yBot + vDepth + 2 > floorY || armL < 3 || armR > 97) return null;
    final geos = <Geo>[];
    if (n < 140 || chance(.25)) {
      geos.add(Geo.rect(0, floorY, 100, 57));
    } else {
      final pw = math.max(dx + 9, dx + lerp(30, 10) + jit(2));
      final pl = (cx - pw / 2 + jit(2)).clamp(0.0, 100 - pw);
      geos.add(Geo.rect(pl, floorY, pl + pw, 57));
      if (chance(.5)) {
        // low spikes on the rest of the floor
        final tip = floorY + 2.2;
        if (pl > 6) geos.add(Geo.poly([Offset(0, 57), ...spikes(0, pl, (pl / 3.2).round(), tip, 55), Offset(pl, 57)]));
        if (pl + pw < 94) {
          final x1 = pl + pw;
          geos.add(Geo.poly([Offset(x1, 57), ...spikes(x1, 100, ((100 - x1) / 3.2).round(), tip, 55), const Offset(100, 57)]));
        }
      }
    }
    final hint = [
      Offset(armL, armTop),
      Offset(armL, yBot - 1.5),
      Offset(armL + 1.5, yBot),
      Offset(cx, yBot + vDepth),
      Offset(armR - 1.5, yBot),
      Offset(armR, yBot - 1.5),
      Offset(armR, armTop),
    ];
    if (n > 240 && chance(lerp(0, 0.75))) {
      // Channel walls hugging the arms: the cup has to be drawn precisely.
      final gapSide = lerp(3.0, 1.35) + jit(0.2);
      final wallTop = armTop + range(-2, 4);
      geos.add(Geo.bar([Offset(armL - gapSide - 0.5, floorY), Offset(armL - gapSide - 0.5, wallTop)], 1.0));
      geos.add(Geo.bar([Offset(armR + gapSide + 0.5, floorY), Offset(armR + gapSide + 0.5, wallTop)], 1.0));
    }
    final keep = [
      Rect.fromLTRB(armL + 0.6, armTop - 2.5, armR - 0.6, yBot + vDepth),
      Rect.fromLTRB(armL - 0.8, yBot - 2, armR + 0.8, floorY + 0.5),
    ];
    final swap = chance(.5);
    return Candidate(Pattern.cup, geos, Offset(swap ? xR : xL, swap ? yR : yL),
        Offset(swap ? xL : xR, swap ? yL : yR), hint, keep);
  }

  // ------------------------------------------------------------- bridge
  /// One ball rolls down a slope toward a pit; a bridge over the pit lets it
  /// roll on to the other ball. Hard levels add a second pit.
  Candidate? bridge() {
    final groundY = range(40, 50);
    final topY = math.max(12.0, groundY - lerp(8, 18) + jit(2));
    final slopeEnd = range(20, 32);
    final pitL = slopeEnd + range(2, 7);
    final pitW = lerp(5, 20) + jit(1.5);
    final pitR = pitL + pitW;
    final two = n > 350 && chance(lerp(0, 0.6));
    final pillarW = range(4, 8);
    final pit2W = two ? lerp(5, 14) + jit(1.2) : 0.0;
    final endX = two ? pitR + pillarW + pit2W : pitR;
    final pinkX = endX + range(5, lerp(10, 28));
    if (pinkX > 93) return null;
    final geos = <Geo>[
      Geo.poly([Offset(0, topY), Offset(6, topY), Offset(slopeEnd, groundY), Offset(pitL, groundY), Offset(pitL, 57), Offset(0, 57)]),
      if (two) Geo.rect(pitR, groundY, pitR + pillarW, 57),
      Geo.rect(endX, groundY, 100, 57),
    ];
    final v = Offset(slopeEnd - 6, groundY - topY);
    final vn = v / v.distance;
    final up = Offset(vn.dy, -vn.dx);
    final bx = 10.0;
    final surf = Offset(bx, topY + (bx - 6) / (slopeEnd - 6) * (groundY - topY));
    final roller = surf + up * (kBallR + 0.05);
    final waiter = Offset(pinkX, groundY - kBallR);
    final hint = [Offset(pitL - 1.8, groundY - 0.8), Offset(endX + 1.8, groundY - 0.8)];
    if (n > 220 && chance(lerp(0, 0.7))) {
      // Low ceiling over the pit: little room to draw the bridge.
      final clearance = lerp(13, 6.6) + jit(0.4);
      final cy = groundY - clearance;
      geos.add(Geo.rect(pitL - range(1, 4), cy - range(2, 4), endX + range(1, 4), cy));
    }
    final keep = [Rect.fromLTRB(pitL, groundY, endX, 57)];
    final path = [roller, Offset(slopeEnd, groundY - kBallR), Offset(pinkX, groundY - kBallR)];
    var c = Candidate(Pattern.bridge, geos, roller, waiter, hint, keep, [(path, 5.2)]);
    if (chance(.5)) c = mirror(c);
    if (chance(.5)) c = Candidate(c.pattern, c.geos, c.pink, c.blue, c.hint, c.keepOut, c.paths);
    return c;
  }

  // ------------------------------------------------------------- hook
  /// A pin in the middle; a sling hung over it catches both balls, which roll
  /// together at its lowest point (like level 20).
  Candidate? hook() {
    final xc = range(32, 68), yp = range(12, 22);
    final kind = rnd.nextInt(3);
    final pr = [lerp(1.6, 1.3), 4.2, 3.7][kind];
    final a = lerp(7, 19) + jit(1.5) + pr;
    final yb = yp + range(-0.5, lerp(5, 9));
    final xL = xc - a, xR = xc + a;
    if (xL < 9 || xR > 91 || yb + 9 > 54) return null;
    final geos = <Geo>[
      if (kind == 0) Geo.circle(xc, yp, pr),
      if (kind == 1) ...[
        Geo.circle(xc, yp, 1.7),
        for (var i = 0; i < 6; i++)
          Geo.circle(xc + math.cos(i * math.pi / 3 - math.pi / 2) * 2.7,
              yp + math.sin(i * math.pi / 3 - math.pi / 2) * 2.7, 1.45),
      ],
      if (kind == 2) Geo.poly(starPts(xc, yp, 3.7, 2.0, 6)),
    ];
    final hint = [
      Offset(xL + 5.6, yb - 4.8),
      Offset(xL - 2.4, yb - 3.8),
      Offset(xL - 4.4, yb + 1.2),
      Offset(xL + 0.6, yb + 5.7),
      Offset(xc, yb + 7.0),
      Offset(xR - 0.6, yb + 5.7),
      Offset(xR + 3.4, yb + 0.2),
      Offset(xR + 0.4, yb - 4.8),
      Offset(xc + pr + 5.6, yp - pr - 2.7),
      Offset(xc, yp - pr - 2.6),
      Offset(xc - pr - 1.4, yp - pr - 0.7),
      Offset(xc - pr - 2.0, yp - 0.8),
    ];
    final keep = [Rect.fromLTRB(xL - 3, yp - pr - 1.5, xR + 3, yb + 6.5)];
    final swap = chance(.5);
    return Candidate(Pattern.hook, geos, Offset(swap ? xR : xL, yb), Offset(swap ? xL : xR, yb), hint, keep);
  }

  // ------------------------------------------------------------- obstacles

  /// Obstacles. "Tight" ones sit right next to the hint so a sloppy line
  /// hits them; their gap shrinks with difficulty. "Loose" ones are scenery.
  List<Geo> obstacles(Candidate c) {
    final out = <Geo>[];
    final tight = (lerp(-0.3, 3.6) + rnd.nextDouble()).floor();
    final gap = lerp(3.2, 1.3);
    final cx = c.hint.map((p) => p.dx).reduce((a, b) => a + b) / c.hint.length;
    final cy = c.hint.map((p) => p.dy).reduce((a, b) => a + b) / c.hint.length;
    var tries = 0;
    while (out.length < tight && tries++ < 120) {
      final i = 1 + rnd.nextInt(c.hint.length - 1);
      final a = c.hint[i - 1], b = c.hint[i];
      final seg = b - a;
      if (seg.distance < 1) continue;
      final p = Offset.lerp(a, b, range(0.15, 0.85))!;
      var nrm = Offset(-seg.dy, seg.dx) / seg.distance;
      // Put it on the outside of the shape (or above a straight line).
      final outward = c.hint.length > 3 ? (p - Offset(cx, cy)) : const Offset(0, -1);
      if (nrm.dx * outward.dx + nrm.dy * outward.dy < 0) nrm = -nrm;
      final size = range(1.0, 2.4);
      final ctr = p + nrm * (gap + 0.42 + size);
      final g = rnd.nextBool()
          ? Geo.circle(ctr.dx, ctr.dy, size)
          : Geo.poly(starPts(ctr.dx, ctr.dy, size * 1.25, size * 0.6, 5));
      if (!_clear(g, [...c.geos, ...out], c, gap)) continue;
      out.add(g);
    }
    final loose = (lerp(0.3, 1.8) + rnd.nextDouble()).floor();
    tries = 0;
    var placed = 0;
    while (placed < loose && tries++ < 80) {
      final x = range(6, 94), y = range(4, 48);
      final g = switch (rnd.nextInt(5)) {
        0 => Geo.circle(x, y, range(1.2, 3)),
        1 => () {
            final ang = range(0, math.pi), len = range(6, 14);
            final dd = Offset(math.cos(ang), math.sin(ang)) * (len / 2);
            return Geo.bar([Offset(x, y) - dd, Offset(x, y) + dd], 1.0);
          }(),
        2 => Geo.rect(x - range(1.5, 4), y - range(1.5, 3), x + range(1.5, 4), y + range(1.5, 3)),
        3 => Geo.poly(starPts(x, y, range(2, 3.4), 1.3, 5 + rnd.nextInt(2))),
        _ => Geo.poly(heartPts(x, y, range(3.5, 5.5))),
      };
      if (!_clear(g, [...c.geos, ...out], c, 4)) continue;
      out.add(g);
      placed++;
    }
    return out;
  }

  bool _clear(Geo g, List<Geo> allGeo, Candidate c, double margin) {
    final pts = _samplePts(g);
    for (final p in pts) {
      for (final r in c.keepOut) {
        if (r.contains(p)) return false;
      }
      for (final (path, rad) in c.paths) {
        for (var i = 1; i < path.length; i++) {
          if (distToSeg(p, path[i - 1], path[i]) < rad) return false;
        }
      }
      for (var i = 1; i < c.hint.length; i++) {
        if (distToSeg(p, c.hint[i - 1], c.hint[i]) < margin + 0.42 - 0.05) return false;
      }
      if ((p - c.blue).distance < 5 || (p - c.pink).distance < 5) return false;
      for (final other in allGeo) {
        if (geoHits(other, p, 1.0)) return false;
      }
      if (p.dx < 1 || p.dx > 99 || p.dy < 1 || p.dy > 56) return false;
    }
    return true;
  }

  List<Offset> _samplePts(Geo g) => switch (g.kind) {
        GeoKind.circle => [
            g.c,
            for (var i = 0; i < 8; i++) g.c + Offset(math.cos(i * math.pi / 4), math.sin(i * math.pi / 4)) * g.r
          ],
        GeoKind.bar => [
            for (var i = 0; i <= 8; i++) Offset.lerp(g.pts.first, g.pts.last, i / 8)!,
          ],
        GeoKind.poly => g.pts,
      };
}

List<Offset> spikes(double x0, double x1, int count, double tip, double base) {
  final pts = <Offset>[];
  final w = (x1 - x0) / math.max(1, count);
  for (var i = 0; i < count; i++) {
    pts.add(Offset(x0 + i * w, base));
    pts.add(Offset(x0 + i * w + w / 2, tip));
  }
  pts.add(Offset(x1, base));
  return pts;
}

Candidate mirror(Candidate c) {
  Offset m(Offset p) => Offset(100 - p.dx, p.dy);
  Geo mg(Geo g) => switch (g.kind) {
        GeoKind.poly => Geo.poly(g.pts.reversed.map(m).toList(), solid: g.solid, white: g.white),
        GeoKind.bar => Geo.bar(g.pts.map(m).toList(), g.w, closed: g.closed),
        GeoKind.circle => Geo.circle(100 - g.c.dx, g.c.dy, g.r),
      };
  return Candidate(c.pattern, c.geos.map(mg).toList(), m(c.blue), m(c.pink), c.hint.map(m).toList(),
      c.keepOut.map((r) => Rect.fromLTRB(100 - r.right, r.top, 100 - r.left, r.bottom)).toList(),
      [for (final (pts, r) in c.paths) (pts.map(m).toList(), r)]);
}

const rewardCycle = [
  Reward.wheel, Reward.draw, Reward.coins, Reward.chest, Reward.skin,
  Reward.wheel, Reward.coins, Reward.draw, Reward.chest, Reward.skin,
];
const skinCycle = [
  'ball:witch', 'pen:heart', 'ball:ninja', 'pen:bear', 'ball:ladybug', 'pen:reindeer',
  'ball:cat', 'pen:snowman', 'ball:glasses', 'pen:candy', 'ball:bunny', 'pen:rose',
  'ball:crown', 'ball:devil',
];

Pattern pickPattern(int n, math.Random rnd, List<Pattern> recent) {
  // New patterns are introduced with a few easy examples in a row.
  if (n >= 41 && n <= 43) return Pattern.bridge;
  if (n >= 121 && n <= 123) return Pattern.hook;
  final avail = [
    Pattern.stack,
    Pattern.cup,
    if (n >= 41) Pattern.bridge,
    if (n >= 121) Pattern.hook,
  ];
  for (var i = 0; i < 20; i++) {
    final p = avail[rnd.nextInt(avail.length)];
    final last2 = recent.length >= 2 && recent[recent.length - 1] == p && recent[recent.length - 2] == p;
    if (!last2) return p;
  }
  return avail.first;
}

/// Free spot for the "does a random dot solve it?" check.
Offset? freeSpot(Level l) {
  for (final p in const [Offset(5, 5), Offset(95, 5), Offset(50, 3.5), Offset(5, 30), Offset(95, 30)]) {
    var ok = (p - l.blue).distance > 8 && (p - l.pink).distance > 8;
    for (final g in l.geos) {
      if (geoHits(g, p, 1.5)) ok = false;
    }
    if (ok) return p;
  }
  return null;
}

String? validate(Level l) {
  final r = playStroke(l, seconds: 10);
  if (!r.won) return 'hint does not win (${r.state})';
  if (r.drawn < 0.97) return 'hint blocked (${(r.drawn * 100).round()}%)';
  if (r.seconds > 8) return 'too slow (${r.seconds.toStringAsFixed(1)}s)';
  if (r.stars < 3) return 'hint is not a 3-star solution';
  var robust = 0;
  for (final s in const [Offset(0.5, 0), Offset(-0.5, 0), Offset(0, 0.5), Offset(0, -0.5)]) {
    if (playStroke(l, shift: s, seconds: 10).won) robust++;
  }
  if (robust < 3) return 'fragile ($robust/4 shifted hints win)';
  final spot = freeSpot(l);
  if (spot == null) return 'no free spot for the dot check';
  if (playStroke(l, stroke: [spot, spot + const Offset(0.8, 0)], seconds: 10).won) {
    return 'solves itself';
  }
  return null;
}

void main() {
  test('generate levels', () {
    final out = <Map<String, Object>>[];
    final recent = <Pattern>[];
    final stats = <String, int>{};
    final rejects = <String, int>{};
    final sw = Stopwatch()..start();
    // GEN_STEP=k samples every k-th level and writes nothing (for tuning).
    final step = int.tryParse(Platform.environment['GEN_STEP'] ?? '') ?? 1;
    for (var n = firstLevel; n <= lastLevel; n += step) {
      final pr = math.Random(n * 7919);
      Level? made;
      Pattern? used;
      for (var attempt = 0; attempt < 60 && made == null; attempt++) {
        final pattern = attempt < 40 ? pickPattern(n, pr, recent) : Pattern.cup;
        final g = Gen(n, n * 100003 + attempt);
        final c = switch (pattern) {
          Pattern.stack => g.stack(),
          Pattern.cup => g.cup(),
          Pattern.bridge => g.bridge(),
          Pattern.hook => g.hook(),
        };
        if (c == null) {
          rejects['layout'] = (rejects['layout'] ?? 0) + 1;
          continue;
        }
        final extra = attempt < 30 ? g.obstacles(c) : const <Geo>[];
        final idx = (n - 1) % rewardCycle.length;
        final level = Level(
          geos: [...c.geos, ...extra],
          blue: c.blue,
          pink: c.pink,
          hint: c.hint,
          reward: rewardCycle[idx],
          skinReward: rewardCycle[idx] == Reward.skin ? skinCycle[(n ~/ 10) % skinCycle.length] : null,
          inkFactor: g.lerp(4.4, 3.9),
          tier: tierOf(n),
        );
        final why = validate(level);
        if (why == null) {
          made = level;
          used = pattern;
        } else {
          final key = '${pattern.name}: ${why.split(' (').first}';
          rejects[key] = (rejects[key] ?? 0) + 1;
        }
      }
      if (made == null) fail('could not generate level $n');
      recent.add(used!);
      final key = '${tierOf(n).name}/${used.name}';
      stats[key] = (stats[key] ?? 0) + 1;
      out.add(made.toJson());
      if (step != 1 || n % 50 == 0) {
        // ignore: avoid_print
        print('level $n ${used.name} d=${difficultyOf(n).toStringAsFixed(2)} (${sw.elapsed.inSeconds}s)');
      }
    }
    // ignore: avoid_print
    print('patterns: $stats');
    // ignore: avoid_print
    print('rejected candidates: $rejects');
    if (step != 1) {
      File('build/gen_sample.json')
        ..createSync(recursive: true)
        ..writeAsStringSync(jsonEncode(out));
      return;
    }
    final file = File('assets/levels/generated.json')..createSync(recursive: true);
    file.writeAsStringSync(jsonEncode(out));
    // ignore: avoid_print
    print('wrote ${out.length} levels, ${file.lengthSync() ~/ 1024} KB, in ${sw.elapsed.inSeconds}s');
    // ignore: avoid_print
    print('patterns: $stats');
    // ignore: avoid_print
    print('rejected candidates: $rejects');
  }, timeout: const Timeout(Duration(hours: 2)));
}
