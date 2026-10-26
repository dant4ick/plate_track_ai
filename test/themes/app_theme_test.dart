import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plate_track_ai/core/themes/app_colors.dart';
import 'package:plate_track_ai/core/themes/app_theme.dart';

/// Pumps [theme] and hands back the palette a widget under it would resolve.
Future<AppPalette> paletteUnder(WidgetTester tester, ThemeData theme) async {
  late AppPalette palette;
  await tester.pumpWidget(
    MaterialApp(
      theme: theme,
      home: Builder(
        builder: (context) {
          palette = AppPalette.of(context);
          return const SizedBox();
        },
      ),
    ),
  );
  return palette;
}

void main() {
  for (final entry in {
    'light': AppTheme.lightTheme,
    'dark': AppTheme.darkTheme,
    'pick-me': AppTheme.pickMeTheme,
  }.entries) {
    testWidgets('calories use fixed pink and neutral fills in ${entry.key}', (
      tester,
    ) async {
      final palette = await paletteUnder(tester, entry.value);
      final style = palette.styleOf(Macro.calories);
      expect(style.graphic, const Color(0xFFFF3372));
      expect(style.ink, const Color(0xFFFF3372));
      expect(style.fill, entry.value.colorScheme.surface);
    });

    testWidgets('macros use the designer colours in ${entry.key}', (
      tester,
    ) async {
      final palette = await paletteUnder(tester, entry.value);
      expect(palette.styleOf(Macro.protein).graphic, const Color(0xFFFF7777));
      expect(palette.styleOf(Macro.carbs).graphic, const Color(0xFFFFCC77));
      expect(palette.styleOf(Macro.fat).graphic, const Color(0xFFAF5BD0));
      for (final macro in [Macro.protein, Macro.carbs, Macro.fat]) {
        final style = palette.styleOf(macro);
        expect(style.ink, style.graphic);
        expect(style.fill, entry.value.colorScheme.surface);
      }
    });
  }

  test('dark page background matches the design', () {
    expect(AppTheme.darkTheme.scaffoldBackgroundColor, const Color(0xFF1A191F));
  });

  test('dark cards use the requested surface without a Material tint', () {
    const surface = Color(0xFF262A35);
    expect(AppTheme.darkTheme.colorScheme.surface, surface);
    expect(AppTheme.darkTheme.cardTheme.color, surface);
    expect(AppTheme.darkTheme.cardTheme.surfaceTintColor, Colors.transparent);
    expect(AppTheme.lightTheme.cardTheme.color, const Color(0xFFFFFFFF));
    expect(AppTheme.pickMeTheme.cardTheme.color, const Color(0xFFFFFFFF));
  });

  test('all themes share green primary with their own secondary', () {
    const lime = Color(0xFFB0DD4E);
    for (final theme in [
      AppTheme.lightTheme,
      AppTheme.darkTheme,
      AppTheme.pickMeTheme,
    ]) {
      expect(theme.colorScheme.primary, lime);
      expect(theme.floatingActionButtonTheme.backgroundColor, lime);
      expect(
        theme.elevatedButtonTheme.style!.backgroundColor!.resolve({}),
        lime,
      );
      expect(theme.colorScheme.onPrimary, AppColors.onAccentDark);
    }
    expect(AppTheme.lightTheme.colorScheme.secondary, AppColors.prime);
    expect(AppTheme.darkTheme.colorScheme.secondary, AppColors.prime);
    expect(AppTheme.pickMeTheme.colorScheme.secondary, AppColors.pick);
  });

  for (final entry in {
    'light': AppTheme.lightTheme,
    'dark': AppTheme.darkTheme,
    'pick-me': AppTheme.pickMeTheme,
  }.entries) {
    test(
      '${entry.key} default typography uses the active primary text colour',
      () {
        final theme = entry.value;
        for (final style in [
          theme.textTheme.displayLarge,
          theme.textTheme.displayMedium,
          theme.textTheme.displaySmall,
          theme.textTheme.headlineLarge,
          theme.textTheme.headlineMedium,
          theme.textTheme.headlineSmall,
          theme.textTheme.titleLarge,
          theme.textTheme.titleMedium,
          theme.textTheme.titleSmall,
          theme.textTheme.bodyLarge,
          theme.textTheme.bodyMedium,
          theme.textTheme.bodySmall,
          theme.textTheme.labelLarge,
          theme.textTheme.labelMedium,
          theme.textTheme.labelSmall,
        ]) {
          expect(style!.color, theme.colorScheme.onSurface);
        }
      },
    );

    test('${entry.key} filled controls have readable foregrounds', () {
      final theme = entry.value;
      final scheme = theme.colorScheme;
      for (final pair in [
        (scheme.onPrimary, scheme.primary),
        (scheme.onSecondary, scheme.secondary),
        (scheme.onTertiary, scheme.tertiary),
        (scheme.onError, scheme.error),
        (
          theme.floatingActionButtonTheme.foregroundColor!,
          theme.floatingActionButtonTheme.backgroundColor!,
        ),
        (
          theme.elevatedButtonTheme.style!.foregroundColor!.resolve({})!,
          theme.elevatedButtonTheme.style!.backgroundColor!.resolve({})!,
        ),
      ]) {
        expect(_contrast(pair.$1, pair.$2), greaterThanOrEqualTo(4.5));
      }
    });

    testWidgets('${entry.key} advice accent is readable on its tinted tile', (
      tester,
    ) async {
      final palette = await paletteUnder(tester, entry.value);
      final tile = Color.alphaBlend(
        palette.fillOf(palette.accentInk),
        entry.value.colorScheme.surface,
      );
      expect(_contrast(palette.accentInk, tile), greaterThanOrEqualTo(3));
      for (final macro in Macro.values) {
        final style = palette.styleOf(macro);
        expect(
          _contrast(palette.foregroundOn(style.graphic), style.graphic),
          greaterThanOrEqualTo(4.5),
        );
        // Nutrition colours are fixed, not contrast-adjusted shades.
        expect(style.ink, style.graphic);
      }
    });
  }

  group('AppPalette flavor resolution', () {
    testWidgets('light theme resolves the light flavor', (tester) async {
      final palette = await paletteUnder(tester, AppTheme.lightTheme);

      expect(palette.flavor, AppFlavor.light);
      expect(palette.isDark, isFalse);
      expect(palette.calories, const Color(0xFFFF3372));
    });

    testWidgets('dark theme resolves the dark flavor', (tester) async {
      final palette = await paletteUnder(tester, AppTheme.darkTheme);

      expect(palette.flavor, AppFlavor.dark);
      expect(palette.isDark, isTrue);
      expect(palette.calories, const Color(0xFFFF3372));
    });

    testWidgets('pick-me theme is told apart from light despite sharing '
        'a brightness', (tester) async {
      final palette = await paletteUnder(tester, AppTheme.pickMeTheme);

      expect(palette.flavor, AppFlavor.pickMe);
      expect(palette.isDark, isFalse);
      expect(palette.calories, const Color(0xFFFF3372));
    });

    testWidgets('pick-me inherits light values for tokens the pink frame '
        'does not restyle', (tester) async {
      final light = await paletteUnder(tester, AppTheme.lightTheme);
      final pickMe = await paletteUnder(tester, AppTheme.pickMeTheme);

      expect(pickMe.textSecondary, light.textSecondary);
      expect(pickMe.track, light.track);
      expect(pickMe.border, light.border);
      expect(pickMe.danger, light.danger);
    });

    testWidgets('an untagged theme falls back to brightness', (tester) async {
      final palette = await paletteUnder(
        tester,
        ThemeData(brightness: Brightness.dark),
      );

      expect(palette.flavor, AppFlavor.dark);
    });
  });

  group('pick-me theme surfaces', () {
    test('takes its colors from the pink design frame', () {
      final theme = AppTheme.pickMeTheme;

      expect(theme.colorScheme.secondary, AppColors.pick);
      expect(theme.scaffoldBackgroundColor, AppColors.scaffoldPick);
      expect(theme.colorScheme.primary, const Color(0xFFB0DD4E));
      expect(theme.scaffoldBackgroundColor, const Color(0xFFFFF6F9));
      expect(theme.appBarTheme.backgroundColor, Colors.transparent);
    });

    test('keeps the lime FAB with readable navigation icons', () {
      final theme = AppTheme.pickMeTheme;

      expect(
        theme.floatingActionButtonTheme.backgroundColor,
        AppColors.secondLight,
      );
      expect(theme.appBarTheme.iconTheme?.color, theme.colorScheme.onSurface);
    });
  });
}

double _contrast(Color foreground, Color background) {
  final ink = Color.alphaBlend(foreground, background).computeLuminance();
  final surface = background.computeLuminance();
  return ink > surface
      ? (ink + 0.05) / (surface + 0.05)
      : (surface + 0.05) / (ink + 0.05);
}
