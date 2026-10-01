import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../art/palette.dart';
import '../core/ads.dart';
import '../core/audio.dart';
import '../core/billing.dart';
import '../core/l10n.dart';
import '../core/save.dart';
import 'rewards.dart';
import 'widgets.dart';

/// Coins given by the free (rewarded video) button.
const kFreeVideoCoins = 100;

/// "Get More Coins!": a free coins video and four coin packs.
class CoinShopDialog extends StatefulWidget {
  const CoinShopDialog({super.key});

  @override
  State<CoinShopDialog> createState() => _CoinShopDialogState();
}

class _CoinShopDialogState extends State<CoinShopDialog> {
  StreamSubscription<BillingEvent>? _sub;

  @override
  void initState() {
    super.initState();
    Billing.I.addListener(_changed);
    Save.I.addListener(_changed);
    _sub = Billing.I.events.listen((e) {
      if (!mounted) return;
      if (e.success) Audio.I.play(Sfx.coin);
      showToast(context, e.message);
    });
    if (!Billing.I.available) Billing.I.refresh();
  }

  @override
  void dispose() {
    Billing.I.removeListener(_changed);
    Save.I.removeListener(_changed);
    _sub?.cancel();
    super.dispose();
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  void _freeCoins() {
    Ads.I.showRewarded(context, () {
      Save.I.update(() => Save.I.coins += kFreeVideoCoins);
      Audio.I.play(Sfx.coin);
      if (mounted) showToast(context, tr('coinsAdded', kFreeVideoCoins));
    });
  }

  @override
  Widget build(BuildContext context) {
    final packs = ProductIds.coinPacks.entries.toList();
    return Material(
      color: Colors.transparent,
      child: SizedBox(
        width: s(840),
        height: s(390),
        child: CustomPaint(
          painter: _SheetPainter(),
          child: Stack(
            children: [
              Positioned(
                  left: s(60), top: s(18), child: _Balance(Save.I.coins)),
              Positioned(
                left: s(300),
                right: s(80),
                top: s(14),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(tr('getCoins'),
                      style: TextStyle(
                          fontSize: s(38), color: const Color(0xFF333333))),
                ),
              ),
              Positioned(
                right: s(14),
                top: s(10),
                child: Tap(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    width: s(52),
                    height: s(52),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: const Color(0xFF222222), width: s(3.5)),
                    ),
                    child: Icon(Icons.close_rounded,
                        size: s(40), color: const Color(0xFF222222)),
                  ),
                ),
              ),
              Positioned(
                  left: s(68),
                  top: s(95),
                  child: _FreeButton(onTap: _freeCoins)),
              for (var i = 0; i < packs.length; i++)
                Positioned(
                  left: s(415 + (i % 2) * 215.0),
                  top: s(80 + (i ~/ 2) * 150.0),
                  child: _PackCard(
                    coins: packs[i].value,
                    price: Billing.I.priceOf(packs[i].key),
                    busy: (Billing.I.state[packs[i].key] ?? BuyState.idle) !=
                        BuyState.idle,
                    size: i,
                    onTap: () => Billing.I.buyCoins(packs[i].key),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Balance extends StatelessWidget {
  final int coins;
  const _Balance(this.coins);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: s(210),
      height: s(46),
      decoration: BoxDecoration(
        color: const Color(0xFFDDDDDD),
        borderRadius: BorderRadius.circular(s(23)),
      ),
      padding: EdgeInsets.only(left: s(8)),
      child: Row(children: [
        CoinIcon(size: s(38)),
        SizedBox(width: s(12)),
        Text('$coins', style: TextStyle(fontSize: s(30), color: Colors.white)),
      ]),
    );
  }
}

class _FreeButton extends StatelessWidget {
  final VoidCallback onTap;
  const _FreeButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Tap(
      onTap: onTap,
      child: Container(
        width: s(252),
        height: s(56),
        color: const Color(0xFF9BD34A),
        padding: EdgeInsets.symmetric(horizontal: s(10)),
        child: Row(children: [
          CoinIcon(size: s(32)),
          SizedBox(width: s(10)),
          Text('+$kFreeVideoCoins',
              style: TextStyle(fontSize: s(20), color: Colors.white)),
          const Spacer(),
          Container(
            height: s(36),
            padding: EdgeInsets.symmetric(horizontal: s(6)),
            color: const Color(0xFFF07D2B),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const VideoBadge(size: 18),
              SizedBox(width: s(4)),
              ConstrainedBox(
                constraints: BoxConstraints(maxWidth: s(62)),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(tr('free'),
                      style: TextStyle(fontSize: s(15), color: Colors.white)),
                ),
              ),
            ]),
          ),
        ]),
      ),
    );
  }
}

