import 'package:flutter_test/flutter_test.dart';
import 'package:love_dots/core/l10n.dart';

void main() {
  test('all 7 languages translate every text', () {
    expect(kLanguages, ['en', 'zh', 'fr', 'de', 'ja', 'ko', 'es']);
    final keys = allStrings['en']!.keys.toSet();
    for (final lang in kLanguages) {
      final have = allStrings[lang]!.keys.toSet();
      expect(keys.difference(have), isEmpty, reason: '$lang is missing translations');
      expect(have.difference(keys), isEmpty, reason: '$lang has unknown keys');
      for (final k in keys) {
        expect(allStrings[lang]![k]!.trim(), isNotEmpty, reason: '$lang/$k is empty');
        expect(allStrings[lang]![k]!.contains('{n}'), allStrings['en']![k]!.contains('{n}'),
            reason: '$lang/$k placeholder mismatch');
      }
    }
  });

  test('the language button cycles through all languages and back', () {
    var lang = 'en';
    final seen = <String>[];
    for (var i = 0; i < kLanguages.length; i++) {
      seen.add(lang);
      lang = nextLanguage(lang);
    }
    expect(seen, kLanguages);
    expect(lang, 'en');
  });
}
