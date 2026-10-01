import 'package:flutter/material.dart';

import '../art/backgrounds.dart';
import '../art/characters.dart';
import '../art/palette.dart';
import '../core/audio.dart';
import '../core/save.dart';
import 'widgets.dart';

enum ShopTab { pen, ball, bg }

class ShopDialog extends StatefulWidget {
  final ShopTab initial;
  const ShopDialog({super.key, this.initial = ShopTab.pen});

  @override
  State<ShopDialog> createState() => _ShopDialogState();
}

class _ShopDialogState extends State<ShopDialog> {
  late ShopTab tab = widget.initial;
  late PageController _pc = _controller();

  PageController _controller() {
    final idx = switch (tab) {
      ShopTab.pen => penItems.indexWhere((e) => e.id == Save.I.pen),
      ShopTab.ball => ballItems.indexWhere((e) => e.id == Save.I.balls),
      ShopTab.bg => bgItems.indexWhere((e) => e.id == Save.I.bg),
    };
    return PageController(viewportFraction: 0.44, initialPage: idx < 0 ? 0 : idx);
  }

  int _page = 0;

  @override
  void initState() {
    super.initState();
    _page = _pc.initialPage;
  }

  void _setTab(ShopTab t) {
    if (t == tab) return;
    setState(() {
      tab = t;
      _pc.dispose();
      _pc = _controller();
      _page = _pc.initialPage;
    });
  }

  @override
  void dispose() {
    _pc.dispose();
    super.dispose();
  }

  String get _title => switch (tab) {
        ShopTab.pen => 'Pen Shop',
        ShopTab.ball => 'Ball Shop',
        ShopTab.bg => 'Background Shop',
      };

  int get _count => switch (tab) {
        ShopTab.pen => penItems.length,
        ShopTab.ball => ballItems.length,
        ShopTab.bg => bgItems.length,
      };

  (String id, int price, bool iap) _item(int i) => switch (tab) {
        ShopTab.pen => (penItems[i].id, penItems[i].price, penItems[i].iap),
        ShopTab.ball => (ballItems[i].id, ballItems[i].price, ballItems[i].iap),
        ShopTab.bg => (bgItems[i].id, bgItems[i].price, bgItems[i].iap),
      };

  bool _owned(String id) => switch (tab) {
        ShopTab.pen => Save.I.ownedPens.contains(id),
        ShopTab.ball => Save.I.ownedBalls.contains(id),
        ShopTab.bg => Save.I.ownedBgs.contains(id),
      };

  bool _using(String id) => switch (tab) {
        ShopTab.pen => Save.I.pen == id,
        ShopTab.ball => Save.I.balls == id,
        ShopTab.bg => Save.I.bg == id,
      };

  void _use(String id) {
    Save.I.update(() {
      switch (tab) {
        case ShopTab.pen:
          Save.I.pen = id;
          Save.I.trials.removeWhere((k, _) => k.startsWith('pen:'));
        case ShopTab.ball:
          Save.I.balls = id;
          Save.I.trials.removeWhere((k, _) => k.startsWith('ball:'));
        case ShopTab.bg:
          Save.I.bg = id;
      }
    });
    setState(() {});
  }

