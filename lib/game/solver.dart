import 'dart:ui';

import 'levels.dart';
import 'sim.dart';

class SolveResult {
  final SimState state;
  final int stars;
  final double seconds;

  /// Fraction of the hint that could actually be drawn (1 = all of it).
  final double drawn;
  final Offset blue, pink;
  const SolveResult(this.state, this.stars, this.seconds, this.drawn, this.blue, this.pink);

  bool get won => state == SimState.won;

  @override
  String toString() => '$state stars=$stars t=${seconds.toStringAsFixed(1)} '
      'drawn=${(drawn * 100).round()}% '
      'blue=(${blue.dx.toStringAsFixed(1)},${blue.dy.toStringAsFixed(1)}) '
      'pink=(${pink.dx.toStringAsFixed(1)},${pink.dy.toStringAsFixed(1)})';
}

/// Draws [stroke] (defaults to the level's hint) the way a finger would and
/// runs the physics for up to [seconds].
SolveResult playStroke(Level level, {List<Offset>? stroke, Offset shift = Offset.zero, double seconds = 12}) {
  final sim = Sim(level);
  final base = stroke ?? [...level.hint, if (level.hintClosed) level.hint.first];
  final pts = [for (final p in base) p + shift];
  var total = 0.0;
  for (var i = 1; i < pts.length; i++) {
    total += (pts[i] - pts[i - 1]).distance;
  }
  if (!sim.begin(pts.first)) {
    return SolveResult(SimState.ready, 0, 0, 0, level.blue, level.pink);
  }
  for (var i = 1; i < pts.length; i++) {
    final a = pts[i - 1], b = pts[i];
    final n = ((b - a).distance / 0.5).ceil().clamp(1, 1000);
    for (var j = 1; j <= n; j++) {
      sim.extend(Offset.lerp(a, b, j / n)!);
    }
  }
  var drawnLen = 0.0;
  for (var i = 1; i < sim.stroke.length; i++) {
    drawnLen += (sim.stroke[i] - sim.stroke[i - 1]).distance;
  }
  sim.end();
  final stars = sim.starsNow;
  var t = 0.0;
  while (t < seconds && sim.state == SimState.running) {
    sim.step(1 / 60);
    t += 1 / 60;
  }
  return SolveResult(sim.state, stars, t, total == 0 ? 1 : drawnLen / total, sim.bluePos, sim.pinkPos);
}
