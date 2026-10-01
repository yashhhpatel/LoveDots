import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../art/palette.dart';
import '../core/ads.dart';
import '../core/audio.dart';
import '../core/l10n.dart';
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
  bool _switching = false;

  /// Like the reference game: each tap moves to the next language, with a
  /// short "Loading..." while the texts change.
  Future<void> _nextLanguage() async {
    if (_switching) return;
    setState(() => _switching = true);
    await Future.delayed(const Duration(milliseconds: 650));
    Save.I.update(() => Save.I.lang = nextLanguage(Save.I.lang));
    if (mounted) setState(() => _switching = false);
  }

  @override
  Widget build(BuildContext context) {
    final save = Save.I;
    final items = <(IconData, String, bool, VoidCallback)>[
      (
        save.sound ? Icons.volume_up_rounded : Icons.volume_off_rounded,
        tr('sounds'),
        save.sound,
        () {
          save.update(() => save.sound = !save.sound);
          if (!save.sound) Audio.I.stopDraw();
          setState(() {});
        }
      ),
      (
        Icons.music_note_rounded,
        tr('music'),
        save.music,
        () {
          save.update(() => save.music = !save.music);
          Audio.I.refreshMusic();
          setState(() {});
        }
      ),
      (
        Icons.vibration_rounded,
        tr('vibration'),
        save.vibration,
        () {
          save.update(() => save.vibration = !save.vibration);
          Audio.I.vibrate();
          setState(() {});
        }
      ),
      (
        Icons.leaderboard_rounded,
        tr('leaderboard'),
        true,
        () => showLeaderboard(context)
      ),
      (
        Icons.question_mark_rounded,
        tr('help'),
        true,
        () => showPopup(context, const HelpDialog())
      ),
      (Icons.mail_rounded, tr('contact'), true, () => showContact(context)),
      (
        Icons.privacy_tip_rounded,
        tr('privacy'),
        true,
        () => showPrivacy(context)
      ),
      (Icons.star_rounded, tr('langName'), true, _nextLanguage),
    ];
    return Material(
      color: Colors.transparent,
      child: Stack(children: [
        PopupCard(
          title: tr('settings'),
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
                            border: Border.all(
                                color: const Color(0xFFE3F3F2), width: s(4)),
                          ),
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color:
                                  it.$3 ? C.tealBar : const Color(0xFFB0B0B0),
                            ),
                            child:
                                Icon(it.$1, color: Colors.white, size: s(26)),
                          ),
                        ),
                        SizedBox(height: s(6)),
                        SizedBox(
                          width: s(110),
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(it.$2,
                                style: TextStyle(
                                    fontSize: s(14),
                                    color: const Color(0xFF555555))),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
        if (_switching)
          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.45),
              alignment: Alignment.center,
              child: Text(tr('loadingDots'),
                  style: TextStyle(color: Colors.white, fontSize: s(22))),
            ),
          ),
      ]),
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
        title: tr('leaderboard'),
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
                  style: TextStyle(
                      fontSize: s(30), color: const Color(0xFF444444))),
            ]),
            SizedBox(height: s(14)),
            Text(tr('levelsDone', done),
                style:
                    TextStyle(fontSize: s(17), color: const Color(0xFF666666))),
            SizedBox(height: s(6)),
            Text(tr('coinsN', save.coins),
                style:
                    TextStyle(fontSize: s(17), color: const Color(0xFF666666))),
          ],
        ),
      ),
    ),
  );
}

const kPrivacyPolicyUrl =
    'https://api.buildprivacypolicy.com/policy/c3fad6ce-15f4-4a7a-8bd2-fcf3f39b246e';

Future<void> openPrivacyPolicy(BuildContext context) async {
  Ads.I.skipNextResume();
  var ok = false;
  try {
    ok = await launchUrl(Uri.parse(kPrivacyPolicyUrl),
        mode: LaunchMode.externalApplication);
  } catch (_) {}
  if (!ok) {
    Ads.I.onResumeHandled();
    if (context.mounted) showToast(context, tr('browserFail'));
  }
}

/// Opens the privacy policy. Players in regions where Google's consent form
/// applies (EEA/UK) also get a way to change their ad consent.
Future<void> showPrivacy(BuildContext context) async {
  if (!await Ads.I.privacyOptionsRequired()) {
    if (context.mounted) await openPrivacyPolicy(context);
    return;
  }
  if (!context.mounted) return;
  showPopup(
    context,
    Material(
      color: Colors.transparent,
      child: PopupCard(
        title: tr('privacy'),
        width: 460,
        height: 250,
        onClose: () => Navigator.of(context).pop(),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Pill(tr('privacyPolicy'),
                color: C.tealBar,
                width: 260,
                height: 40,
                font: 16,
                onTap: () => openPrivacyPolicy(context)),
            SizedBox(height: s(16)),
            Pill(tr('adPrivacy'),
                color: C.blueBtn,
                width: 260,
                height: 40,
                font: 16,
                onTap: Ads.I.showPrivacyOptions),
          ],
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
    if (context.mounted) showToast(context, tr('noEmailApp'));
  }
}

void showContact(BuildContext context) {
  showPopup(
    context,
    Material(
      color: Colors.transparent,
      child: PopupCard(
        title: tr('contact'),
        width: 520,
        height: 260,
        onClose: () => Navigator.of(context).pop(),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: s(26)),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(tr('contactBody'),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: s(15), color: const Color(0xFF666666))),
              SizedBox(height: s(18)),
              Tap(
                onTap: () => openContactEmail(context),
                child: Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: s(16), vertical: s(10)),
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
