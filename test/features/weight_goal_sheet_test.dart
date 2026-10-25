import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plate_track_ai/core/themes/app_theme.dart';
import 'package:plate_track_ai/features/dashboard/weight_goal_sheet.dart';
import '../color_test_utils.dart';

Future<void> pumpSheet(
  WidgetTester tester, {
  double? minimumGoal,
  ThemeData? theme,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: theme ?? AppTheme.lightTheme,
      home: Scaffold(
        body: WeightGoalSheet(
          weight: 70,
          goalWeight: 60,
          minimumGoal: minimumGoal,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Finder goalField() => find.widgetWithText(TextFormField, 'goal_weight');

void main() {
  for (final theme in [
    AppTheme.lightTheme,
    AppTheme.darkTheme,
    AppTheme.pickMeTheme,
  ]) {
    testWidgets(
      'weight suffix remains readable on ${theme.colorScheme.primary}',
      (tester) async {
        await pumpSheet(tester, theme: theme);
        await tester.tap(goalField());
        await tester.pumpAndSettle();
        final suffixes = tester
            .widgetList<RichText>(find.byType(RichText))
            .where((w) => w.text.toPlainText() == 'kg')
            .toList();
        expect(suffixes, isNotEmpty);
        for (final suffix in suffixes) {
          expect(
            contrastOn(
              suffix.text.style!.color!,
              theme.inputDecorationTheme.fillColor!,
            ),
            greaterThanOrEqualTo(4.5),
          );
        }
      },
    );
  }
  group('WeightGoalSheet minimum goal', () {
    testWidgets('rejects a goal below the healthy minimum', (tester) async {
      await pumpSheet(tester, minimumGoal: 53.5);

      await tester.enterText(goalField(), '45');
      await tester.tap(find.text('save'));
      await tester.pumpAndSettle();

      expect(find.text('goal_weight_below_minimum'), findsOneWidget);
    });

    testWidgets('accepts a goal at the minimum', (tester) async {
      await pumpSheet(tester, minimumGoal: 53.5);

      await tester.enterText(goalField(), '53.5');
      await tester.tap(find.text('save'));
      await tester.pumpAndSettle();

      expect(find.text('goal_weight_below_minimum'), findsNothing);
    });

    testWidgets('does not bound the goal when no minimum is given', (
      tester,
    ) async {
      await pumpSheet(tester);

      await tester.enterText(goalField(), '45');
      await tester.tap(find.text('save'));
      await tester.pumpAndSettle();

      expect(find.text('goal_weight_below_minimum'), findsNothing);
      expect(find.text('please_enter_valid_goal_weight'), findsNothing);
    });
  });
}
