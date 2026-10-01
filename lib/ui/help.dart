import 'package:flutter/material.dart';

import '../art/desk.dart';
import '../game/hud.dart';
import '../game/levels.dart';
import '../game/scene.dart';
import '../game/sim.dart';
import 'widgets.dart';

/// "Help" pages: three annotated screenshots of the game.
class HelpDialog extends StatefulWidget {
  const HelpDialog({super.key});
  @override
  State<HelpDialog> createState() => _HelpDialogState();
}

class _HelpPage {
  final Level level;
  final List<Offset> stroke;
  final bool pen;
  final bool hint;
  final double ink;
  final List<(String, Offset, double, double, bool)> callouts; // text, pos, width, arrowX, flip
  const _HelpPage(this.level, this.stroke, this.pen, this.hint, this.ink, this.callouts);
}

final _pages = [
  _HelpPage(
    Level(
      geos: [
        Geo.poly([o(0, 33), o(26, 33), o(52, 46), o(52, 51), o(100, 51), o(100, 57), o(0, 57)]),
      ],
      blue: o(20, 30.9),
      pink: o(77, 48.9),
      hint: const [],
      reward: Reward.coins,
    ),
    [o(14, 18), o(16, 14), o(17.6, 9), o(18.4, 4)],
    true,
    false,
    0.71,
    [
      ('You could get 3 stars by draw a shorter line or following the hint.', const Offset(330, 200), 300, 0.18, false),
      ('The progress bar shows the usage of the ink, the less you use, the easier you can get 3 stars.',
          const Offset(600, 110), 330, 0.25, false),
    ],
  ),
  _HelpPage(
    Level(
      geos: [
        Geo.poly([o(0, 46), o(18, 46), o(18, 50), o(24, 50), o(24, 46), o(76, 46), o(76, 50), o(82, 50), o(82, 46), o(100, 46), o(100, 57), o(0, 57)]),
      ],
      blue: o(23, 26),
      pink: o(77, 26),
      hint: [o(17.5, 45.5), o(21, 39), o(25, 45.5)],
      reward: Reward.coins,
    ),
    const [],
    true,
    true,
    1.0,
    [
      ("If you fail to complete a level or you can't get 3 stars, tap the hint button!",
          const Offset(640, 105), 330, 0.82, true),
    ],
  ),
  _HelpPage(
    Level(
      geos: [Geo.rect(0, 46, 100, 57)],
      blue: o(24, 43.9),
      pink: o(77, 43.9),
      hint: const [],
      reward: Reward.coins,
    ),
    [o(10, 43), o(20, 41.5), o(30, 40), o(22, 43), o(15, 44.6), o(28, 42.5), o(38, 44.6), o(18, 44.4)],
    false,
    false,
    0.27,
    [
      ('You can click the Retry button to redo it.', const Offset(740, 105), 330, 0.9, true),
    ],
  ),
];

class _HelpDialogState extends State<HelpDialog> {
  int page = 0;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Material(
      color: const Color(0xFFE6E6E6),
      child: SizedBox(
        width: size.width,
        height: size.height,
        child: Stack(
          children: [
            Center(
              child: Container(
                width: size.width * 0.63,
                height: size.height * 0.79,
                color: Colors.white,
                padding: EdgeInsets.all(s(16)),
                child: FittedBox(
                  child: SizedBox(
                    width: size.width,
                    height: size.height,
                    child: _HelpScene(_pages[page], size),
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: s(14),
              left: 0,
              right: 0,
              child: Center(
                child: Text('${page + 1} / ${_pages.length}',
                    style: TextStyle(fontSize: s(22), color: const Color(0xFF555555))),
              ),
            ),
            Positioned(
              left: s(40),
              top: size.height / 2 - s(30),
              child: Tap(
                onTap: () => setState(() => page = (page - 1 + _pages.length) % _pages.length),
                child: Icon(Icons.arrow_back_ios_new_rounded, size: s(50), color: const Color(0xFFA0A0A0)),
              ),
            ),
            Positioned(
              right: s(40),
              top: size.height / 2 - s(30),
              child: Tap(
                onTap: () => setState(() => page = (page + 1) % _pages.length),
                child: Icon(Icons.arrow_forward_ios_rounded, size: s(50), color: const Color(0xFFA0A0A0)),
              ),
            ),
            Positioned(
              right: s(16),
              top: s(12),
              child: Tap(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  width: s(42),
                  height: s(42),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFF333333), width: s(3)),
                  ),
                  child: Icon(Icons.close_rounded, size: s(30), color: const Color(0xFF333333)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HelpScene extends StatelessWidget {
  final _HelpPage p;
  final Size size;
  const _HelpScene(this.p, this.size);

  @override
  Widget build(BuildContext context) {
    final paper = paperRectFor(size, S.k);
    final sim = Sim(p.level);
    if (p.stroke.isNotEmpty) {
      sim.state = SimState.drawing;
      sim.stroke.addAll(p.stroke);
      if (!p.pen) sim.end();
    }
    final st = SceneState()
      ..sim = sim
      ..level = p.level
      ..bg = 'notebook'
      ..hintVisible = p.hint
      ..hintPen = p.hint ? 0.62 : -1;
    return IgnorePointer(
      child: Stack(
        children: [
          Positioned.fill(child: CustomPaint(painter: DeskPainter(paper))),
          Positioned.fill(child: CustomPaint(painter: ScenePainter(st, paper))),
          Positioned(
            left: 0,
            top: 0,
            child: Hud(
              width: size.width,
              ink: ValueNotifier(p.ink),
              sound: true,
              music: true,
              hintFree: true,
              onBack: () {},
              onSound: () {},
              onMusic: () {},
              onHint: () {},
              onRetry: () {},
            ),
          ),
          for (final c in p.callouts)
            Positioned(
              left: c.$5
                  ? size.width - (1152 - c.$2.dx) * S.k
                  : size.width / 2 + (c.$2.dx - 576) * S.k,
              top: s(c.$2.dy - 44),
              child: Callout(c.$1, width: c.$3, arrowX: c.$4, flip: c.$5),
            ),
        ],
      ),
    );
  }
}