class _PackCard extends StatelessWidget {
  final int coins;
  final String price;
  final bool busy;
  final int size; // 0..3, how big the coin pile is
  final VoidCallback onTap;
  const _PackCard({
    required this.coins,
    required this.price,
    required this.busy,
    required this.size,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tap(
      onTap: busy ? null : onTap,
      child: Opacity(
        opacity: busy ? 0.6 : 1,
        child: SizedBox(
          width: s(180),
          height: s(132),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                left: 0,
                top: 0,
                width: s(180),
                height: s(118),
                child: CustomPaint(painter: _PackPainter(size)),
              ),
              Positioned(
                left: 0,
                right: 0,
                top: s(68),
                height: s(26),
                child: Container(
                  color: const Color(0xFFE8394B),
                  alignment: Alignment.center,
                  child: Text('+$coins',
                      style: TextStyle(fontSize: s(22), color: Colors.white)),
                ),
              ),
              Positioned(
                left: s(42),
                right: s(42),
                bottom: 0,
                height: s(28),
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFC650EC),
                    borderRadius: BorderRadius.circular(s(14)),
                  ),
                  padding: EdgeInsets.symmetric(horizontal: s(6)),
                  alignment: Alignment.center,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(busy ? '…' : price,
                        style: TextStyle(fontSize: s(16), color: Colors.white)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Gold card with a sunburst and a pile of coins that grows with the pack.
class _PackPainter extends CustomPainter {
  final int size;
  _PackPainter(this.size);

  @override
  void paint(Canvas c, Size sz) {
    final r = Offset.zero & sz;
    c.drawRect(r.shift(const Offset(2, 3)), Paint()..color = Colors.black12);
    c.drawRect(r, Paint()..color = const Color(0xFFFFC928));
    final o = Offset(sz.width / 2, sz.height * 0.38);
    final ray = Paint()..color = const Color(0x55FFF3A0);
    for (var i = 0; i < 12; i++) {
      final a = i / 12 * math.pi * 2;
      c.drawPath(
          Path()
            ..moveTo(o.dx, o.dy)
            ..lineTo(o.dx + math.cos(a - 0.12) * sz.width,
                o.dy + math.sin(a - 0.12) * sz.width)
            ..lineTo(o.dx + math.cos(a + 0.12) * sz.width,
                o.dy + math.sin(a + 0.12) * sz.width)
            ..close(),
          ray);
    }
    c.save();
    c.clipRect(r);
    c.drawCircle(o, sz.height * 0.32, Paint()..color = const Color(0x66FFFDE0));
    c.restore();
    final cr = sz.height * 0.085;
    final pile = <Offset>[];
    final cols = 3 + size;
    for (var row = 0; row < 2 + (size + 1) ~/ 2; row++) {
      for (var i = 0; i < cols - row; i++) {
        pile.add(
            Offset((i - (cols - row - 1) / 2) * cr * 1.5, -row * cr * 0.9));
      }
    }
    final base = Offset(o.dx, sz.height * 0.5);
    for (final p in pile) {
      final q = base + p;
      c.drawOval(
          Rect.fromCenter(
              center: q + Offset(0, cr * 0.25),
              width: cr * 2.1,
              height: cr * 1.3),
          Paint()..color = C.goldDark);
      c.drawOval(Rect.fromCenter(center: q, width: cr * 2.1, height: cr * 1.3),
          Paint()..color = const Color(0xFFFFD84A));
    }
    final sparkle = Paint()..color = Colors.white;
    for (final sp in [
      const Offset(0.3, 0.18),
      const Offset(0.72, 0.14),
      const Offset(0.8, 0.42)
    ]) {
      final p = Offset(sz.width * sp.dx, sz.height * sp.dy);
      c.drawPath(starPath(p, cr * 0.7, cr * 0.18), sparkle);
    }
  }

  @override
  bool shouldRepaint(_PackPainter old) => old.size != size;
}

/// White torn-paper sheet behind the coin shop.
class _SheetPainter extends CustomPainter {
  @override
  void paint(Canvas c, Size sz) {
    final r = Offset.zero & sz;
    c.drawRect(r.shift(const Offset(4, 5)), Paint()..color = Colors.black26);
    c.drawRect(r, Paint()..color = Colors.white);
    final fold = Paint()..color = const Color(0xFFE6E6E6);
    final f = sz.shortestSide * 0.07;
    c.drawPath(
        Path()
          ..moveTo(0, f)
          ..lineTo(f, 0)
          ..lineTo(f * 0.8, f * 0.8)
          ..close(),
        fold);
    c.drawPath(
        Path()
          ..moveTo(sz.width - f, sz.height)
          ..lineTo(sz.width, sz.height - f)
          ..lineTo(sz.width - f * 0.8, sz.height - f * 0.8)
          ..close(),
        fold);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

void showCoinShop(BuildContext context) =>
    showPopup(context, const CoinShopDialog());
