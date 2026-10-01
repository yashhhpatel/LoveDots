import 'dart:math' as math;
import 'dart:ui';

/// Paper coordinate space: x 0..100, y 0..57 (y down).
const double kPaperW = 100;
const double kPaperH = 57;
const double kBallR = 2.0;

enum GeoKind { poly, bar, circle }

/// A piece of level geometry. Solid pieces collide; decorations only draw.
class Geo {
  final GeoKind kind;
  final List<Offset> pts;
  final double w; // bar thickness
  final bool closed;
  final Offset c;
  final double r;
  final bool solid;
  final bool white;

  const Geo._(this.kind,
      {this.pts = const [],
      this.w = 1,
      this.closed = false,
      this.c = Offset.zero,
      this.r = 0,
      this.solid = true,
      this.white = false});

  factory Geo.poly(List<Offset> pts, {bool solid = true, bool white = false}) =>
      Geo._(GeoKind.poly, pts: pts, solid: solid, white: white);
  factory Geo.rect(double x1, double y1, double x2, double y2) => Geo.poly(
      [Offset(x1, y1), Offset(x2, y1), Offset(x2, y2), Offset(x1, y2)]);
  factory Geo.bar(List<Offset> pts, double w, {bool closed = false}) =>
      Geo._(GeoKind.bar, pts: pts, w: w, closed: closed);
  factory Geo.circle(double x, double y, double r) =>
      Geo._(GeoKind.circle, c: Offset(x, y), r: r);
}

enum Reward { wheel, draw, chest, coins, skin }

class Level {
  final List<Geo> geos;
  final Offset blue;
  final Offset pink;
  final List<Offset> hint;
  final bool hintClosed;
  final Reward reward;
  final String? skinReward; // 'ball:<id>' or 'pen:<id>'
  final String? text;
  final Offset textPos;

  const Level({
    required this.geos,
    required this.blue,
    required this.pink,
    required this.hint,
    this.hintClosed = false,
    required this.reward,
    this.skinReward,
    this.text,
    this.textPos = Offset.zero,
  });

  double get hintLength {
    var l = 0.0;
    for (var i = 1; i < hint.length; i++) {
      l += (hint[i] - hint[i - 1]).distance;
    }
    if (hintClosed && hint.length > 2) l += (hint.first - hint.last).distance;
    return l;
  }

  /// Ink capacity: following the hint leaves enough ink for three stars.
  double get ink => math.max(60, hintLength * 4.0);
}

Offset o(double x, double y) => Offset(x, y);

List<Offset> heartPts(double cx, double cy, double size) {
  final pts = <Offset>[];
  for (var i = 0; i < 48; i++) {
    final t = i / 48 * 2 * math.pi;
    final x = 16 * math.pow(math.sin(t), 3);
    final y = 13 * math.cos(t) -
        5 * math.cos(2 * t) -
        2 * math.cos(3 * t) -
        math.cos(4 * t);
    pts.add(Offset(cx + x / 34 * size, cy - y / 34 * size));
  }
  return pts;
}

List<Offset> starPts(double cx, double cy, double r, double ri, int n) {
  final pts = <Offset>[];
  for (var i = 0; i < n * 2; i++) {
    final a = -math.pi / 2 + i * math.pi / n;
    final rr = i.isEven ? r : ri;
    pts.add(Offset(cx + math.cos(a) * rr, cy + math.sin(a) * rr));
  }
  return pts;
}

List<Offset> quad(Offset a, Offset c, Offset b, [int n = 12]) {
  return [
    for (var i = 0; i <= n; i++)
      () {
        final t = i / n;
        final u = 1 - t;
        return a * (u * u) + c * (2 * u * t) + b * (t * t);
      }()
  ];
}

List<Offset> ellipse(double cx, double cy, double rx, double ry,
    double a0, double a1, int n) {
  return [
    for (var i = 0; i <= n; i++)
      Offset(cx + math.cos(a0 + (a1 - a0) * i / n) * rx,
          cy + math.sin(a0 + (a1 - a0) * i / n) * ry)
  ];
}

List<Geo> _walls(double l, double r) =>
    [Geo.rect(0, 0, l, kPaperH), Geo.rect(r, 0, kPaperW, kPaperH)];

