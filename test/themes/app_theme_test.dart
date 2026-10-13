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
  group('AppPalette flavor resolution', () {
    testWidgets('light theme resolves the light flavor', (tester) async {
      final palette = await paletteUnder(tester, AppTheme.lightTheme);

      expect(palette.flavor, AppFlavor.light);
      expect(palette.isDark, isFalse);
      expect(palette.brandSoft, AppColors.secondSoft);
      expect(palette.calories, AppColors.calories);
    });

    testWidgets('dark theme resolves the dark flavor', (tester) async {
      final palette = await paletteUnder(tester, AppTheme.darkTheme);

      expect(palette.flavor, AppFlavor.dark);
      expect(palette.isDark, isTrue);
      expect(palette.brandSoft, AppColors.primeSoft);
      expect(palette.calories, AppColors.caloriesDark);
    });

    testWidgets('pick-me theme is told apart from light despite sharing '
        'a brightness', (tester) async {
      final palette = await paletteUnder(tester, AppTheme.pickMeTheme);

      expect(palette.flavor, AppFlavor.pickMe);
      expect(palette.isDark, isFalse);
      expect(palette.brandSoft, AppColors.pickSoft);
      expect(palette.calories, AppColors.pickCalories);
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
      final palette = await paletteUnder(tester, ThemeData(
        brightness: Brightness.dark,
      ));

      expect(palette.flavor, AppFlavor.dark);
    });
  });

  group('pick-me theme surfaces', () {
    test('takes its colors from the pink design frame', () {
      final theme = AppTheme.pickMeTheme;

      expect(theme.colorScheme.primary, AppColors.pick);
      expect(theme.scaffoldBackgroundColor, AppColors.scaffoldPick);
      expect(theme.appBarTheme.backgroundColor, Colors.transparent);
    });

    test('keeps the lime FAB and app-bar icons from the frame', () {
      final theme = AppTheme.pickMeTheme;

      expect(
        theme.floatingActionButtonTheme.backgroundColor,
        AppColors.secondShade,
      );
      expect(theme.appBarTheme.iconTheme?.color, AppColors.secondShade);
    });
  });
}
