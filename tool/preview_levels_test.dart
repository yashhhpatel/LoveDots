// Renders levels and their hints to a PNG contact sheet for review.
//   PREVIEW_IN=build/gen_sample.json PREVIEW_OUT=build/preview.png flutter test tool/preview_levels_test.dart
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:love_dots/game/geometry.dart';
import 'package:love_dots/game/levels.dart';

void main() {
  testWidgets('preview', (tester) async {
    final input = Platform.environment['PREVIEW_IN'] ?? 'build/gen_sample.json';
    final output = Platform.environment['PREVIEW_OUT'] ?? 'build/preview.png';
    final first = int.tryParse(Platform.environment['PREVIEW_FIRST'] ?? '') ?? 21;
    final step = int.tryParse(Platform.environment['PREVIEW_STEP'] ?? '') ?? 1;
    final list = [
      for (final j in jsonDecode(File(input).readAsStringSync()) as List) Level.fromJson(j as Map<String, dynamic>)
    ];
    const w = 400.0, h = 228.0, cols = 4;
    final rows = (list.length / cols).ceil();
    await tester.runAsync(() async {
      final rec = ui.PictureRecorder();
      final c = Canvas(rec);
      c.drawRect(Rect.fromLTWH(0, 0, cols * w, rows * h), Paint()..color = Colors.black);
      for (var i = 0; i < list.length; i++) {
        final l = list[i];
        c.save();
        c.translate((i % cols) * w, (i ~/ cols) * h);
        c.clipRect(const Rect.fromLTWH(2, 2, w - 4, h - 4));
        c.translate(2, 2);
        LevelPreviewPainter(l).paint(c, const Size(w - 4, h - 4));
        final k = (w - 4) / kPaperW;
        c.scale(k);
        paintDashed(c, [...l.hint, if (l.hintClosed) l.hint.first], false, 0.4,
            color: const Color(0xFFE53935), dash: 1.2, gap: 0.6);
        final tp = TextPainter(
          text: TextSpan(
              text: '${first + i * step} ${l.tier.name}',
              style: const TextStyle(fontSize: 2.6, color: Colors.black)),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(c, const Offset(1, 0.5));
        c.restore();
      }
      final img = await rec.endRecording().toImage((cols * w).toInt(), (rows * h).toInt());
      final png = await img.toByteData(format: ui.ImageByteFormat.png);
      File(output).writeAsBytesSync(png!.buffer.asUint8List());
    });
  });
}