List<Offset> _spikes(double x0, double x1, int n, double tip, double base) {
  final pts = <Offset>[];
  final w = (x1 - x0) / n;
  for (var i = 0; i < n; i++) {
    pts.add(Offset(x0 + i * w, base));
    pts.add(Offset(x0 + i * w + w / 2, tip));
  }
  pts.add(Offset(x1, base));
  return pts;
}

List<Offset> _waves() {
  const humps = [
    [0.0, 17.0, 40.5],
    [17.0, 31.0, 45.2],
    [31.0, 45.0, 45.0],
    [45.0, 59.0, 45.8],
    [59.0, 73.0, 43.8],
    [73.0, 87.0, 44.8],
    [87.0, 100.0, 45.8],
  ];
  const valley = 48.5;
  final pts = <Offset>[const Offset(0, kPaperH)];
  for (final h in humps) {
    final c = (h[0] + h[1]) / 2, hw = (h[1] - h[0]) / 2;
    for (var i = 0; i <= 10; i++) {
      final x = h[0] + (h[1] - h[0]) * i / 10;
      final k = 1 - math.pow((x - c) / hw, 2);
      final y = valley - (valley - h[2]) * math.pow(math.max(0, k), 0.55);
      if (h[0] == 0 && i < 5) {
        pts.add(Offset(x, math.min(y, h[2] + (5 - i) * 0.3)));
      } else {
        pts.add(Offset(x, y));
      }
    }
  }
  pts.add(const Offset(kPaperW, kPaperH));
  return pts;
}

List<Offset> _mirror(List<Offset> p) =>
    p.map((e) => Offset(kPaperW - e.dx, e.dy)).toList();

