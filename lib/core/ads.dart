import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'audio.dart';
import 'save.dart';

/// Google's public test ad unit IDs. Replace with real IDs before release.
class AdIds {
  static const appOpen = 'ca-app-pub-3940256099942544/9257395921';
  static const interstitial = 'ca-app-pub-3940256099942544/1033173712';
  static const rewarded = 'ca-app-pub-3940256099942544/5224354917';
}

/// Every ad in the game goes through here.
///
/// Rules:
/// * interstitial: after every 3rd completed level, when the player taps NEXT
/// * rewarded: only when the player taps a video button (always optional)
/// * app open: on cold start (not the very first launch) and on return from
///   background, never right after another full-screen ad or an app switch
///   the game started itself (share sheet, email, Play purchase)
/// No banner ads. Ads-free purchases turn off interstitial and app open ads.
/// Rewarded videos stay, since the player chooses to watch them.
class Ads extends ChangeNotifier {
  Ads._();
  static final Ads I = Ads._();

  static const levelsPerInterstitial = 3;
  static const _appOpenMaxAge = Duration(hours: 4);
  static const unavailableMessage =
      'Internet connection lost, please check it out and try again.';

  bool _ready = false;
  bool get ready => _ready;

  InterstitialAd? _interstitial;
  RewardedAd? _rewarded;
  AppOpenAd? _appOpen;
  DateTime? _appOpenLoadedAt;
  bool _showingFullScreen = false;
  DateTime _suppressAppOpenUntil = DateTime.fromMillisecondsSinceEpoch(0);
  bool _skipNextResume = false;
  int _retryInterstitial = 0, _retryRewarded = 0, _retryAppOpen = 0;

  bool get showingFullScreen => _showingFullScreen;

  /// Gathers consent (EEA/UK only shows a form), then starts the SDK.
  Future<void> init() async {
    final done = Completer<void>();
    ConsentInformation.instance.requestConsentInfoUpdate(
      ConsentRequestParameters(),
      () {
        ConsentForm.loadAndShowConsentFormIfRequired((_) => done.complete());
      },
      (_) => done.complete(),
    );
    await done.future.timeout(const Duration(seconds: 8), onTimeout: () {});
    if (!await ConsentInformation.instance.canRequestAds()) {
      debugPrint('Ads: consent not given, ads disabled');
      return;
    }
    await MobileAds.instance.initialize();
    _ready = true;
    _loadInterstitial();
    _loadRewarded();
    _loadAppOpen();
    notifyListeners();
  }

  /// Whether the "Privacy options" entry should be offered in Settings.
  Future<bool> privacyOptionsRequired() async =>
      await ConsentInformation.instance.getPrivacyOptionsRequirementStatus() ==
      PrivacyOptionsRequirementStatus.required;

  void showPrivacyOptions() {
    ConsentForm.showPrivacyOptionsForm((_) {});
  }

  /// Call before the game itself opens another app (share, email, billing),
  /// so coming back doesn't trigger an app open ad.
  void skipNextResume() => _skipNextResume = true;

  /// Undo [skipNextResume] when the other app never opened.
  void onResumeHandled() => _skipNextResume = false;

  // ------------------------------------------------------------- interstitial

