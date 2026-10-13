import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plate_track_ai/core/themes/app_theme.dart';
import 'package:plate_track_ai/features/weight/weight_history_screen.dart';
import 'package:plate_track_ai/shared/models/weight_entry.dart';

import 'localized_pump.dart';

void main() {
  setUpAll(initLocalization);

  final many = [
    for (var i = 0; i < 6; i++)
      WeightEntry(date: DateTime(2026, 8, 1 + i * 4), kg: 72 - i * 0.8),
  ];

  testWidgets('draws one, two and many weigh-ins in both themes', (
    tester,
  ) async {
    await pumpLocalized(
      tester,
      Scaffold(
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              for (final theme in [AppTheme.lightTheme, AppTheme.darkTheme])
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
      size: const Size(390, 1400),
    );

    expect(tester.takeException(), isNull);
    expect(find.byType(WeightChart), findsNWidgets(6));
    // The goal is drawn as a horizontal rule (painted, so not a Text widget).
    final withGoal = tester
        .widgetList<LineChart>(find.byType(LineChart))
        .where((c) => c.data.extraLinesData.horizontalLines.isNotEmpty)
        .toList();
    expect(withGoal, hasLength(2));
    expect(withGoal.first.data.extraLinesData.horizontalLines.single.y, 65);
    // The ends of the axis carry dates.
    expect(find.text('1 Aug'), findsWidgets);
    expect(find.text('21 Aug'), findsNWidgets(2));
  });
}
