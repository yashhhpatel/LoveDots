import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:love_dots/game/levels.dart';
import 'package:love_dots/game/sim.dart';

/// Draws the level's hint as a stroke and simulates [seconds] of physics.
(SimState, int, String) playHint(Level level, {double seconds = 12}) {
  final sim = Sim(level);
  final pts = [...level.hint, if (level.hintClosed) level.hint.first];
  if (!sim.begin(pts.first)) return (SimState.ready, 0, 'hint start blocked');
  for (var i = 1; i < pts.length; i++) {
    final a = pts[i - 1], b = pts[i];
    final n = ((b - a).distance / 0.5).ceil().clamp(1, 1000);
    for (var j = 1; j <= n; j++) {
      sim.extend(Offset.lerp(a, b, j / n)!);
    }
  }
  final drawn = sim.stroke.length;
  sim.end();
  final stars = sim.starsNow;
  var t = 0.0;
  while (t < seconds && sim.state == SimState.running) {
    sim.step(1 / 60);
    t += 1 / 60;
  }
  final b = sim.bluePos, p = sim.pinkPos;
  return (
    sim.state,
    stars,
    'pts=$drawn/${pts.length} t=${t.toStringAsFixed(1)} '
        'blue=(${b.dx.toStringAsFixed(1)},${b.dy.toStringAsFixed(1)}) '
        'pink=(${p.dx.toStringAsFixed(1)},${p.dy.toStringAsFixed(1)})'
  );
}

void main() {
  test('every level is solvable by following its hint', () {
    final failures = <String>[];
    for (var i = 0; i < levels.length; i++) {
      final (state, stars, info) = playHint(levels[i]);
      // ignore: avoid_print
      print('L${i + 1}: $state stars=$stars $info');
      if (state != SimState.won) failures.add('L${i + 1}');
    }
    expect(failures, isEmpty);
  });

  test('balls stay put until a line is drawn', () {
    for (final l in levels) {
      final sim = Sim(l);
      for (var i = 0; i < 120; i++) {
        sim.step(1 / 60);
      }
      expect((sim.bluePos - l.blue).distance, lessThan(1e-4));
      expect((sim.pinkPos - l.pink).distance, lessThan(1e-4));
    }
  });
}
