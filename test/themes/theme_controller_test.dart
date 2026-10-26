import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plate_track_ai/core/themes/app_colors.dart';
import 'package:plate_track_ai/core/themes/app_theme.dart';
import 'package:plate_track_ai/core/themes/theme_controller.dart';
import 'package:plate_track_ai/shared/widgets/theme_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  group('ThemePicker', () {
    /// Mirrors how `PlateTrackApp` wires the notifier to `MaterialApp`.
    Widget harness() {
      return ValueListenableBuilder<ThemePreference>(
        valueListenable: themePreference,
        builder: (context, preference, _) => MaterialApp(
          theme: preference.theme,
          darkTheme: AppTheme.darkTheme,
          themeMode: preference.mode,
          home: const Scaffold(
            body: SingleChildScrollView(child: ThemePicker()),
          ),
        ),
      );
    }

    testWidgets('selecting a theme repaints the app with it', (tester) async {
      await tester.pumpWidget(harness());

      await tester.tap(find.text('Pick me'));
      await tester.pumpAndSettle();

      expect(themePreference.value, ThemePreference.pickMe);

      final context = tester.element(find.byType(ThemePicker));
      expect(AppPalette.of(context).flavor, AppFlavor.pickMe);
      expect(Theme.of(context).colorScheme.primary, AppColors.secondLight);
      expect(Theme.of(context).colorScheme.secondary, AppColors.pick);
    });

    testWidgets('offers all four choices with the active one selected', (
      tester,
    ) async {
      await tester.pumpWidget(harness());

      // Keys come back untranslated without EasyLocalization in the tree.
      for (final label in [
        'theme_system',
        'theme_light',
        'theme_dark',
        'Pick me',
      ]) {
        expect(find.text(label), findsOneWidget, reason: 'missing $label');
      }

      final system = tester.widget<RadioListTile<ThemePreference>>(
        find.widgetWithText(RadioListTile<ThemePreference>, 'theme_system'),
      );
      expect(system.value, ThemePreference.system);
    });

    testWidgets('switching away from pick-me restores the light theme', (
      tester,
    ) async {
      themePreference.value = ThemePreference.pickMe;
      await tester.pumpWidget(harness());

      await tester.tap(find.text('theme_light'));
      await tester.pumpAndSettle();

      final context = tester.element(find.byType(ThemePicker));
      expect(AppPalette.of(context).flavor, AppFlavor.light);
    });
  });

  group('initThemePreference', () {
    test('restores a stored choice', () async {
      SharedPreferences.setMockInitialValues({'theme_preference': 'pickMe'});

      await initThemePreference();

      expect(themePreference.value, ThemePreference.pickMe);
    });

    test('falls back to system for an unrecognised stored value', () async {
      SharedPreferences.setMockInitialValues({'theme_preference': 'sepia'});

      await initThemePreference();

      expect(themePreference.value, ThemePreference.system);
    });

    test('persists a change for the next launch', () async {
      SharedPreferences.setMockInitialValues({});
      await initThemePreference();

      themePreference.value = ThemePreference.dark;
      // The listener writes asynchronously; give it a turn of the loop.
      await Future<void>.delayed(Duration.zero);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('theme_preference'), 'dark');

      // A fresh init — as on next launch — lands on the stored choice.
      await initThemePreference();
      expect(themePreference.value, ThemePreference.dark);
    });
  });
}
