import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';

import 'ads.dart';
import 'save.dart';
import 'l10n.dart';

/// Play Console product IDs. Create these before release:
/// * [monthly]: auto-renewing subscription, 1 month, ₹299
/// * [lifetime]: one-time (non-consumable) in-app product, ₹2,999
class ProductIds {
  static const monthly = 'ads_free_monthly';
  static const lifetime = 'ads_free_lifetime';
  static const all = {monthly, lifetime};
}

enum BuyState { idle, buying, pending }

/// Result of a purchase-related action, for the UI to show.
class BillingEvent {
  final String message;
  final bool success;
  const BillingEvent(this.message, {this.success = false});
}

/// Remove-ads purchases through Google Play Billing.
///
/// Entitlements are re-read from Play on every launch and resume, so an
/// expired or refunded monthly subscription switches ads back on, and a
/// reinstall picks the purchases up again.
class Billing extends ChangeNotifier {
  Billing._();
  static final Billing I = Billing._();

  final _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _sub;
  final _events = StreamController<BillingEvent>.broadcast();

  bool available = false;
  bool loading = true;
  final Map<String, ProductDetails> products = {};
  final Map<String, BuyState> state = {};

  Stream<BillingEvent> get events => _events.stream;

  /// Shown when Play hasn't returned a localized price yet.
  static const fallbackPrices = {
    ProductIds.monthly: '₹299',
    ProductIds.lifetime: '₹2,999',
  };

  String priceOf(String id) => products[id]?.price ?? fallbackPrices[id]!;

  Future<void> init() async {
    _sub = _iap.purchaseStream.listen(_onPurchases, onError: (Object e) {
      debugPrint('Billing: stream error $e');
    });
    await refresh();
  }

  /// Reconnects to Play, reloads prices and re-syncs what the player owns.
  Future<void> refresh() async {
    loading = true;
    notifyListeners();
    available = await _iap.isAvailable();
    if (available) {
      final res = await _iap.queryProductDetails(ProductIds.all);
      for (final p in res.productDetails) {
        products[p.id] = p;
      }
      if (res.notFoundIDs.isNotEmpty) {
        debugPrint('Billing: products not found in Play Console: ${res.notFoundIDs}');
      }
      await _syncOwned();
    }
    loading = false;
    notifyListeners();
  }

  /// Reads current purchases straight from Play and updates entitlements.
  /// Returns the number of active ads-free purchases found, or null if Play
  /// could not be reached (cached entitlements are kept in that case).
  Future<int?> _syncOwned() async {
    final android = _iap.getPlatformAddition<InAppPurchaseAndroidPlatformAddition>();
    final res = await android.queryPastPurchases();
    if (res.error != null) {
      debugPrint('Billing: queryPastPurchases failed: ${res.error!.message}');
      return null;
    }
    var lifetime = false, monthly = false;
    for (final p in res.pastPurchases) {
      if (p.status != PurchaseStatus.purchased && p.status != PurchaseStatus.restored) {
        continue;
      }
      if (p.productID == ProductIds.lifetime) lifetime = true;
      if (p.productID == ProductIds.monthly) monthly = true;
      if (p.pendingCompletePurchase) await _iap.completePurchase(p);
    }
    Save.I.update(() {
      Save.I.adsFreeLifetime = lifetime;
      Save.I.adsFreeMonthly = monthly;
    });
    return (lifetime ? 1 : 0) + (monthly ? 1 : 0);
  }

  bool owns(String id) =>
      id == ProductIds.lifetime ? Save.I.adsFreeLifetime : Save.I.adsFreeMonthly;

  /// Starts the Play purchase sheet for [id].
  Future<void> buy(String id) async {
    if (owns(id) || (id == ProductIds.monthly && Save.I.adsFreeLifetime)) {
      _events.add(BillingEvent(tr('bAlready'), success: true));
      return;
    }
    if (!available) {
      await refresh();
    }
    final product = products[id];
    if (!available || product == null) {
      _events.add(BillingEvent(tr('bUnavailable')));
      return;
    }
    if (state[id] == BuyState.pending) {
      _events.add(BillingEvent(tr('bStillPending')));
      return;
    }
    state[id] = BuyState.buying;
    notifyListeners();
    Ads.I.skipNextResume();
    try {
      // Subscriptions and one-time items both use buyNonConsumable.
      await _iap.buyNonConsumable(purchaseParam: PurchaseParam(productDetails: product));
    } catch (e) {
      debugPrint('Billing: buy failed $e');
      state[id] = BuyState.idle;
      notifyListeners();
      _events.add(BillingEvent(tr('bStartFailed')));
    }
  }

  /// "Restore purchases": re-reads everything the player owns from Play.
  Future<void> restore() async {
    if (!available) await refresh();
    if (!available) {
      _events.add(BillingEvent(tr('bUnavailable')));
      return;
    }
    final n = await _syncOwned();
    notifyListeners();
    if (n == null) {
      _events.add(BillingEvent(tr('bNoReach')));
    } else if (n == 0) {
      _events.add(BillingEvent(tr('bNothing')));
    } else {
      _events.add(BillingEvent(tr('bRestored'), success: true));
    }
  }

  Future<void> _onPurchases(List<PurchaseDetails> list) async {
    for (final p in list) {
      if (!ProductIds.all.contains(p.productID)) continue;
      switch (p.status) {
        case PurchaseStatus.pending:
          state[p.productID] = BuyState.pending;
          _events.add(BillingEvent(tr('bPending')));
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          _grant(p.productID);
          state[p.productID] = BuyState.idle;
          if (p.status == PurchaseStatus.purchased) {
            _events.add(BillingEvent(tr('bThanks'), success: true));
          }
        case PurchaseStatus.canceled:
          state[p.productID] = BuyState.idle;
          _events.add(BillingEvent(tr('bCancelled')));
        case PurchaseStatus.error:
          state[p.productID] = BuyState.idle;
          final msg = p.error?.message ?? '';
          if (msg.contains('itemAlreadyOwned')) {
            // Bought earlier (another device or reinstall): restore it.
            await _syncOwned();
            _events.add(BillingEvent(tr('bOwned'), success: true));
          } else {
            _events.add(BillingEvent(tr('bFailed')));
          }
      }
      // Acknowledge, or Google refunds the purchase after 3 days.
      if (p.pendingCompletePurchase) await _iap.completePurchase(p);
    }
    notifyListeners();
  }

  void _grant(String id) {
    Save.I.update(() {
      if (id == ProductIds.lifetime) Save.I.adsFreeLifetime = true;
      if (id == ProductIds.monthly) Save.I.adsFreeMonthly = true;
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    _events.close();
    super.dispose();
  }
}
