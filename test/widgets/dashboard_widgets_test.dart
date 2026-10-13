import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plate_track_ai/core/themes/app_colors.dart';
import 'package:plate_track_ai/core/themes/app_theme.dart';
import 'package:plate_track_ai/shared/widgets/common_widgets.dart';
import 'package:plate_track_ai/shared/widgets/calorie_gauge.dart';
import 'package:plate_track_ai/shared/widgets/macro_bars.dart';
import 'package:plate_track_ai/shared/widgets/macro_chip.dart';
import 'package:plate_track_ai/shared/widgets/progress_ring.dart';
import 'package:plate_track_ai/shared/widgets/weight_card.dart';

/// Pumps [child] inside the real app theme at a given surface width, so layout
/// overflow in the new painters and rows fails the test rather than only showing
/// up on a device.
Future<void> pumpInApp(
  WidgetTester tester,
  Widget child, {
  double width = 360,
  ThemeData? theme,
}) async {
  tester.view.physicalSize = Size(width, 800);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(
      theme: theme ?? AppTheme.lightTheme,
      home: Scaffold(
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: child,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  _contrastGuards();

  group('CalorieGauge', () {
    testWidgets('shows what is left when under the target', (tester) async {
      await pumpInApp(tester, const CalorieGauge(consumed: 1500, target: 2000));

      expect(find.text('500'), findsOneWidget);
      expect(find.text('calories_left'), findsOneWidget);
      expect(find.text('calories_over'), findsNothing);
    });

    testWidgets('flips to "over" past the target and stays positive', (
      tester,
    ) async {
      await pumpInApp(tester, const CalorieGauge(consumed: 2300, target: 2000));

      // 300 over, not -300.
      expect(find.text('300'), findsOneWidget);
      expect(find.text('calories_over'), findsOneWidget);
    });

    testWidgets('falls back to the raw total with no target', (tester) async {
      await pumpInApp(tester, const CalorieGauge(consumed: 900, target: 0));

      expect(find.text('900'), findsOneWidget);
      expect(find.text('calories_consumed'), findsOneWidget);
    });
  });

  group('MacroBars', () {
    testWidgets('prints every gram figure', (tester) async {
      await pumpInApp(
        tester,
        const MacroBars(
          macros: [
            MacroProgress(macro: Macro.protein, grams: 112, target: 150),
            MacroProgress(macro: Macro.carbs, grams: 98, target: 250),
            MacroProgress(macro: Macro.fat, grams: 44, target: 70),
          ],
        ),
      );

      expect(find.text('112g'), findsOneWidget);
      expect(find.text('98g'), findsOneWidget);
      expect(find.text('44g'), findsOneWidget);
    });

    test('fraction clamps and tolerates a zero target', () {
      const over = MacroProgress(macro: Macro.fat, grams: 100, target: 50);
      expect(over.fraction, 1.0);

      const noTarget = MacroProgress(macro: Macro.fat, grams: 100, target: 0);
      expect(noTarget.fraction, 0.0);
    });

    testWidgets('survives a narrow screen', (tester) async {
      await pumpInApp(
        tester,
        const MacroBars(
          macros: [
            MacroProgress(macro: Macro.protein, grams: 1112, target: 150),
            MacroProgress(macro: Macro.carbs, grams: 1098, target: 250),
            MacroProgress(macro: Macro.fat, grams: 1044, target: 70),
          ],
        ),
        width: 300,
      );

      expect(tester.takeException(), isNull);
    });
  });

  group('WeightCard', () {
    testWidgets('shows the start/current/goal triplet and the ring', (
      tester,
    ) async {
      await pumpInApp(
        tester,
        const WeightCard(current: 67, start: 70, goal: 50, progress: 0.15),
      );

      expect(find.text('70'), findsOneWidget);
      expect(find.text('67'), findsOneWidget);
      expect(find.text('50'), findsOneWidget);
      expect(find.text('15%'), findsOneWidget);
      expect(find.byType(ProgressRing), findsOneWidget);
    });

    testWidgets('drops the ring and invites a goal when none is set', (
      tester,
    ) async {
      await pumpInApp(tester, const WeightCard(current: 70));

      expect(find.byType(ProgressRing), findsNothing);
      expect(find.text('goal_weight_hint'), findsOneWidget);
      expect(find.text('start'), findsNothing);
    });

    testWidgets('keeps a half kilo but trims a whole one', (tester) async {
      await pumpInApp(
        tester,
        const WeightCard(current: 67.5, start: 70, goal: 50, progress: 0.125),
      );

      expect(find.text('67.5'), findsOneWidget);
      expect(find.text('70'), findsOneWidget);
    });

    testWidgets('sits the three figures on one shared baseline', (
      tester,
    ) async {
      await pumpInApp(
        tester,
        const WeightCard(current: 67, start: 70, goal: 50, progress: 0.15),
      );

      double baselineOf(String text) {
        final box = tester.renderObject<RenderBox>(find.text(text));
        // getDistanceToBaseline is guarded to the layout and paint phases. This
        // flag is the escape hatch Flutter's own render tests use to query it
        // from a settled tree; nothing here mutates layout.
        RenderObject.debugCheckingIntrinsics = true;
        final distance = box.getDistanceToBaseline(TextBaseline.alphabetic)!;
        RenderObject.debugCheckingIntrinsics = false;
        return box.localToGlobal(Offset(0, distance)).dy;
      }

      // The design rests 70, 67 and 50 on a single line despite the middle
      // figure being far larger. Stacking a Column per figure aligns the column
      // boxes instead and lets the small numbers float above the large one.
      expect(baselineOf('70'), closeTo(baselineOf('67'), 0.5));
      expect(baselineOf('50'), closeTo(baselineOf('67'), 0.5));
    });

    testWidgets('puts the captions below the figures, not beside them', (
      tester,
    ) async {
      await pumpInApp(
        tester,
        const WeightCard(current: 67, start: 70, goal: 50, progress: 0.15),
      );

      expect(
        tester.getTopLeft(find.text('start')).dy,
        greaterThan(tester.getBottomLeft(find.text('70')).dy - 4),
      );
      // And each caption stays under its own figure.
      expect(
        tester.getCenter(find.text('start')).dx,
        closeTo(tester.getCenter(find.text('70')).dx, 12),
      );
      expect(
        tester.getCenter(find.text('goal_lower')).dx,
        closeTo(tester.getCenter(find.text('50')).dx, 12),
      );
    });

    testWidgets('fires onTap', (tester) async {
      var tapped = false;
      await pumpInApp(
        tester,
        WeightCard(
          current: 67,
          start: 70,
          goal: 50,
          progress: 0.15,
          onTap: () => tapped = true,
        ),
      );

      await tester.tap(find.byType(WeightCard));
      expect(tapped, isTrue);
    });

    for (final entry in {
      'light': AppTheme.lightTheme,
      'dark': AppTheme.darkTheme,
      'pick-me': AppTheme.pickMeTheme,
    }.entries) {
      testWidgets('lays out on a narrow screen — ${entry.key}', (tester) async {
        await pumpInApp(
          tester,
          const WeightCard(
            current: 167.5,
            start: 170.5,
            goal: 150.5,
            progress: 0.15,
          ),
          width: 300,
          theme: entry.value,
        );

        expect(tester.takeException(), isNull);
      });
    }
  });

  group('MacroChip', () {
    testWidgets('labels the macro and rounds the grams', (tester) async {
      await pumpInApp(
        tester,
        const Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            MacroChip(macro: Macro.protein, grams: 32.4),
            MacroChip(macro: Macro.carbs, grams: 23),
            MacroChip(macro: Macro.fat, grams: 19.6),
          ],
        ),
      );

      expect(find.text('protein_short: 32g'), findsOneWidget);
      expect(find.text('carbs_short: 23g'), findsOneWidget);
      expect(find.text('fat_short: 20g'), findsOneWidget);
    });
  });

  group('AppPalette.styleOf', () {
    for (final entry in {
      AppTheme.lightTheme: false,
      AppTheme.darkTheme: true,
    }.entries) {
      testWidgets(
        'pairs each macro ink with its own fill (dark=${entry.value})',
        (tester) async {
          late AppPalette palette;
          await tester.pumpWidget(
            MaterialApp(
              theme: entry.key,
              home: Builder(
                builder: (context) {
                  palette = AppPalette.of(context);
                  return const SizedBox();
                },
              ),
            ),
          );

          expect(palette.isDark, entry.value);
          for (final macro in Macro.values) {
            final style = palette.styleOf(macro);
            expect(style.ink, isNot(style.fill));
            expect(style.ink, isNot(style.graphic));
          }
        },
      );
    }
  });
}