  void _buy(String id, int price) {
    if (Save.I.coins < price) {
      showToast(context, 'Not enough coins');
      return;
    }
    Audio.I.play(Sfx.coin);
    Save.I.update(() {
      Save.I.coins -= price;
      switch (tab) {
        case ShopTab.pen:
          Save.I.ownedPens.add(id);
        case ShopTab.ball:
          Save.I.ownedBalls.add(id);
        case ShopTab.bg:
          Save.I.ownedBgs.add(id);
      }
    });
    _use(id);
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: PopupCard(
        title: _title,
        width: 690,
        height: 377,
        onClose: () => Navigator.of(context).pop(),
        headerLeft: CoinPill(Save.I.coins),
        child: Stack(
          children: [
            Positioned.fill(
              left: s(70),
              right: s(10),
              child: Column(
                children: [
                  SizedBox(height: s(26)),
                  SizedBox(
                    height: s(190),
                    child: PageView.builder(
                      controller: _pc,
                      itemCount: _count,
                      onPageChanged: (i) => setState(() => _page = i),
                      itemBuilder: (_, i) => AnimatedBuilder(
                        animation: _pc,
                        builder: (_, __) {
                          var d = 0.0;
                          if (_pc.position.haveDimensions) {
                            d = ((_pc.page ?? _page.toDouble()) - i).abs();
                          } else {
                            d = (_page - i).abs().toDouble();
                          }
                          final sc = (1 - d * 0.35).clamp(0.6, 1.0);
                          return Opacity(
                            opacity: (1 - d * 0.5).clamp(0.35, 1.0),
                            child: Transform.scale(scale: sc, child: _preview(i, d < 0.5)),
                          );
                        },
                      ),
                    ),
                  ),
                  SizedBox(height: s(10)),
                  _button(),
                ],
              ),
            ),
            Positioned(left: 0, top: s(52), child: _tab(ShopTab.pen, const Color(0xFFF25A7E), Icons.edit_rounded)),
            Positioned(left: 0, top: s(117), child: _tab(ShopTab.ball, const Color(0xFFA770E0), Icons.sentiment_satisfied_alt_rounded)),
            Positioned(left: 0, top: s(184), child: _tab(ShopTab.bg, const Color(0xFFFFC233), Icons.image_rounded)),
          ],
        ),
      ),
    );
  }

  Widget _tab(ShopTab t, Color color, IconData icon) {
    final sel = t == tab;
    return Tap(
      onTap: () => _setTab(t),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: s(sel ? 62 : 40),
        height: s(48),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.horizontal(right: Radius.circular(s(24))),
        ),
        alignment: Alignment.centerRight,
        padding: EdgeInsets.only(right: s(8)),
        child: Container(
          width: s(26),
          height: s(26),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: s(1.6)),
          ),
          child: Icon(icon, color: Colors.white, size: s(16)),
        ),
      ),
    );
  }

  Widget _preview(int i, bool center) {
    final (id, _, _) = _item(i);
    final owned = _owned(id);
    Widget art;
    switch (tab) {
      case ShopTab.pen:
        art = CustomPaint(
          size: Size(s(150), s(190)),
          painter: _Fn((c, sz) => paintPen(c, Offset(sz.width * 0.12, sz.height * 0.92), sz.height * 1.1, id)),
        );
      case ShopTab.ball:
        art = CustomPaint(
          size: Size(s(170), s(110)),
          painter: _Fn((c, sz) {
            final r = sz.height * 0.17;
            paintBall(c, Offset(sz.width * 0.28, sz.height * 0.55), r,
                blue: true, skin: id, look: const Offset(1, 0), grey: !owned && !center);
            paintBall(c, Offset(sz.width * 0.72, sz.height * 0.55), r,
                blue: false, skin: id, look: const Offset(-1, 0), grey: !owned && !center);
          }),
        );
      case ShopTab.bg:
        art = CustomPaint(
          size: Size(s(200), s(114)),
          painter: _Fn((c, sz) {
            final r = Offset.zero & sz;
            paintPaper(c, r, id);
            c.drawRect(r, Paint()
              ..color = const Color(0x33000000)
              ..style = PaintingStyle.stroke);
          }),
        );
    }
    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (center && tab == ShopTab.ball)
            CustomPaint(size: Size(s(150), s(122)), painter: _Brackets()),
          art,
        ],
      ),
    );
  }

  Widget _button() {
    final (id, price, iap) = _item(_page.clamp(0, _count - 1));
    if (_using(id)) {
      return Pill('USING', color: C.redBtn, width: 150, height: 34, font: 17, onTap: () {});
    }
    if (_owned(id)) {
      return Pill('USE', color: C.greenBtn, width: 150, height: 34, font: 17, onTap: () => _use(id));
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Pill('$price',
            color: C.greenBtn,
            width: 150,
            height: 30,
            font: 14,
            icon: CoinIcon(size: s(22)),
            onTap: () => _buy(id, price)),
        if (iap) ...[
          SizedBox(height: s(4)),
          Pill('BUY NOW \$0.99',
              color: C.purpleBtn,
              width: 150,
              height: 24,
              font: 12,
              onTap: () => showToast(context, 'In-app purchases are not available in this build')),
        ],
      ],
    );
  }
}

class _Fn extends CustomPainter {
  final void Function(Canvas, Size) fn;
  _Fn(this.fn);
  @override
  void paint(Canvas canvas, Size size) => fn(canvas, size);
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _Brackets extends CustomPainter {
  @override
  void paint(Canvas c, Size sz) {
    final p = Paint()
      ..color = const Color(0xFFAEDCEB)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    const l = 10.0;
    for (final corner in [
      Offset.zero,
      Offset(sz.width, 0),
      Offset(0, sz.height),
      Offset(sz.width, sz.height)
    ]) {
      final dx = corner.dx == 0 ? l : -l;
      final dy = corner.dy == 0 ? l : -l;
      c.drawLine(corner, corner + Offset(dx, 0), p);
      c.drawLine(corner, corner + Offset(0, dy), p);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
