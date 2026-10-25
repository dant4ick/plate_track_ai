import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:plate_track_ai/core/themes/app_theme.dart';
import 'package:plate_track_ai/shared/widgets/app_logo.dart';

void main() {
  test('launcher images keep the blue identity and adaptive transparency', () {
    final paths = [
      'assets/icons/app_icon_color.png',
      for (final density in ['mdpi', 'hdpi', 'xhdpi', 'xxhdpi', 'xxxhdpi'])
        'android/app/src/main/res/mipmap-$density/ic_launcher.png',
    ];
    for (final path in paths) {
      final image = img.decodePng(File(path).readAsBytesSync())!;
      expect(image.width, image.height, reason: path);
      for (final pixel in [
        image.getPixel(0, 0),
        image.getPixel(image.width ~/ 2, image.height ~/ 2),
      ]) {
        // The launcher package's resize can round an RGB channel by one.
        final tolerance = path.startsWith('assets/') ? 0 : 1;
        expect(pixel.r, closeTo(77, tolerance), reason: path);
        expect(pixel.g, closeTo(85, tolerance), reason: path);
        expect(pixel.b, closeTo(245, tolerance), reason: path);
        expect(pixel.a, 255, reason: path);
      }
    }
    final foreground = img.decodePng(
      File('assets/icons/app_icon_foreground.png').readAsBytesSync(),
    )!;
    expect(foreground.width, 1024);
    expect(foreground.getPixel(0, 0).a, 0);
    expect(foreground.getPixel(512, 512).a, 0);
  });

  test(
    'generated tiles preserve every path and fill from the Figma export',
    () {
      List<String> paths(String svg) =>
          RegExp(r'<path\s+d="[^"]+"\s+fill="[^"]+"\s*/>')
              .allMatches(svg)
              .map((match) => match[0]!.replaceAll(' />', '/>'))
              .toList();

      final source = paths(
        File('tool/branding/designer_logos.svg').readAsStringSync(),
      );
      expect(source, hasLength(15));
      final assets = [
        'assets/icons/app_icon_color.svg',
        'assets/icons/app_icon_light.svg',
        'assets/icons/app_icon_pick_me.svg',
      ];
      for (var index = 0; index < assets.length; index++) {
        expect(
          paths(File(assets[index]).readAsStringSync()),
          source.sublist(index * 5, index * 5 + 5),
          reason: assets[index],
        );
      }
      expect(
        paths(File('assets/icons/app_icon.svg').readAsStringSync()),
        source.sublist(1, 5),
      );
    },
  );

  for (final entry in {
    'light': (AppTheme.lightTheme, 'assets/icons/app_icon_light.svg'),
    'pick me': (AppTheme.pickMeTheme, 'assets/icons/app_icon_pick_me.svg'),
  }.entries) {
    testWidgets('${entry.key} theme uses its exact Figma tile', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: entry.value.$1,
          home: const Center(child: AppLogoMark(size: 154)),
        ),
      );
      await tester.pumpAndSettle();

      final picture = tester.widget<SvgPicture>(find.byType(SvgPicture));
      expect((picture.bytesLoader as SvgAssetLoader).assetName, entry.value.$2);
      expect(picture.colorFilter, isNull);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('dark theme uses the unmodified blue designer tile', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: const Center(child: AppLogoMark(size: 154)),
      ),
    );
    await tester.pumpAndSettle();

    final picture = tester.widget<SvgPicture>(find.byType(SvgPicture));
    expect(
      (picture.bytesLoader as SvgAssetLoader).assetName,
      'assets/icons/app_icon_color.svg',
    );
    expect(picture.colorFilter, isNull);
    expect(picture.width, 154);
    expect(picture.height, 154);
    expect(tester.takeException(), isNull);
  });

  testWidgets('mark follows theme changes without a stale colour filter', (
    tester,
  ) async {
    final theme = ValueNotifier(AppTheme.darkTheme);
    addTearDown(theme.dispose);
    await tester.pumpWidget(
      ValueListenableBuilder<ThemeData>(
        valueListenable: theme,
        builder: (context, theme, _) => MaterialApp(
          theme: theme,
          home: const Center(child: AppLogoMark()),
        ),
      ),
    );
    await tester.pumpAndSettle();
    theme.value = AppTheme.pickMeTheme;
    await tester.pumpAndSettle();

    final picture = tester.widget<SvgPicture>(find.byType(SvgPicture));
    expect(
      (picture.bytesLoader as SvgAssetLoader).assetName,
      'assets/icons/app_icon_pick_me.svg',
    );
    expect(picture.colorFilter, isNull);
    expect(tester.takeException(), isNull);
  });
}
