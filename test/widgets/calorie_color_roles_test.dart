import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plate_track_ai/core/themes/app_theme.dart';
import 'package:plate_track_ai/features/nutrition_stats/nutrition_summary.dart';
import 'package:plate_track_ai/features/nutrition_stats/nutrition_trend_chart.dart';

import '../color_test_utils.dart';
import '../test_utils.dart';
import 'localized_pump.dart';

void main() {
  setUpAll(initLocalization);

  testWidgets('selected and ordinary calorie bars keep fixed pink fills', (
    tester,
  ) async {
    final now = DateTime(2026, 10, 26);
    final summary = NutritionSummary.fromItems(
      [TestDataFactory.createFoodItem(timestamp: now, calories: 1000)],
      period: NutritionPeriod.day,
      now: now,
    );
    final themes = [
      AppTheme.lightTheme,
      AppTheme.darkTheme,
      AppTheme.pickMeTheme,
    ];
    await pumpLocalized(
      tester,
      Scaffold(
        body: SingleChildScrollView(
          child: Column(
            children: [
              for (final theme in themes)
                Theme(
                  data: theme,
                  child: NutritionTrendChart(
                    summary: summary,
                    selectedIndex: 7,
                    onSelected: (_) {},
                  ),
                ),
            ],
          ),
        ),
      ),
      size: const Size(390, 1200),
    );
    final charts = find.byType(NutritionTrendChart);
    for (var index = 0; index < themes.length; index++) {
      final bars = tester
          .widgetList<AnimatedContainer>(
            find.descendant(
              of: charts.at(index),
              matching: find.byType(AnimatedContainer),
            ),
          )
          .toList();
      expect(bars, hasLength(8));
      for (var bar = 0; bar < bars.length; bar++) {
        final decoration = bars[bar].decoration! as BoxDecoration;
        expect(decoration.color, const Color(0xFFFF3372));
        expect(decoration.border, isNotNull);
        final border = decoration.border! as Border;
        expect(border.top.width, bar == 7 ? 2 : 1);
        expect(
          contrastOn(border.top.color, themes[index].colorScheme.surface),
          greaterThanOrEqualTo(3),
        );
      }
    }
    expect(tester.takeException(), isNull);
  });
}