  void _loadInterstitial() {
    if (!_ready || _interstitial != null) return;
    InterstitialAd.load(
      adUnitId: AdIds.interstitial,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitial = ad;
          _retryInterstitial = 0;
        },
        onAdFailedToLoad: (e) {
          debugPrint('Ads: interstitial failed: ${e.message}');
          _retryLater(() => _loadInterstitial(), ++_retryInterstitial);
        },
      ),
    );
  }

  /// Shows an interstitial if 3 levels were completed since the last one,
  /// then calls [then]. [then] always runs exactly once.
  void maybeShowInterstitial(VoidCallback then) {
    final due = Save.I.levelsSinceAd >= levelsPerInterstitial;
    final ad = _interstitial;
    if (!due || Save.I.adsFree || ad == null || _showingFullScreen) {
      if (due && ad == null) _loadInterstitial();
      then();
      return;
    }
    _interstitial = null;
    ad.fullScreenContentCallback = _fullScreenCallback<InterstitialAd>(onClosed: () {
      Save.I.update(() => Save.I.levelsSinceAd = 0);
      _loadInterstitial();
      then();
    });
    _beginFullScreen();
    ad.show();
  }

  // ------------------------------------------------------------- rewarded

  void _loadRewarded() {
    if (!_ready || _rewarded != null) return;
    RewardedAd.load(
      adUnitId: AdIds.rewarded,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewarded = ad;
          _retryRewarded = 0;
          notifyListeners();
        },
        onAdFailedToLoad: (e) {
          debugPrint('Ads: rewarded failed: ${e.message}');
          _retryLater(() => _loadRewarded(), ++_retryRewarded);
        },
      ),
    );
  }

  bool get rewardedReady => _rewarded != null;

  /// Plays a rewarded video. [onReward] runs after the ad closes, only if
  /// the reward was earned. Shows [unavailableMessage] when no ad is ready.
  void showRewarded(BuildContext context, VoidCallback onReward) {
    final ad = _rewarded;
    if (ad == null || _showingFullScreen) {
      _loadRewarded();
      _toast(context, unavailableMessage);
      return;
    }
    _rewarded = null;
    var earned = false;
    ad.fullScreenContentCallback = _fullScreenCallback<RewardedAd>(onClosed: () {
      _loadRewarded();
      if (earned) onReward();
    });
    _beginFullScreen();
    ad.show(onUserEarnedReward: (_, __) => earned = true);
  }

  // ------------------------------------------------------------- app open

  void _loadAppOpen() {
    if (!_ready || _appOpen != null) return;
    AppOpenAd.load(
      adUnitId: AdIds.appOpen,
      request: const AdRequest(),
      adLoadCallback: AppOpenAdLoadCallback(
        onAdLoaded: (ad) {
          _appOpen = ad;
          _appOpenLoadedAt = DateTime.now();
          _retryAppOpen = 0;
        },
        onAdFailedToLoad: (e) {
          debugPrint('Ads: app open failed: ${e.message}');
          _retryLater(() => _loadAppOpen(), ++_retryAppOpen);
        },
      ),
    );
  }

  bool get _appOpenFresh =>
      _appOpen != null &&
      _appOpenLoadedAt != null &&
      DateTime.now().difference(_appOpenLoadedAt!) < _appOpenMaxAge;

  /// Cold start: shows the app open ad if one is ready. Skipped on the very
  /// first launch so new players go straight into the game.
  void showAppOpenOnStart(VoidCallback then) {
    if (Save.I.launches <= 1) {
      then();
      return;
    }
    _showAppOpen(then);
  }

  /// Called when the app returns to the foreground.
  void onResume() {
    if (_skipNextResume) {
      _skipNextResume = false;
      return;
    }
    if (DateTime.now().isBefore(_suppressAppOpenUntil)) return;
    _showAppOpen(() {});
  }

  void _showAppOpen(VoidCallback then) {
    final ad = _appOpen;
    if (Save.I.adsFree || _showingFullScreen || !_appOpenFresh || ad == null) {
      if (!_appOpenFresh) {
        _appOpen?.dispose();
        _appOpen = null;
        _loadAppOpen();
      }
      then();
      return;
    }
    _appOpen = null;
    ad.fullScreenContentCallback = _fullScreenCallback<AppOpenAd>(onClosed: () {
      _loadAppOpen();
      then();
    });
    _beginFullScreen();
    ad.show();
  }

  // ------------------------------------------------------------- helpers

  void _beginFullScreen() {
    _showingFullScreen = true;
    Audio.I.pauseAll();
  }

  FullScreenContentCallback<T> _fullScreenCallback<T extends Ad>({required VoidCallback onClosed}) {
    void finish(T ad) {
      ad.dispose();
      _showingFullScreen = false;
      // Closing a full-screen ad resumes the app; don't stack an app open ad.
      _suppressAppOpenUntil = DateTime.now().add(const Duration(seconds: 3));
      Audio.I.refreshMusic();
      onClosed();
    }

    return FullScreenContentCallback<T>(
      onAdDismissedFullScreenContent: finish,
      onAdFailedToShowFullScreenContent: (ad, e) {
        debugPrint('Ads: failed to show: ${e.message}');
        finish(ad);
      },
    );
  }

  void _retryLater(VoidCallback load, int attempt) {
    final secs = [5, 15, 30, 60][(attempt - 1).clamp(0, 3)];
    Timer(Duration(seconds: secs), load);
  }

  void _toast(BuildContext context, String msg) {
    final overlay = Overlay.maybeOf(context);
    if (overlay == null) return;
    late OverlayEntry e;
    e = OverlayEntry(
      builder: (ctx) => Positioned(
        left: 0,
        right: 0,
        top: MediaQuery.of(ctx).size.height * 0.24,
        child: IgnorePointer(
          child: Container(
            color: Colors.white.withOpacity(0.75),
            padding: const EdgeInsets.symmetric(vertical: 10),
            alignment: Alignment.center,
            child: Text(msg,
                style: const TextStyle(color: Color(0xFF333333), fontSize: 16, decoration: TextDecoration.none)),
          ),
        ),
      ),
    );
    overlay.insert(e);
    Future.delayed(const Duration(milliseconds: 2200), e.remove);
  }
}
