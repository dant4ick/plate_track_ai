import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plate_track_ai/core/themes/app_theme.dart';
import 'package:plate_track_ai/features/weight/weight_history_screen.dart';
import 'package:plate_track_ai/shared/models/weight_entry.dart';

import 'localized_pump.dart';
import '../color_test_utils.dart';

void main() {
  setUpAll(initLocalization);

  final many = [
    for (var i = 0; i < 6; i++)
      WeightEntry(date: DateTime(2026, 8, 1 + i * 4), kg: 72 - i * 0.8),
  ];

  testWidgets('draws themed series and readable goals in all three themes', (
    tester,
  ) async {
    await pumpLocalized(
      tester,
      Scaffold(
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              for (final theme in [
                AppTheme.lightTheme,
                AppTheme.darkTheme,
                AppTheme.pickMeTheme,
              ])
                Theme(
                  data: theme,
                  child: Column(
                    children: [
                      // A single weigh-in has no x range of its own.
                      WeightChart(series: [many.first], height: 140),
                      const SizedBox(height: 12),
                      // Two points draw straight; curves start at three.
                      WeightChart(series: many.take(2).toList(), height: 140),
                      const SizedBox(height: 12),
                      WeightChart(series: many, goal: 65, height: 160),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
      size: const Size(390, 1900),
    );

    expect(tester.takeException(), isNull);
    expect(find.byType(WeightChart), findsNWidgets(9));
    // The goal is drawn as a horizontal rule (painted, so not a Text widget).
    final withGoal = tester
        .widgetList<LineChart>(find.byType(LineChart))
        .where((c) => c.data.extraLinesData.horizontalLines.isNotEmpty)
        .toList();
    expect(withGoal, hasLength(3));
    expect(withGoal.first.data.extraLinesData.horizontalLines.single.y, 65);
    final themes = [
      AppTheme.lightTheme,
      AppTheme.darkTheme,
      AppTheme.pickMeTheme,
    ];
    for (var i = 0; i < withGoal.length; i++) {
      final data = withGoal[i].data;
      final surface = themes[i].colorScheme.surface;
      expect(data.lineBarsData.single.color, themes[i].colorScheme.primary);
      final goal = data.extraLinesData.horizontalLines.single;
      expect(contrastOn(goal.color!, surface), greaterThanOrEqualTo(3));
      expect(
        contrastOn(goal.label.style!.color!, surface),
        greaterThanOrEqualTo(4.5),
      );
      // The goal can sit under the series, on top of the tinted plot area.
      expect(
        contrastOn(
          goal.label.style!.color!,
          data.lineBarsData.single.belowBarData.color!,
          surface: surface,
        ),
        greaterThanOrEqualTo(4.5),
      );
    }
    // The ends of the axis carry dates.
    expect(find.text('1 Aug'), findsWidgets);
    expect(find.text('21 Aug'), findsNWidgets(3));
  });
}
