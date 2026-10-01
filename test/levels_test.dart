import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:love_dots/game/levels.dart';
import 'package:love_dots/game/sim.dart';
import 'package:love_dots/game/solver.dart';

void main() {
  setUpAll(() => loadGeneratedLevels(File(kGeneratedLevelsAsset).readAsStringSync()));

  test('there are 1000 levels with a rising difficulty', () {
    expect(levels.length, 1000);
    for (var i = 1; i < levels.length; i++) {
      expect(levels[i].tier.index, greaterThanOrEqualTo(levels[i - 1].tier.index),
          reason: 'level ${i + 1} is easier than level $i');
    }
  });

  test('the 20 hand-made levels are solvable by following their hint', () {
    final failures = <String>[];
    for (var i = 0; i < handLevels.length; i++) {
      final r = playStroke(levels[i]);
      // ignore: avoid_print
      print('L${i + 1}: $r');
      if (!r.won) failures.add('L${i + 1}');
    }
    expect(failures, isEmpty);
  });

  test('generated levels are solvable by following their hint (every 10th)', () {
    final failures = <String>[];
    for (var i = handLevels.length; i < levels.length; i += 10) {
      final r = playStroke(levels[i], seconds: 10);
      if (!r.won || r.stars < 3) failures.add('L${i + 1}: $r');
    }
    expect(failures, isEmpty);
  });

  test('balls stay put until a line is drawn', () {
    for (final l in levels.take(40)) {
      final sim = Sim(l);
      for (var i = 0; i < 120; i++) {
        sim.step(1 / 60);
      }
      expect((sim.bluePos - l.blue).distance, lessThan(1e-4));
      expect((sim.pinkPos - l.pink).distance, lessThan(1e-4));
    }
  });
}
