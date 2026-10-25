import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plate_track_ai/features/nutrition_stats/nutrition_macro_breakdown.dart';
import 'package:plate_track_ai/features/nutrition_stats/nutrition_summary.dart';
import 'package:plate_track_ai/shared/widgets/soft_card.dart';

import '../test_utils.dart';
import 'localized_pump.dart';

void main() {
  setUpAll(initLocalization);

  testWidgets('amounts remain honest above the goal and without a profile', (
    tester,
  ) async {
    final now = DateTime(2026, 10, 25);
    final bucket = NutritionSummary.fromItems(
      [
        TestDataFactory.createFoodItem(
          timestamp: now,
          protein: 250,
          fat: 35,
          carbs: 0,
        ),
      ],
      period: NutritionPeriod.day,
      now: now,
    ).buckets.last;
    await pumpLocalized(
      tester,
      Scaffold(
        body: SingleChildScrollView(
          child: Column(
            children: [
              SoftCard(
                child: NutritionMacroBreakdown(
                  bucket: bucket,
                  period: NutritionPeriod.day,
                  targets: const {'protein': 100, 'fat': 70, 'carbs': 300},
                ),
              ),
              SoftCard(
                child: NutritionMacroBreakdown(
                  bucket: bucket,
                  period: NutritionPeriod.week,
                ),
              ),
            ],
          ),
        ),
      ),
      size: const Size(600, 1100),
    );
    expect(find.text('250 / 100 g'), findsOneWidget);
    expect(find.text('35 / 70 g'), findsOneWidget);
    expect(find.text('0 / 300 g'), findsOneWidget);
    expect(find.text('250 g'), findsOneWidget);
    expect(find.text('Daily average'), findsOneWidget);
    // Full, half and empty tracks; no invented target without a profile.
    expect(
      tester
          .widgetList<LinearProgressIndicator>(
            find.byType(LinearProgressIndicator),
          )
          .map((bar) => bar.value),
      [1, .5, 0],
    );
    expect(tester.takeException(), isNull);
  });
}
