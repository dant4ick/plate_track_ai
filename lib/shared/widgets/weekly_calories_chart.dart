import 'package:easy_localization/easy_localization.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import 'package:plate_track_ai/core/themes/app_colors.dart';
import 'package:plate_track_ai/shared/models/week_summary.dart';
import 'package:plate_track_ai/shared/widgets/soft_card.dart';

/// Seven days of calorie totals in the theme primary, with readable outlines.
/// Today has a stronger outline rather than a different fill colour.
///
/// Shared by the dashboard and the stats screen so the two cannot drift apart.
class WeeklyCaloriesChart extends StatelessWidget {
  const WeeklyCaloriesChart({
    super.key,
    required this.summary,
    this.height = 220,
  });

  final WeekSummary summary;
  final double height;

  /// Day-of-week labels for the last seven days, oldest first, matching the
  /// order of [WeekSummary.days].
  static List<String> _weekdayLabels(BuildContext context, DateTime today) {
    return [
      for (var i = 6; i >= 0; i--)
        DateFormat(
          'E',
          context.locale.toString(),
        ).format(DateTime(today.year, today.month, today.day - i)),
    ];
  }

  /// Rounds the axis up to the next 500 so gridlines land on round numbers, with
  /// one interval of headroom above the tallest bar.
  static double _maxY(List<double> values) {
    final tallest = values.isEmpty
        ? 0.0
        : values.reduce((a, b) => a > b ? a : b);
    return ((tallest / 500).ceil() * 500 + 500).clamp(1000, 5000).toDouble();
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final theme = Theme.of(context);
    final calories = summary.dailyCalories;
    final labels = _weekdayLabels(context, DateTime.now());

    final labelStyle = theme.textTheme.bodySmall?.copyWith(
      color: palette.textSecondary,
    );

    return SoftCard(
      child: SizedBox(
        height: height,
        child: BarChart(
          BarChartData(
            alignment: BarChartAlignment.spaceAround,
            maxY: _maxY(calories),
            minY: 0,
            barTouchData: BarTouchData(
              touchTooltipData: BarTouchTooltipData(
                getTooltipColor: (_) => theme.colorScheme.inverseSurface,
                getTooltipItem: (group, groupIndex, rod, rodIndex) =>
                    BarTooltipItem(
                      rod.toY.toString(),
                      theme.textTheme.bodySmall!.copyWith(
                        color: theme.colorScheme.onInverseSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                fitInsideHorizontally: true,
                fitInsideVertically: true,
              ),
            ),
            barGroups: [
              for (var i = 0; i < calories.length; i++)
                BarChartGroupData(
                  x: i,
                  barRods: [
                    BarChartRodData(
                      toY: calories[i],
                      color: palette.calories,
                      borderSide: BorderSide(
                        color: palette.caloriesInk,
                        width: i == calories.length - 1 ? 2 : 1,
                      ),
                      width: 18,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(6),
                      ),
                    ),
                  ],
                ),
            ],
            titlesData: FlTitlesData(
              show: true,
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 28,
                  getTitlesWidget: (value, meta) {
                    final index = value.toInt();
                    if (index < 0 || index >= labels.length) {
                      return const SizedBox.shrink();
                    }
                    return SideTitleWidget(
                      meta: meta,
                      child: Text(labels[index], style: labelStyle),
                    );
                  },
                ),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 40,
                  getTitlesWidget: (value, meta) {
                    if (value % 500 != 0) return const SizedBox.shrink();
                    return SideTitleWidget(
                      meta: meta,
                      child: Text(value.toInt().toString(), style: labelStyle),
                    );
                  },
                ),
              ),
              topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
            ),
            gridData: FlGridData(
              show: true,
              horizontalInterval: 500,
              drawVerticalLine: false,
              getDrawingHorizontalLine: (value) =>
                  FlLine(color: palette.chartGrid, strokeWidth: 1),
            ),
            borderData: FlBorderData(show: false),
          ),
        ),
      ),
    );
  }
}