/// Guards the pairing that broke on device: a secondary AppButton took the
/// scheme's secondary as its background but kept the theme's white foreground,
/// which on the lime secondary is 1.13:1.
void _contrastGuards() {
  group('AppButton foreground pairing', () {
    for (final entry in {
      'light': AppTheme.lightTheme,
      'dark': AppTheme.darkTheme,
      'pick-me': AppTheme.pickMeTheme,
    }.entries) {
      testWidgets('secondary button clears 4.5:1 — ${entry.key}', (
        tester,
      ) async {
        await pumpInApp(
          tester,
          AppButton(text: 'Go', onPressed: () {}, isSecondary: true),
          theme: entry.value,
        );

        final button = tester.widget<ElevatedButton>(
          find.byType(ElevatedButton),
        );
        const states = <WidgetState>{};
        final bg = button.style!.backgroundColor!.resolve(states)!;
        final fg = button.style!.foregroundColor!.resolve(states)!;

        expect(
          _contrast(fg, bg),
          greaterThanOrEqualTo(4.5),
          reason: '${entry.key}: $fg on $bg',
        );
      });
    }
  });
}

double _channel(double c) =>
    c <= 0.03928 ? c / 12.92 : math.pow((c + 0.055) / 1.055, 2.4).toDouble();

double _luminance(Color c) =>
    0.2126 * _channel(c.r) + 0.7152 * _channel(c.g) + 0.0722 * _channel(c.b);

double _contrast(Color a, Color b) {
  final la = _luminance(a), lb = _luminance(b);
  final hi = math.max(la, lb), lo = math.min(la, lb);
  return (hi + 0.05) / (lo + 0.05);
}
