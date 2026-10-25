import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plate_track_ai/core/themes/app_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'bundled faces cover both alphabets and every translated letter',
    () async {
      final required = <int>{
        ...'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789'
            .runes,
        ...'АБВГДЕЁЖЗИЙКЛМНОПРСТУФХЦЧШЩЪЫЬЭЮЯ'.runes,
        ...'абвгдеёжзийклмнопрстуфхцчшщъыьэюя'.runes,
      };
      final letter = RegExp(r'\p{L}', unicode: true);
      for (final locale in ['en', 'ru']) {
        final translations = jsonDecode(
          await rootBundle.loadString('assets/translations/$locale.json'),
        );
        for (final text in _strings(translations)) {
          required.addAll(
            text.runes.where(
              (rune) => letter.hasMatch(String.fromCharCode(rune)),
            ),
          );
        }
      }
      final loader = FontLoader(AppTheme.fontFamily);
      for (final face in [
        'Regular',
        'Italic',
        'Medium',
        'MediumItalic',
        'SemiBold',
        'SemiBoldItalic',
        'Bold',
        'BoldItalic',
      ]) {
        final font = await rootBundle.load(
          'assets/fonts/Montserrat/Montserrat-$face.ttf',
        );
        final missing = required.difference(_codePoints(font));
        expect(
          missing,
          isEmpty,
          reason: '$face lacks ${String.fromCharCodes(missing)}',
        );
        loader.addFont(Future.value(font));
      }
      await loader.load();
      expect(
        await rootBundle.loadString('assets/fonts/Montserrat/OFL.txt'),
        contains('SIL OPEN FONT LICENSE'),
      );
    },
  );

  for (final theme in {
    'light': AppTheme.lightTheme,
    'dark': AppTheme.darkTheme,
    'pick-me': AppTheme.pickMeTheme,
  }.entries) {
    for (final locale in [const Locale('en'), const Locale('ru')]) {
      testWidgets(
        '${theme.key}: ${locale.languageCode} text shares one family',
        (tester) async {
          final sample = locale.languageCode == 'ru'
              ? 'Ваш профиль — Ёё'
              : 'Your profile';
          await tester.pumpWidget(
            MaterialApp(
              theme: theme.value,
              locale: locale,
              supportedLocales: const [Locale('en'), Locale('ru')],
              localizationsDelegates: GlobalMaterialLocalizations.delegates,
              home: Builder(
                builder: (context) => Localizations.override(
                  context: context,
                  locale: locale,
                  child: Scaffold(
                    appBar: AppBar(title: Text(sample)),
                    body: Column(
                      children: [
                        Text(sample),
                        ElevatedButton(onPressed: () {}, child: Text(sample)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          for (final element in find.text(sample).evaluate()) {
            expect(Localizations.localeOf(element), locale);
            final richText = tester.widget<RichText>(
              find.descendant(
                of: find.byWidget(element.widget),
                matching: find.byType(RichText),
              ),
            );
            expect(richText.text.style!.fontFamily, 'Montserrat');
          }
          expect(
            theme.value.primaryTextTheme.bodyMedium!.fontFamily,
            'Montserrat',
          );
          expect(
            theme.value.appBarTheme.titleTextStyle!.fontFamily,
            'Montserrat',
          );
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
}

Iterable<String> _strings(dynamic value) sync* {
  if (value is String) {
    yield value;
  } else if (value is Map) {
    for (final child in value.values) {
      yield* _strings(child);
    }
  } else if (value is List) {
    for (final child in value) {
      yield* _strings(child);
    }
  }
}

/// Read the Unicode cmap rather than inferring coverage from rendered fallback.
Set<int> _codePoints(ByteData data) {
  int u16(int offset) => data.getUint16(offset);
  int u32(int offset) => data.getUint32(offset);
  int? cmap;
  for (var i = 0; i < u16(4); i++) {
    final offset = 12 + i * 16;
    if (u32(offset) == 0x636d6170) cmap = u32(offset + 8);
  }
  if (cmap == null) throw StateError('Font has no cmap');
  final points = <int>{};
  for (var i = 0; i < u16(cmap + 2); i++) {
    final offset = cmap + 4 + i * 8;
    final platform = u16(offset);
    final encoding = u16(offset + 2);
    if (platform != 0 &&
        !(platform == 3 && (encoding == 1 || encoding == 10))) {
      continue;
    }
    final table = cmap + u32(offset + 4);
    final format = u16(table);
    if (format == 12) {
      for (var j = 0; j < u32(table + 12); j++) {
        final group = table + 16 + j * 12;
        final start = u32(group);
        final end = u32(group + 4);
        final glyph = u32(group + 8);
        for (var cp = start; cp <= end; cp++) {
          if (glyph + cp - start != 0) points.add(cp);
        }
      }
    } else if (format == 4) {
      final count = u16(table + 6) ~/ 2;
      final ends = table + 14;
      final starts = ends + count * 2 + 2;
      final deltas = starts + count * 2;
      final offsets = deltas + count * 2;
      for (var j = 0; j < count; j++) {
        final start = u16(starts + j * 2);
        final end = u16(ends + j * 2);
        final delta = data.getInt16(deltas + j * 2);
        final range = u16(offsets + j * 2);
        for (var cp = start; cp <= end && cp < 0xffff; cp++) {
          var glyph = range == 0
              ? (cp + delta) & 0xffff
              : u16(offsets + j * 2 + range + (cp - start) * 2);
          if (range != 0 && glyph != 0) glyph = (glyph + delta) & 0xffff;
          if (glyph != 0) points.add(cp);
        }
      }
    }
  }
  return points;
}