final List<Level> levels = [
  // 1 — tutorial: platform over a bowl
  Level(
    geos: [
      ..._walls(5.3, 93.8),
      Geo.poly([o(5.3, 40.2), o(49.5, 47.3), o(93.8, 40.2), o(93.8, 57), o(5.3, 57)]),
      Geo.bar([o(31.6, 25.35), o(67.8, 25.35)], 3.1),
    ],
    blue: o(36.8, 21.8),
    pink: o(62.3, 21.8),
    hint: [o(32, 12), o(35, 12), o(35.2, 14)],
    reward: Reward.wheel,
    text: 'Draw one line\nand bump the\nballs!',
    textPos: o(42.7, 8.6),
  ),
  // 2 — diamond around the balls, hanging from a pin
  Level(
    geos: [
      ..._walls(4.1, 95.7),
      Geo.poly([
        o(4.1, 57),
        ..._spikes(4.1, 35.6, 13, 44.8, 48.3),
        o(50.2, 42.5),
        ..._spikes(64.4, 95.7, 13, 44.8, 48.3),
        o(95.7, 57),
      ]),
      Geo.circle(50.2, 12.6, 1.5),
    ],
    blue: o(44.3, 21.9),
    pink: o(56.1, 21.9),
    hint: [o(50.2, 9.6), o(62.6, 22.9), o(50.2, 33.2), o(37.9, 22.9)],
    hintClosed: true,
    reward: Reward.skin,
    skinReward: 'pen:rose',
  ),
  // 3 — rope-like slope with a heart on the right wall
  Level(
    geos: [
      ..._walls(5.9, 92.8),
      Geo.bar([
        o(5.9, 24.1), o(10, 27.4), o(15, 30.4), o(20, 33), o(25, 35),
        o(30, 36.6), o(35, 37.5), o(41.8, 37.7), o(45, 40), o(50, 42.5),
        o(55, 44.5), o(60, 46), o(65, 47.3), o(70, 48.2), o(75, 48.8),
        o(80, 49), o(85, 48.8), o(90, 47.6), o(92.8, 46.6),
      ], 1.3),
      Geo.poly(heartPts(90.4, 43.2, 4.6)),
    ],
    blue: o(38.6, 35.0),
    pink: o(77.7, 46.3),
    hint: [o(32.6, 31.6), o(35.2, 33.0)],
    reward: Reward.draw,
  ),
  // 4 — two balls in the air over a bump
  Level(
    geos: [
      ..._walls(2, 98),
      Geo.rect(0, 48.9, 100, 57),
      Geo.rect(34.7, 44.3, 63.6, 49),
    ],
    blue: o(34.0, 20.0),
    pink: o(64.1, 19.6),
    hint: [o(20, 10), o(46, 41.5), o(54, 41.5), o(80, 10)],
    reward: Reward.wheel,
  ),
  // 5 — slope with a zig-zag rail
  Level(
    geos: [
      Geo.rect(0, 48.5, 51.8, 57),
      Geo.poly([o(51.7, 57), o(51.7, 41.6), o(85.1, 3.1), o(100, 3.1), o(100, 57)]),
      Geo.bar([o(60.4, 0), o(60.4, 6.8), o(70.9, 17.3), o(54.4, 36.3), o(46.2, 36.3)], 1.0),
    ],
    blue: o(26.1, 46.5),
    pink: o(52.6, 39.0),
    hint: [o(48, 31), o(50, 34)],
    reward: Reward.chest,
  ),
  // 6 — tube drop onto a diagonal ramp
  Level(
    geos: [
      Geo.rect(0, 0, 4.2, 57),
      Geo.bar([o(4.2, 4.3), o(26.6, 4.3)], 1.2),
      Geo.bar([o(19.6, 4.3), o(19.6, 22.3)], 1.0),
      Geo.bar([o(26.1, 4.3), o(26.1, 22.3)], 1.0),
      Geo.poly([o(4.2, 25.4), o(54.2, 52), o(44.9, 52), o(4.2, 30.9)]),
      Geo.rect(0, 52, 100, 57),
    ],
    blue: o(22.85, 7.0),
    pink: o(25.8, 34.6),
    hint: [o(46, 44.5), o(58, 49.4), o(72, 49.4), o(73.5, 46)],
    reward: Reward.skin,
    skinReward: 'ball:witch',
  ),
  // 7 — row of dots
  Level(
    geos: [
      Geo.rect(0, 52.2, 100, 57),
      Geo.circle(3.3, 41.1, 3.3),
      Geo.circle(50.1, 41.1, 3.3),
      Geo.circle(96.7, 41.1, 3.3),
      for (final x in [14.6, 25.9, 37.3, 62.3, 73.5, 85.1]) Geo.circle(x, 41.1, 1.5),
    ],
    blue: o(25.5, 21.9),
    pink: o(73.8, 21.9),
    hint: [o(15, 13), o(17.5, 30), o(24, 35.6), o(50, 36.2), o(76, 35.6), o(82.5, 30), o(85, 13)],
    reward: Reward.coins,
  ),
  // 8 — tunnels
  Level(
    geos: [
      Geo.poly([o(0, 23.8), o(20.2, 23.8), o(20.2, 27.5), o(24.5, 40.6), o(0, 40.6)]),
      Geo.poly([o(24.8, 23.8), o(73.8, 23.8), o(73.8, 27.5), o(69.7, 40.6), o(28.8, 40.6), o(24.8, 27.5)]),
      Geo.poly([o(78.3, 23.8), o(100, 23.8), o(100, 40.6), o(74.6, 40.6), o(78.3, 27.5)]),
      Geo.rect(0, 44.8, 100, 57),
      Geo.rect(0, 40.5, 2, 44.9),
      Geo.rect(97.8, 40.5, 100, 44.9),
    ],
    blue: o(28.6, 42.8),
    pink: o(70.3, 42.8),
    hint: [o(21.4, 14), o(23.6, 14), o(23.6, 16)],
    reward: Reward.skin,
    skinReward: 'ball:ninja',
  ),
  // 9 — hang a loop on the star
  Level(
    geos: [
      ..._walls(5, 94.4),
      Geo.bar([o(5, 27.2), o(12, 29.5), o(20, 33), o(28, 37.2), o(35, 41.6), o(40, 45.4), o(43.7, 48.3), o(43.7, 58)], 1.0),
      Geo.bar(_mirror([o(5, 27.2), o(12, 29.5), o(20, 33), o(28, 37.2), o(35, 41.6), o(40, 45.4), o(43.7, 48.3), o(43.7, 58)]), 1.0),
      Geo.poly(starPts(50.1, 16.7, 3.7, 2.0, 6)),
    ],
    blue: o(50.1, 32.8),
    pink: o(50.1, 23.8),
    hint: [o(53, 13.6), o(50.1, 12.1), o(46.6, 14), o(45, 22), o(45.6, 32), o(50.1, 36.8), o(54.6, 32), o(55.2, 22), o(54.2, 15.6)],
    reward: Reward.draw,
  ),
  // 10 — funnel
  Level(
    geos: [
      Geo.rect(0, 52.6, 100, 57),
      Geo.bar([o(20.5, 52.6), o(20.5, 22.3), o(42.8, 43.9), o(42.8, 52.6)], 0.9),
      Geo.bar([o(78.7, 52.6), o(78.7, 22.3), o(56.4, 43.9), o(56.4, 52.6)], 0.9),
      Geo.bar([o(45.5, 22.3), o(55.4, 22.3)], 1.0),
    ],
    blue: o(49.6, 50.1),
    pink: o(50.2, 19.8),
    hint: [o(46, 10), o(49.6, 13.5)],
    reward: Reward.wheel,
  ),
  // 11 — staircase of circles
  Level(
    geos: [
      ..._walls(2, 97.8),
      Geo.rect(0, 48.5, 100, 57),
      Geo.bar([o(2, 25.3), o(47.4, 40.9), o(47.4, 43.6), o(54.8, 43.6), o(54.8, 46.0), o(64.1, 46.0), o(64.1, 48.5)], 0.8),
      Geo.circle(10.8, 48.5 - 8.6, 8.6),
      Geo.circle(25.1, 48.5 - 5.7, 5.7),
      Geo.circle(34.4, 48.5 - 3.8, 3.8),
      Geo.circle(42.1, 48.5 - 3.3, 3.3),
      Geo.circle(47.4, 48.5 - 2.2, 2.2),
      Geo.circle(52.0, 48.5 - 2.2, 2.2),
      for (var x = 55.8; x < 63.8; x += 1.2) Geo.circle(x, 47.9, 0.55),
      Geo.bar([o(37.3, 26.6), o(97.8, 26.6)], 0.8),
    ],
    blue: o(50.5, 24.2),
    pink: o(69.7, 46.5),
    hint: [o(51.8, 6), o(56, 6)],
    reward: Reward.chest,
  ),
  // 12 — bridge the gap
  Level(
    geos: [
      Geo.rect(0, 26.8, 7.8, 57),
      Geo.circle(3.9, 26.8, 3.9),
      Geo.rect(93.6, 27.3, 100, 57),
      Geo.circle(96.8, 27.3, 3.2),
      Geo.rect(7.6, 39.6, 41.2, 42.7),
      Geo.rect(58.5, 39.6, 93.8, 42.7),
    ],
    blue: o(50.1, 32.9),
    pink: o(50.1, 18.6),
    hint: [o(30, 38.6), o(50, 38.9), o(70, 38.6)],
    reward: Reward.draw,
  ),
  // 13 — hook the hearts
  Level(
    geos: [
      Geo.poly(heartPts(37.9, 20.7, 6.2)),
      Geo.poly(heartPts(60.8, 20.4, 6.2)),
    ],
    blue: o(43.4, 29.1),
    pink: o(53.8, 29.1),
    hint: [o(39, 15.4), o(33, 16.8), o(30.8, 25), o(33, 33), o(48.5, 34.6), o(64, 33), o(67, 25), o(65.5, 16.8), o(60, 15.1)],
    reward: Reward.skin,
    skinReward: 'ball:ladybug',
  ),
  // 14 — blocks and the heart box
  Level(
    geos: [
      Geo.poly([o(0, 25.7), o(12.7, 25.7), o(30.7, 32.2), o(30.7, 57), o(0, 57)]),
      Geo.rect(46.5, 44.6, 55.7, 54.2),
      Geo.poly(heartPts(51.1, 49.6, 6.4), solid: false, white: true),
      Geo.rect(72.5, 47.0, 100, 57),
    ],
    blue: o(21.0, 19.3),
    pink: o(85.8, 45.0),
    hint: [o(31.4, 31.4), o(41, 41.8), o(51.1, 43.6), o(61, 43.4), o(72.4, 46.2)],
    reward: Reward.wheel,
  ),
  // 15 — Christmas tree and bench
  Level(
    geos: [
      Geo.rect(0, 0, 100, 3),
      Geo.bar([o(31, 13.6), o(45.3, 32.2), o(16.1, 32.2)], 1.5, closed: true),
      Geo.bar([o(31, 27.2), o(52.5, 48.8), o(7.4, 48.8)], 1.5, closed: true),
      Geo.rect(26.0, 43.3, 34.7, 53.2),
      Geo.rect(0, 53.0, 100, 57),
      Geo.bar([o(59.2, 53), o(59.2, 48.3), o(84.5, 48.3), o(84.5, 53)], 1.0),
      Geo.bar([o(84.5, 48.3), o(84.5, 38.4)], 1.0),
      Geo.circle(84.5, 38.4, 1.7),
    ],
    blue: o(72.2, 45.7),
    pink: o(40.6, 21.5),
    hint: [o(52.4, 46.6), o(56, 46.6), o(61, 46.8)],
    reward: Reward.chest,
  ),
  // 16 — waves and a ball
  Level(
    geos: [
      Geo.poly(_waves()),
      Geo.circle(69.7, 29.3, 4.0),
    ],
    blue: o(31.6, 25.4),
    pink: o(70.0, 14.9),
    hint: [o(26, 26), o(29, 40.5), o(55, 41.2), o(77, 39.5), o(80, 24)],
    reward: Reward.coins,
  ),
  // 17 — two hills
  Level(
    geos: [
      Geo.poly([
        o(22.5, 57), o(22.5, 40), o(23.5, 33), o(26.5, 30.2), o(30.2, 29.5),
        o(35, 30.5), o(40, 33.5), o(44, 35.7), o(48.3, 36.1), o(53, 35),
        o(58, 31), o(62, 26.5), o(66, 24.2), o(69.8, 23.8), o(74, 24.5),
        o(78.5, 26.5), o(82, 29.5), o(83.4, 33), o(83.7, 40), o(83.7, 57),
      ]),
    ],
    blue: o(31.2, 21.8),
    pink: o(69.1, 16.2),
    hint: [o(24.5, 22.6), o(29.6, 26.2)],
    reward: Reward.chest,
  ),
  // 18 — hammock between frames
  Level(
    geos: [
      Geo.bar([o(45.9, 7.9), o(54.7, 7.9), o(54.7, 16.5), o(45.9, 16.5)], 0.8, closed: true),
      Geo.bar([o(20.3, 37.9), o(29.2, 37.9), o(29.2, 46.8), o(20.3, 46.8)], 0.8, closed: true),
      Geo.bar([o(71.7, 37.9), o(80.4, 37.9), o(80.4, 46.8), o(71.7, 46.8)], 0.8, closed: true),
      Geo.circle(50.2, 10.6, 1.3),
      Geo.circle(23.1, 43.7, 1.3),
      Geo.circle(77.5, 43.7, 1.3),
    ],
    blue: o(50.2, 20.2),
    pink: o(50.2, 32.1),
    hint: [o(21, 36.2), o(29.6, 36.2), o(40, 42.5), o(50.2, 44.8), o(60.4, 42.5), o(71.2, 36.2), o(79.8, 36.2)],
    reward: Reward.coins,
  ),
  // 19 — shelf and ramps
  Level(
    geos: [
      Geo.poly([o(0, 21.8), o(14.9, 28.8), o(14.9, 50.4), o(0, 50.4)]),
      Geo.poly([o(14.9, 28.8), o(44.6, 42.8), o(44.6, 50.4), o(42.4, 50.4), o(42.4, 45.6), o(14.9, 32.4)]),
      Geo.rect(0, 50.2, 100, 57),
      Geo.bar([o(42.8, 29.2), o(100, 29.2)], 0.9),
      Geo.bar([o(81.7, 29.2), o(81.7, 20.5), o(100, 12.6)], 1.2),
    ],
    blue: o(68.8, 11.1),
    pink: o(73.8, 48.1),
    hint: [o(70.4, 8.5), o(78, 2)],
    reward: Reward.coins,
  ),
  // 20 — flower hook
  Level(
    geos: [
      Geo.circle(50.2, 24.3, 1.7),
      for (var i = 0; i < 6; i++)
        Geo.circle(50.2 + math.cos(i * math.pi / 3 - math.pi / 2) * 2.7,
            24.3 + math.sin(i * math.pi / 3 - math.pi / 2) * 2.7, 1.45),
    ],
    blue: o(30.4, 23.8),
    pink: o(68.6, 23.8),
    hint: [o(36, 19), o(28, 20), o(26, 25), o(31, 29.5), o(50, 30.8), o(68, 29.5), o(72, 24), o(69, 19), o(60, 17.4), o(50, 17.5), o(44.6, 19.4), o(44, 23.5)],
    reward: Reward.skin,
    skinReward: 'ball:cat',
  ),
];

/// Reward that the result screen headline uses for daily challenge.
const int kDailyChallengeLevel = 15;
