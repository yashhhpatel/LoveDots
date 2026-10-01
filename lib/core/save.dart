import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persistent player progress and settings.
class Save extends ChangeNotifier {
  Save._();
  static final Save I = Save._();

  late SharedPreferences _p;

  int coins = 0;
  Map<int, int> stars = {}; // level index (0-based) -> best stars
  int lastPlayed = 0;
  bool sound = true;
  bool music = true;
  bool vibration = true;
  Set<String> ownedPens = {'classic'};
  Set<String> ownedBalls = {'classic'};
  Set<String> ownedBgs = {'notebook'};
  String pen = 'classic';
  String balls = 'classic';
  String bg = 'notebook';
  Set<int> freeHintUsed = {};
  bool dailyChallenge = false;

  /// Bonus-skin trials: skin id -> expiry epoch ms.
  Map<String, int> trials = {};

  Future<void> load() async {
    _p = await SharedPreferences.getInstance();
    coins = _p.getInt('coins') ?? 0;
    final s = _p.getString('stars');
    if (s != null) {
      stars = (jsonDecode(s) as Map<String, dynamic>)
          .map((k, v) => MapEntry(int.parse(k), v as int));
    }
    lastPlayed = _p.getInt('lastPlayed') ?? 0;
    sound = _p.getBool('sound') ?? true;
    music = _p.getBool('music') ?? true;
    vibration = _p.getBool('vibration') ?? true;
    ownedPens = (_p.getStringList('ownedPens') ?? ['classic']).toSet();
    ownedBalls = (_p.getStringList('ownedBalls') ?? ['classic']).toSet();
    ownedBgs = (_p.getStringList('ownedBgs') ?? ['notebook']).toSet();
    pen = _p.getString('pen') ?? 'classic';
    balls = _p.getString('balls') ?? 'classic';
    bg = _p.getString('bg') ?? 'notebook';
    freeHintUsed =
        (_p.getStringList('freeHint') ?? []).map(int.parse).toSet();
    dailyChallenge = _p.getBool('daily') ?? false;
    final t = _p.getString('trials');
    if (t != null) {
      trials = (jsonDecode(t) as Map<String, dynamic>)
          .map((k, v) => MapEntry(k, v as int));
    }
  }

  void _persist() {
    _p.setInt('coins', coins);
    _p.setString(
        'stars', jsonEncode(stars.map((k, v) => MapEntry('$k', v))));
    _p.setInt('lastPlayed', lastPlayed);
    _p.setBool('sound', sound);
    _p.setBool('music', music);
    _p.setBool('vibration', vibration);
    _p.setStringList('ownedPens', ownedPens.toList());
    _p.setStringList('ownedBalls', ownedBalls.toList());
    _p.setStringList('ownedBgs', ownedBgs.toList());
    _p.setString('pen', pen);
    _p.setString('balls', balls);
    _p.setString('bg', bg);
    _p.setStringList(
        'freeHint', freeHintUsed.map((e) => '$e').toList());
    _p.setBool('daily', dailyChallenge);
    _p.setString('trials', jsonEncode(trials));
  }

  void update(void Function() f) {
    f();
    _persist();
    notifyListeners();
  }

  int get totalStars => stars.values.fold(0, (a, b) => a + b);

  /// Highest level index the player may open.
  int get unlockedUpTo {
    var i = 0;
    while (stars.containsKey(i)) {
      i++;
    }
    return i;
  }

  bool trialActive(String id) {
    final e = trials[id];
    return e != null && e > DateTime.now().millisecondsSinceEpoch;
  }

  /// Ball skin to actually render (trial skins override the chosen one).
  String get activeBalls {
    for (final e in trials.entries) {
      if (e.key.startsWith('ball:') && trialActive(e.key)) {
        return e.key.substring(5);
      }
    }
    return balls;
  }

  String get activePen {
    for (final e in trials.entries) {
      if (e.key.startsWith('pen:') && trialActive(e.key)) {
        return e.key.substring(4);
      }
    }
    return pen;
  }
}
