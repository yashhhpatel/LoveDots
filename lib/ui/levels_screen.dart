import 'package:flutter/material.dart';

import '../art/palette.dart';
import '../core/save.dart';
import '../game/geometry.dart';
import '../game/levels.dart';
import 'settings.dart';
import 'shop.dart';
import 'widgets.dart';

class LevelsScreen extends StatefulWidget {
  final void Function(int level) onPlay;
  final VoidCallback onBack;
  const LevelsScreen({super.key, required this.onPlay, required this.onBack});

  @override
  State<LevelsScreen> createState() => _LevelsScreenState();
}

class _LevelsScreenState extends State<LevelsScreen> {
  static const perPage = 6;
  late int page = (Save.I.lastPlayed ~/ perPage).clamp(0, _pages - 1);

  int get _pages => (levels.length + perPage - 1) ~/ perPage;

  @override
  void initState() {
    super.initState();
    Save.I.addListener(_changed);
  }

  @override
  void dispose() {
    Save.I.removeListener(_changed);
    super.dispose();
  }

  void _changed() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final cx = size.width / 2;
    final save = Save.I;
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Positioned.fill(child: CustomPaint(painter: _LinedPaper())),
          // top bar
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            height: s(52),
            child: Container(color: C.tealBar),
          ),
          Positioned(left: s(21), top: s(8), child: RoundBtn(Icons.chevron_left_rounded, size: 38, color: Colors.white, onTap: widget.onBack)),
          Positioned(
            left: s(82),
            top: s(8),
            child: Stack(clipBehavior: Clip.none, children: [
              RoundBtn(Icons.checkroom_rounded, size: 38, color: Colors.white,
                  onTap: () => showPopup(context, const ShopDialog())),
              Positioned(
                right: -s(2),
                top: -s(3),
                child: Container(
                  width: s(14),
                  height: s(14),
                  decoration: const BoxDecoration(color: Color(0xFFF2416F), shape: BoxShape.circle),
                  child: Icon(Icons.priority_high_rounded, size: s(11), color: Colors.white),
                ),
              ),
            ]),
          ),
          Positioned(left: s(142), top: s(8), child: RoundBtn(Icons.settings_rounded, size: 38, color: Colors.white,
              onTap: () => showPopup(context, const SettingsDialog()))),
          Positioned(left: s(203), top: s(8), child: Tap(onTap: () => _noAds(context), child: const _NoAdsIcon())),
          Positioned(
            top: s(12),
            left: 0,
            right: 0,
            child: Center(
              child: Text('LEVELS',
                  style: TextStyle(color: Colors.white, fontSize: s(22), letterSpacing: 0.5)),
            ),
          ),
          Positioned(
            right: s(30),
            top: s(8),
            child: Row(children: [
              StarShape(size: s(36)),
              SizedBox(width: s(8)),
              Text('${save.totalStars}/${levels.length * 3}',
                  style: TextStyle(color: Colors.white, fontSize: s(24))),
            ]),
          ),
          if (save.dailyChallenge)
            Positioned(
              right: s(14),
              top: s(60),
              child: Tap(
                onTap: () => widget.onPlay(DateTime.now().day % save.unlockedUpTo.clamp(1, levels.length)),
                child: Column(children: [
                  Stack(clipBehavior: Clip.none, children: [
                    Icon(Icons.mark_email_unread_rounded, color: const Color(0xFFF5A623), size: s(30)),
                    Positioned(
                      right: -s(3),
                      top: -s(3),
                      child: Container(
                        width: s(12),
                        height: s(12),
                        decoration: const BoxDecoration(color: Color(0xFFF2416F), shape: BoxShape.circle),
                      ),
                    ),
                  ]),
                  Text('Daily\nChallenge',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: s(8.5), color: const Color(0xFF777777), height: 1)),
                ]),
              ),
            ),
          // board grid
          for (var i = 0; i < perPage; i++)
            if (page * perPage + i < levels.length)
              Positioned(
                left: cx + s(-385 + (i % 3) * 384.0) - s(89),
                top: s(i < 3 ? 66 : 248),
                child: _board(page * perPage + i),
              ),
          if (page > 0)
            Positioned(
              left: s(56),
              top: s(208),
              child: Tap(
                onTap: () => setState(() => page--),
                child: Icon(Icons.arrow_back_ios_new_rounded, size: s(46), color: const Color(0xFFAAAAAA)),
              ),
            ),
          if (page < _pages - 1)
            Positioned(
              right: s(56),
              top: s(208),
              child: Tap(
                onTap: () => setState(() => page++),
                child: Icon(Icons.arrow_forward_ios_rounded, size: s(46), color: const Color(0xFFAAAAAA)),
              ),
            ),
        ],
      ),
    );
  }

  void _noAds(BuildContext context) {
    showPopup(
      context,
      Material(
        color: Colors.transparent,
        child: PopupCard(
          title: 'No Ads',
          width: 420,
          height: 220,
          onClose: () => Navigator.of(context).pop(),
          child: Center(
            child: Text('This version of Love Dots has no ads.',
                style: TextStyle(fontSize: s(18), color: const Color(0xFF555555))),
          ),
        ),
      ),
    );
  }

  Widget _board(int idx) {
    final save = Save.I;
    final unlocked = idx <= save.unlockedUpTo;
    final stars = save.stars[idx] ?? 0;
    final done = save.stars.containsKey(idx);
    final here = idx == save.lastPlayed;
    return Tap(
      onTap: unlocked ? () => widget.onPlay(idx) : null,
      child: SizedBox(
        width: s(178),
        height: s(176),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              left: 0,
              top: s(22),
              child: Container(
                width: s(178),
                height: s(106),
                decoration: BoxDecoration(
                  color: C.clipboard,
                  borderRadius: BorderRadius.circular(s(4)),
                  boxShadow: [BoxShadow(color: Colors.black26, offset: Offset(s(1), s(2)), blurRadius: s(2))],
                ),
                padding: EdgeInsets.fromLTRB(s(7), s(7), s(7), s(7)),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [BoxShadow(color: Colors.black12, offset: Offset(s(2), s(2)))],
                  ),
                  padding: EdgeInsets.all(s(3)),
                  child: CustomPaint(
                    painter: LevelPreviewPainter(levels[idx], locked: !unlocked),
                    child: Stack(children: [
                      Positioned(
                        left: s(4),
                        top: s(3),
                        child: Text((idx + 1).toString().padLeft(2, '0'),
                            style: TextStyle(fontSize: s(13), color: const Color(0xFF555555))),
                      ),
                      if (done)
                        Positioned(
                          right: s(4),
                          top: s(4),
                          child: Container(
                            width: s(22),
                            height: s(22),
                            decoration: BoxDecoration(
                              color: const Color(0xFF8BC34A),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: s(1.5)),
                            ),
                            child: Icon(Icons.check_rounded, color: Colors.white, size: s(16)),
                          ),
                        ),
                      if (!unlocked)
                        Center(child: Icon(Icons.lock_rounded, color: Colors.white, size: s(52))),
                    ]),
                  ),
                ),
              ),
            ),
            // clip
            Positioned(
              left: s(63),
              top: s(10),
              child: Container(
                width: s(52),
                height: s(20),
                decoration: BoxDecoration(
                  color: C.clip,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(s(6)), bottom: Radius.circular(s(3))),
                ),
                alignment: Alignment.topCenter,
                child: Container(
                  margin: EdgeInsets.only(top: s(3)),
                  width: s(20),
                  height: s(7),
                  decoration: BoxDecoration(color: const Color(0xFF7CC4B8), borderRadius: BorderRadius.circular(s(3))),
                ),
              ),
            ),
            if (here)
              Positioned(
                left: s(32),
                top: -s(2),
                child: Container(
                  width: s(102),
                  height: s(22),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF2507A),
                    borderRadius: BorderRadius.circular(s(8)),
                  ),
                  child: Text('You are here!', style: TextStyle(color: Colors.white, fontSize: s(11.5))),
                ),
              ),
            Positioned(
              left: s(24),
              top: s(136),
              child: Row(children: [
                for (var i = 0; i < 3; i++)
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: s(6)),
                    child: StarShape(size: s(30), on: i < stars),
                  ),
              ]),
            ),
          ],
        ),
      ),
    );
  }
}

class _NoAdsIcon extends StatelessWidget {
  const _NoAdsIcon();
  @override
  Widget build(BuildContext context) {
    return Container(
      width: s(38),
      height: s(38),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: s(2.4)),
      ),
      child: Stack(alignment: Alignment.center, children: [
        Text('ADS', style: TextStyle(color: Colors.white, fontSize: s(11), fontWeight: FontWeight.w700)),
        Transform.rotate(angle: -0.785, child: Container(width: s(32), height: s(2.4), color: Colors.white)),
      ]),
    );
  }
}

class _LinedPaper extends CustomPainter {
  @override
  void paint(Canvas c, Size sz) {
    final p = Paint()
      ..color = const Color(0xFFEDEDED)
      ..strokeWidth = 1;
    final step = sz.height / 26;
    for (var y = step * 3; y < sz.height; y += step) {
      for (var x = 0.0; x < sz.width; x += 6) {
        c.drawLine(Offset(x, y), Offset(x + 3, y), p);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
