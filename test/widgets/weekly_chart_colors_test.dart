import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plate_track_ai/core/themes/app_theme.dart';
import 'package:plate_track_ai/core/themes/app_colors.dart';
import 'package:plate_track_ai/shared/models/week_summary.dart';
import 'package:plate_track_ai/shared/widgets/weekly_calories_chart.dart';

import '../color_test_utils.dart';
import '../test_utils.dart';
import 'localized_pump.dart';

void main() {
  setUpAll(initLocalization);
  testWidgets(
    'all bars, axes and touched values are readable in all three themes',
    (tester) async {
      final themes = [
        AppTheme.lightTheme,
        AppTheme.darkTheme,
        AppTheme.pickMeTheme,
      ];
      final now = DateTime.now();
      final summary = WeekSummary.fromDays([
        for (var i = 0; i < 7; i++)
          [
            TestDataFactory.createFoodItem(
              calories: 1000 + i * 100,
              timestamp: now.subtract(Duration(days: 6 - i)),
            ),
          ],
      ]);
      await pumpLocalized(
        tester,
        Scaffold(
          body: SingleChildScrollView(
            child: Column(
              children: [
                for (final theme in themes)
                  Theme(
                    data: theme,
                    child: WeeklyCaloriesChart(summary: summary),
                  ),
              ],
            ),
          ),
        ),
        size: const Size(390, 1100),
      );
      expect(tester.takeException(), isNull);
      final charts = tester
          .widgetList<BarChart>(find.byType(BarChart))
          .toList();
      expect(charts, hasLength(3));
      for (var i = 0; i < charts.length; i++) {
        final data = charts[i].data;
        final theme = themes[i];
        final tooltip = data.barTouchData.touchTooltipData;
        final palette = AppPalette.of(tester.element(find.byWidget(charts[i])));
        for (final group in data.barGroups) {
          for (var rodIndex = 0; rodIndex < group.barRods.length; rodIndex++) {
            final rod = group.barRods[rodIndex];
            expect(rod.color, theme.colorScheme.primary);
            expect(
              rod.borderSide.width,
              group.x == data.barGroups.last.x ? 2 : 1,
            );
            expect(rod.borderSide.color, palette.caloriesInk);
            expect(
              contrastOn(rod.borderSide.color, theme.colorScheme.surface),
              greaterThanOrEqualTo(3),
            );
            final item = tooltip.getTooltipItem(group, group.x, rod, rodIndex)!;
            expect(item.text, rod.toY.toString());
            expect(
              contrastOn(
                item.textStyle.color!,
                tooltip.getTooltipColor(group),
                surface: theme.colorScheme.surface,
              ),
              greaterThanOrEqualTo(4.5),
            );
          }
        }
      }
      for (final text in tester.widgetList<Text>(find.byType(Text))) {
        if (text.style?.color == null) continue;
        final context = tester.element(find.byWidget(text));
        expect(
          contrastOn(text.style!.color!, Theme.of(context).colorScheme.surface),
          greaterThanOrEqualTo(4.5),
        );
      }
    },
  );
}
