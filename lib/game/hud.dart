import 'package:flutter/material.dart';

import '../art/palette.dart';
import '../ui/widgets.dart';

/// Top bar shown during play: back, sound, music, ink meter, hint, retry.
class Hud extends StatelessWidget {
  final double width;
  final ValueNotifier<double> ink;
  final bool sound;
  final bool music;
  final bool hintFree;
  final VoidCallback onBack, onSound, onMusic, onHint, onRetry;

  const Hud({
    super.key,
    required this.width,
    required this.ink,
    required this.sound,
    required this.music,
    required this.hintFree,
    required this.onBack,
    required this.onSound,
    required this.onMusic,
    required this.onHint,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final cx = width / 2;
    return SizedBox(
      width: width,
      height: s(56),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [C.hudStrip, C.hudStrip.withOpacity(0.0)],
                  stops: const [0.75, 1],
                ),
              ),
            ),
          ),
          Positioned(left: s(19), top: s(8), child: RoundBtn(Icons.chevron_left_rounded, size: 38, onTap: onBack)),
          Positioned(
              left: s(76),
              top: s(8),
              child: RoundBtn(sound ? Icons.volume_up_rounded : Icons.volume_off_rounded,
                  size: 38, filled: sound, onTap: onSound)),
          Positioned(
              left: s(132),
              top: s(8),
              child: RoundBtn(Icons.music_note_rounded, size: 38, off: !music, onTap: onMusic)),
          Positioned(
            left: cx - s(173),
            top: 0,
            child: ValueListenableBuilder<double>(
              valueListenable: ink,
              builder: (_, v, __) => InkMeter(value: v),
            ),
          ),
          Positioned(
            right: s(77),
            top: s(10),
            child: Tap(onTap: onHint, child: HintPill(free: hintFree)),
          ),
          Positioned(right: s(21), top: s(8), child: RoundBtn(Icons.refresh_rounded, size: 38, onTap: onRetry)),
        ],
      ),
    );
  }
}

class InkMeter extends StatelessWidget {
  final double value;
  const InkMeter({super.key, required this.value});

  @override
  Widget build(BuildContext context) {
    const barL = 50.0, barW = 293.0;
    return SizedBox(
      width: s(350),
      height: s(52),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // ink bottle with percentage
          Positioned(
            left: s(4),
            top: s(4),
            child: Column(
              children: [
                Container(
                  width: s(20),
                  height: s(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3D3D3D),
                    borderRadius: BorderRadius.vertical(top: Radius.circular(s(2))),
                  ),
                ),
                Container(
                  width: s(40),
                  height: s(22),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: const Color(0xFF3D3D3D),
                    borderRadius: BorderRadius.circular(s(6)),
                    border: Border.all(color: Colors.white70, width: s(1)),
                  ),
                  child: Text('${(value * 100).round()}%',
                      style: TextStyle(color: Colors.white, fontSize: s(10.5))),
                ),
              ],
            ),
          ),
          Positioned(
            left: s(barL),
            top: s(28),
            child: Container(
              width: s(barW),
              height: s(9),
              decoration: BoxDecoration(
                color: const Color(0xFFA5A5A5),
                borderRadius: BorderRadius.circular(s(5)),
              ),
              alignment: Alignment.centerLeft,
              child: Container(
                width: s(barW) * value,
                decoration: BoxDecoration(
                  color: const Color(0xFF3B3B3B),
                  borderRadius: BorderRadius.circular(s(5)),
                ),
              ),
            ),
          ),
          for (final f in [0.0, 0.40, 0.727])
            Positioned(
              left: s(barL + barW * f - 10 + (f == 0 ? 3 : 0)),
              top: s(2),
              child: StarShape(size: s(20), on: value >= f, badge: true),
            ),
          for (final f in [0.40, 0.727])
            Positioned(
              left: s(barL + barW * f - 2),
              top: s(31),
              child: Container(
                width: s(4),
                height: s(4),
                decoration: const BoxDecoration(color: Color(0xFF777777), shape: BoxShape.circle),
              ),
            ),
        ],
      ),
    );
  }
}

class HintPill extends StatelessWidget {
  final bool free;
  const HintPill({super.key, required this.free});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: s(84),
      height: s(34),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: s(80),
            height: s(32),
            decoration: BoxDecoration(
              color: const Color(0xFF1E9BE0),
              borderRadius: BorderRadius.circular(s(16)),
              border: Border.all(color: const Color(0xFF136FA8), width: s(1.5)),
            ),
            padding: EdgeInsets.only(left: s(4)),
            child: Row(
              children: [
                Icon(Icons.lightbulb_rounded, color: const Color(0xFF1B2A38), size: s(24)),
                SizedBox(width: s(2)),
                Text(free ? 'HINT\nFREE' : 'HINT',
                    style: TextStyle(
                        color: Colors.white, fontSize: s(9.5), height: 1.0, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          if (!free)
            Positioned(
              right: 0,
              bottom: -s(2),
              child: Container(
                width: s(22),
                height: s(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(s(3)),
                ),
                child: Icon(Icons.videocam_rounded, size: s(16), color: Colors.black87),
              ),
            ),
        ],
      ),
    );
  }
}
