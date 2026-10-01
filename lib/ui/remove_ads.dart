import 'dart:async';

import 'package:flutter/material.dart';

import '../art/palette.dart';
import '../core/billing.dart';
import '../core/save.dart';
import 'widgets.dart';

/// "Remove Ads" popup: 1 Month and Lifetime ads-free packages.
class RemoveAdsDialog extends StatefulWidget {
  const RemoveAdsDialog({super.key});

  @override
  State<RemoveAdsDialog> createState() => _RemoveAdsDialogState();
}

class _RemoveAdsDialogState extends State<RemoveAdsDialog> {
  StreamSubscription<BillingEvent>? _sub;

  @override
  void initState() {
    super.initState();
    Billing.I.addListener(_changed);
    Save.I.addListener(_changed);
    _sub = Billing.I.events.listen((e) {
      if (mounted) showToast(context, e.message);
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

  @override
  Widget build(BuildContext context) {
    final lifetime = Save.I.adsFreeLifetime;
    return Material(
      color: Colors.transparent,
      child: PopupCard(
        title: 'Remove Ads',
        width: 600,
        height: 360,
        onClose: () => Navigator.of(context).pop(),
        child: Padding(
          padding: EdgeInsets.fromLTRB(s(24), s(16), s(24), s(10)),
          child: Column(
            children: [
              Text(
                Save.I.adsFree
                    ? 'Ads are removed. Thank you for supporting Love Dots!'
                    : 'Play without interruptions. Optional reward videos stay available.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: s(14.5), color: const Color(0xFF666666)),
              ),
              SizedBox(height: s(14)),
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: _Package(
                        title: '1 Month Ads-Free',
                        subtitle: 'Renews monthly. Cancel anytime in Google Play.',
                        price: Billing.I.priceOf(ProductIds.monthly),
                        icon: Icons.calendar_month_rounded,
                        color: C.blueBtn,
                        owned: Save.I.adsFreeMonthly,
                        coveredByOther: lifetime,
                        state: Billing.I.state[ProductIds.monthly] ?? BuyState.idle,
                        onBuy: () => Billing.I.buy(ProductIds.monthly),
                      ),
                    ),
                    SizedBox(width: s(18)),
                    Expanded(
                      child: _Package(
                        title: 'Lifetime Ads-Free',
                        subtitle: 'Pay once. No ads, forever.',
                        price: Billing.I.priceOf(ProductIds.lifetime),
                        icon: Icons.all_inclusive_rounded,
                        color: C.pinkBtn,
                        best: true,
                        owned: lifetime,
                        coveredByOther: false,
                        state: Billing.I.state[ProductIds.lifetime] ?? BuyState.idle,
                        onBuy: () => Billing.I.buy(ProductIds.lifetime),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: s(8)),
              Tap(
                onTap: Billing.I.restore,
                child: Padding(
                  padding: EdgeInsets.all(s(6)),
                  child: Text('Restore purchases',
                      style: TextStyle(
                          fontSize: s(14),
                          color: C.tealBar,
                          decoration: TextDecoration.underline,
                          decorationColor: C.tealBar)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Package extends StatelessWidget {
  final String title, subtitle, price;
  final IconData icon;
  final Color color;
  final bool best, owned, coveredByOther;
  final BuyState state;
  final VoidCallback onBuy;

  const _Package({
    required this.title,
    required this.subtitle,
    required this.price,
    required this.icon,
    required this.color,
    this.best = false,
    required this.owned,
    required this.coveredByOther,
    required this.state,
    required this.onBuy,
  });

  @override
  Widget build(BuildContext context) {
    final String label;
    if (owned) {
      label = 'ACTIVE';
    } else if (coveredByOther) {
      label = 'INCLUDED';
    } else if (state == BuyState.pending) {
      label = 'PENDING…';
    } else if (state == BuyState.buying) {
      label = 'PLEASE WAIT…';
    } else {
      label = price;
    }
    final enabled = !owned && !coveredByOther && state == BuyState.idle;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(s(12)),
            border: Border.all(color: color, width: s(2)),
          ),
          padding: EdgeInsets.fromLTRB(s(12), s(14), s(12), s(12)),
          child: Column(
            children: [
              Icon(icon, color: color, size: s(36)),
              SizedBox(height: s(4)),
              Text(title,
                  style: TextStyle(fontSize: s(17), fontWeight: FontWeight.w700, color: const Color(0xFF3A3A3A))),
              SizedBox(height: s(4)),
              Text(subtitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: s(11.5), color: const Color(0xFF777777))),
              const Spacer(),
              Opacity(
                opacity: enabled ? 1 : 0.6,
                child: Pill(label,
                    color: owned ? C.greenBtn : color,
                    width: 150,
                    height: 34,
                    font: 17,
                    icon: owned ? Icon(Icons.check_rounded, color: Colors.white, size: s(20)) : null,
                    onTap: enabled ? onBuy : () {}),
              ),
            ],
          ),
        ),
        if (best)
          Positioned(
            right: s(10),
            top: -s(11),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: s(8), vertical: s(3)),
              decoration: BoxDecoration(color: C.yellowBtn, borderRadius: BorderRadius.circular(s(8))),
              child: Text('BEST VALUE',
                  style: TextStyle(fontSize: s(10.5), color: Colors.white, fontWeight: FontWeight.w700)),
            ),
          ),
      ],
    );
  }
}
