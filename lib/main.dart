import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'core/audio.dart';
import 'core/save.dart';
import 'game/game_screen.dart';
import 'game/levels.dart';
import 'ui/levels_screen.dart';
import 'ui/loading.dart';
import 'ui/widgets.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations(
      [DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight]);
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  await Save.I.load();
  Audio.I.init();
  runApp(const LoveDotsApp());
}

class LoveDotsApp extends StatelessWidget {
  const LoveDotsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Love Dots',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: false, fontFamily: 'Roboto'),
      home: const Root(),
    );
  }
}

enum Screen { loading, game, levels }

class Root extends StatefulWidget {
  const Root({super.key});
  @override
  State<Root> createState() => _RootState();
}

class _RootState extends State<Root> with WidgetsBindingObserver {
  Screen screen = Screen.loading;
  int level = 0;
  int gameKey = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      Audio.I.pauseAll();
    } else if (state == AppLifecycleState.resumed) {
      Audio.I.refreshMusic();
    }
  }

  void _play(int i) {
    setState(() {
      level = i;
      gameKey++;
      screen = Screen.game;
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    S.k = size.height / 520;
    final Widget child = switch (screen) {
      Screen.loading => LoadingScreen(
          key: const ValueKey('loading'),
          onDone: () => _play(Save.I.lastPlayed.clamp(0, levels.length - 1)),
        ),
      Screen.game => GameScreen(
          key: ValueKey('game$gameKey'),
          level: level,
          onLevels: () => setState(() => screen = Screen.levels),
        ),
      Screen.levels => LevelsScreen(
          key: const ValueKey('levels'),
          onPlay: _play,
          onBack: () => _play(Save.I.lastPlayed.clamp(0, levels.length - 1)),
        ),
    };
    return PopScope(
      canPop: screen != Screen.game,
      onPopInvoked: (didPop) {
        if (!didPop && screen == Screen.game) setState(() => screen = Screen.levels);
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: child,
        ),
      ),
    );
  }
}
