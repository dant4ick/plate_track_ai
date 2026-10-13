import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plate_track_ai/core/themes/app_colors.dart';
import 'package:plate_track_ai/core/themes/app_theme.dart';
import 'package:plate_track_ai/core/themes/theme_controller.dart';
import 'package:plate_track_ai/shared/widgets/theme_switcher_button.dart';

void main() {
  setUp(() => themePreference.value = ThemePreference.system);

  group('ThemePreference → MaterialApp', () {
    test('system follows the OS across both themes', () {
      expect(ThemePreference.system.theme, AppTheme.lightTheme);
      expect(ThemePreference.system.mode, ThemeMode.system);
    });

    test('light and dark pin the mode so the OS cannot override them', () {
      expect(ThemePreference.light.theme, AppTheme.lightTheme);
      expect(ThemePreference.light.mode, ThemeMode.light);

      expect(ThemePreference.dark.theme, AppTheme.darkTheme);
      expect(ThemePreference.dark.mode, ThemeMode.dark);
    });

    test('pick-me rides on `theme` with the mode pinned light', () {
      expect(ThemePreference.pickMe.theme, AppTheme.pickMeTheme);
      expect(ThemePreference.pickMe.mode, ThemeMode.light);
    });

    test('pick-me survives a device set to dark', () {
      // The regression this guards: with mode left on system, a dark device
      // would resolve `darkTheme` and the pink theme would never show.
      expect(ThemePreference.pickMe.mode, isNot(ThemeMode.system));
    });
  });

  group('ThemeSwitcherButton', () {
    /// Mirrors how `PlateTrackApp` wires the notifier to `MaterialApp`.
    Widget harness() {
      return ValueListenableBuilder<ThemePreference>(
        valueListenable: themePreference,
        builder: (context, preference, _) => MaterialApp(
          theme: preference.theme,
          darkTheme: AppTheme.darkTheme,
          themeMode: preference.mode,
          home: const Scaffold(
            appBar: null,
            body: ThemeSwitcherButton(),
          ),
        ),
      );
    }

    testWidgets('selecting a theme repaints the app with it', (tester) async {
      await tester.pumpWidget(harness());

      await tester.tap(find.byType(ThemeSwitcherButton));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Pick me'));
      await tester.pumpAndSettle();

      expect(themePreference.value, ThemePreference.pickMe);

      final context = tester.element(find.byType(ThemeSwitcherButton));
      expect(AppPalette.of(context).flavor, AppFlavor.pickMe);
      expect(Theme.of(context).colorScheme.primary, AppColors.pick);
    });

    testWidgets('offers all four choices', (tester) async {
      await tester.pumpWidget(harness());

      await tester.tap(find.byType(ThemeSwitcherButton));
      await tester.pumpAndSettle();

      for (final label in ['System', 'Light', 'Dark', 'Pick me']) {
        expect(find.text(label), findsOneWidget, reason: 'missing $label');
      }
    });

    testWidgets('switching away from pick-me restores the light theme',
        (tester) async {
      themePreference.value = ThemePreference.pickMe;
      await tester.pumpWidget(harness());

      await tester.tap(find.byType(ThemeSwitcherButton));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Light'));
      await tester.pumpAndSettle();

      final context = tester.element(find.byType(ThemeSwitcherButton));
      expect(AppPalette.of(context).flavor, AppFlavor.light);
    });
  });
}
