import 'dart:math' as math;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'package:plate_track_ai/core/themes/app_colors.dart';
import 'nutrition_summary.dart';

/// Eight selectable bars of average daily intake against a fixed daily goal.
class NutritionTrendChart extends StatelessWidget {
  const NutritionTrendChart({
    super.key,
    required this.summary,
    required this.selectedIndex,
    required this.onSelected,
    this.dailyTarget,
  });

  final NutritionSummary summary;
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final double? dailyTarget;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final theme = Theme.of(context);
    final buckets = summary.buckets;
    final target = dailyTarget;
    final goal = target != null && target > 0 ? target : null;
    final tallest = [
      ...buckets.map((bucket) => bucket.averageCalories),
      ?goal,
    ].fold(0.0, math.max);
    final magnitude = math
        .pow(10, (math.log(math.max(tallest, 1000)) / math.ln10).floor())
        .toDouble();
    final step = magnitude / 2;
    final maxY = (math.max(tallest, 1000) / step).ceil() * step + step;
    final labelStyle = theme.textTheme.labelSmall?.copyWith(
      color: palette.textSecondary,
    );
    final axisFormat = NumberFormat.compact(locale: context.locale.toString());
    final dateFormat = DateFormat(
      summary.period == NutritionPeriod.month ? 'MMM' : 'd MMM',
      context.locale.toString(),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 48,
              height: 230,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(axisFormat.format(maxY), style: labelStyle),
                  Text('0', style: labelStyle),
                ],
              ),
            ),
            Expanded(
              child: Column(
                children: [
                  SizedBox(
                    height: 230,
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        return CustomPaint(
                          painter: _ChartGrid(palette.chartGrid),
                          foregroundPainter: _GoalLine(
                            goal,
                            maxY,
                            theme.colorScheme.onSurface,
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              for (var i = 0; i < buckets.length; i++)
                                Expanded(
                                  child: Semantics(
                                    button: true,
                                    selected: i == selectedIndex,
                                    label:
                                        '${DateFormat.yMMMd(context.locale.toString()).format(buckets[i].start)}, '
                                        '${buckets[i].averageCalories.round()} ${'kcal'.tr()}/${'day'.tr()}'
                                        '${goal == null ? '' : ', ${'goal'.tr()}: ${goal.round()} ${'kcal'.tr()}/${'day'.tr()}'}',
                                    child: InkWell(
                                      key: ValueKey('calorie-bar-$i'),
                                      onTap: () => onSelected(i),
                                      borderRadius: BorderRadius.circular(8),
                                      child: Align(
                                        alignment: Alignment.bottomCenter,
                                        child: AnimatedContainer(
                                          duration: const Duration(
                                            milliseconds: 200,
                                          ),
                                          curve: Curves.easeOut,
                                          width: math.min(
                                            24,
                                            constraints.maxWidth / 8 * .6,
                                          ),
                                          height: math.max(
                                            3,
                                            buckets[i].averageCalories /
                                                maxY *
                                                constraints.maxHeight,
                                          ),
                                          decoration: BoxDecoration(
                                            color: i == selectedIndex
                                                ? palette.caloriesInk
                                                : palette.calories,
                                            borderRadius:
                                                const BorderRadius.vertical(
                                                  top: Radius.circular(6),
                                                ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      for (final i in [0, 4, 7])
                        Text(
                          dateFormat.format(buckets[i].start),
                          style: labelStyle,
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        if (goal != null) ...[
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              SizedBox(
                width: 24,
                height: 2,
                child: CustomPaint(
                  painter: _LegendLine(theme.colorScheme.onSurface),
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text('goal'.tr(), style: theme.textTheme.bodySmall),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _ChartGrid extends CustomPainter {
  const _ChartGrid(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;
    for (var i = 0; i <= 4; i++) {
      final y = size.height * i / 4;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_ChartGrid oldDelegate) => oldDelegate.color != color;
}

void _dash(Canvas canvas, Offset from, Offset to, Paint paint) {
  final distance = (to - from).distance;
  if (distance == 0) return;
  final direction = (to - from) / distance;
  for (var x = 0.0; x < distance; x += 8) {
    canvas.drawLine(
      from + direction * x,
      from + direction * math.min(x + 4, distance),
      paint,
    );
  }
}

class _GoalLine extends CustomPainter {
  const _GoalLine(this.goal, this.maxY, this.color);
  final double? goal;
  final double maxY;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final target = goal;
    if (target == null) return;
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5;
    final y = size.height * (1 - target / maxY);
    _dash(canvas, Offset(0, y), Offset(size.width, y), paint);
  }

  @override
  bool shouldRepaint(_GoalLine oldDelegate) =>
      oldDelegate.maxY != maxY ||
      oldDelegate.color != color ||
      oldDelegate.goal != goal;
}

class _LegendLine extends CustomPainter {
  const _LegendLine(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) => _dash(
    canvas,
    Offset.zero,
    Offset(size.width, 0),
    Paint()
      ..color = color
      ..strokeWidth = 1.5,
  );

  @override
  bool shouldRepaint(_LegendLine oldDelegate) => oldDelegate.color != color;
}
