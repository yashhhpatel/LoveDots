import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../art/palette.dart';
import '../core/ads.dart';
import '../core/audio.dart';
import '../core/save.dart';
import '../game/levels.dart';
import 'help.dart';
import 'widgets.dart';

class SettingsDialog extends StatefulWidget {
  const SettingsDialog({super.key});
  @override
  State<SettingsDialog> createState() => _SettingsDialogState();
}

class _SettingsDialogState extends State<SettingsDialog> {
  @override
  Widget build(BuildContext context) {
    final save = Save.I;
    final items = <(IconData, String, bool, VoidCallback)>[
      (save.sound ? Icons.volume_up_rounded : Icons.volume_off_rounded, 'Sounds', save.sound, () {
        save.update(() => save.sound = !save.sound);
        if (!save.sound) Audio.I.stopDraw();
        setState(() {});
      }),
      (Icons.music_note_rounded, 'Music', save.music, () {
        save.update(() => save.music = !save.music);
        Audio.I.refreshMusic();
        setState(() {});
      }),
      (Icons.vibration_rounded, 'Vibration', save.vibration, () {
        save.update(() => save.vibration = !save.vibration);
        Audio.I.vibrate();
        setState(() {});
      }),
      (Icons.leaderboard_rounded, 'Leaderboard', true, () => showLeaderboard(context)),
      (Icons.question_mark_rounded, 'Help', true, () => showPopup(context, const HelpDialog())),
      (Icons.mail_rounded, 'Contact us', true, () => showContact(context)),
      (Icons.privacy_tip_rounded, 'Privacy', true, () => showPrivacy(context)),
      (Icons.star_rounded, 'English', true, () => _language(context)),
    ];
    return Material(
      color: Colors.transparent,
      child: PopupCard(
        title: 'Settings',
        width: 540,
        height: 340,
        onClose: () => Navigator.of(context).pop(),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: s(30), vertical: s(28)),
          child: GridView.count(
            crossAxisCount: 4,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 1.05,
            children: [
              for (final it in items)
                Tap(
                  onTap: it.$4,
                  child: Column(
                    children: [
                      Container(
                        width: s(52),
                        height: s(52),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFFE3F3F2),
                          border: Border.all(color: const Color(0xFFE3F3F2), width: s(4)),
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: it.$3 ? C.tealBar : const Color(0xFFB0B0B0),
                          ),
                          child: Icon(it.$1, color: Colors.white, size: s(26)),
                        ),
                      ),
                      SizedBox(height: s(6)),
                      Text(it.$2, style: TextStyle(fontSize: s(14), color: const Color(0xFF555555))),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _language(BuildContext context) {
    showPopup(
      context,
      Material(
        color: Colors.transparent,
        child: PopupCard(
          title: 'Language',
          width: 360,
          height: 200,
          onClose: () => Navigator.of(context).pop(),
          child: Center(
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.check_circle_rounded, color: C.tealBar, size: s(26)),
              SizedBox(width: s(10)),
              Text('English', style: TextStyle(fontSize: s(20), color: const Color(0xFF444444))),
            ]),
          ),
        ),
      ),
    );
  }
}

void showLeaderboard(BuildContext context) {
  final save = Save.I;
  final done = save.stars.length;
  showPopup(
    context,
    Material(
      color: Colors.transparent,
      child: PopupCard(
        title: 'Leaderboard',
        width: 420,
        height: 260,
        onClose: () => Navigator.of(context).pop(),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              StarShape(size: s(40)),
              SizedBox(width: s(10)),
              Text('${save.totalStars}/${levels.length * 3}',
                  style: TextStyle(fontSize: s(30), color: const Color(0xFF444444))),
            ]),
            SizedBox(height: s(14)),
            Text('Levels completed: $done',
                style: TextStyle(fontSize: s(17), color: const Color(0xFF666666))),
            SizedBox(height: s(6)),
            Text('Coins: ${save.coins}',
                style: TextStyle(fontSize: s(17), color: const Color(0xFF666666))),
          ],
        ),
      ),
    ),
  );
}

void showPrivacy(BuildContext context) {
  showPopup(
    context,
    Material(
      color: Colors.transparent,
      child: PopupCard(
        title: 'Privacy',
        width: 560,
        height: 320,
        onClose: () => Navigator.of(context).pop(),
        child: Padding(
          padding: EdgeInsets.all(s(22)),
          child: SingleChildScrollView(
            child: Text(
              'Love Dots stores your progress (levels, stars, coins, skins and settings) '
              'only on this device. The game does not collect personal data, does not '
              'use advertising identifiers and does not send any information to servers.\n\n'
              'Sharing a level uses your device\'s share sheet; nothing is sent unless you '
              'choose an app to share with.',
              style: TextStyle(fontSize: s(15), color: const Color(0xFF555555), height: 1.4),
            ),
          ),
        ),
      ),
    ),
  );
}

const kContactEmail = 'aakashmangukiya10@gmail.com';

Future<void> openContactEmail(BuildContext context) async {
  final uri = Uri(
    scheme: 'mailto',
    path: kContactEmail,
    query: 'subject=${Uri.encodeComponent('Love Dots feedback')}',
  );
  Ads.I.skipNextResume();
  var ok = false;
  try {
    ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
  } catch (_) {}
  if (!ok) {
    Ads.I.onResumeHandled();
    await Clipboard.setData(const ClipboardData(text: kContactEmail));
    if (context.mounted) showToast(context, 'No email app found. Email address copied.');
  }
}

void showContact(BuildContext context) {
  showPopup(
    context,
    Material(
      color: Colors.transparent,
      child: PopupCard(
        title: 'Contact us',
        width: 520,
        height: 260,
        onClose: () => Navigator.of(context).pop(),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: s(26)),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Questions, ideas or found a bug? We would love to hear from you.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: s(15), color: const Color(0xFF666666))),
              SizedBox(height: s(18)),
              Tap(
                onTap: () => openContactEmail(context),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: s(16), vertical: s(10)),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE3F3F2),
                    borderRadius: BorderRadius.circular(s(24)),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.mail_rounded, color: C.tealBar, size: s(24)),
                    SizedBox(width: s(10)),
                    Text(kContactEmail,
                        style: TextStyle(
                            fontSize: s(17),
                            color: C.tealBar,
                            fontWeight: FontWeight.w600,
                            decoration: TextDecoration.underline,
                            decorationColor: C.tealBar)),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
