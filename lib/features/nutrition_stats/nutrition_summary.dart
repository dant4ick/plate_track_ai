import 'package:flutter/foundation.dart';

import 'package:plate_track_ai/shared/models/food_item.dart';
import 'package:plate_track_ai/shared/models/week_summary.dart';

enum NutritionPeriod { day, week, month }

/// One calendar day, Monday–Sunday week, or calendar month.
@immutable
class NutritionBucket {
  const NutritionBucket({
    required this.start,
    required this.end,
    required this.averageCalories,
    required this.averageProtein,
    required this.averageFat,
    required this.averageCarbs,
    required this.loggedDays,
    required this.itemCount,
  });

  final DateTime start;

  /// Exclusive end of the calendar interval.
  final DateTime end;
  final double averageCalories;
  final double averageProtein;
  final double averageFat;
  final double averageCarbs;
  final int loggedDays;
  final int itemCount;
}

/// Exactly eight consecutive calendar intervals, including the current one.
/// Bars show average daily intake over logged days. Missing days are unknown,
/// not zero intake; future meals never inflate the current bar.
@immutable
class NutritionSummary {
  const NutritionSummary._(this.period, this.buckets);

  factory NutritionSummary.fromItems(
    List<FoodItem> items, {
    required NutritionPeriod period,
    required DateTime now,
  }) {
    final local = now.toLocal();
    final today = DateTime(local.year, local.month, local.day);
    final tomorrow = DateTime(today.year, today.month, today.day + 1);
    final anchor = switch (period) {
      NutritionPeriod.day => today,
      NutritionPeriod.week => DateTime(
        today.year,
        today.month,
        today.day - today.weekday + 1,
      ),
      NutritionPeriod.month => DateTime(today.year, today.month),
    };
    DateTime boundary(int offset) => switch (period) {
      NutritionPeriod.day => DateTime(
        anchor.year,
        anchor.month,
        anchor.day + offset,
      ),
      NutritionPeriod.week => DateTime(
        anchor.year,
        anchor.month,
        anchor.day + offset * 7,
      ),
      NutritionPeriod.month => DateTime(anchor.year, anchor.month + offset),
    };
    final buckets = <NutritionBucket>[];
    for (var offset = -7; offset <= 0; offset++) {
      final start = boundary(offset);
      final end = boundary(offset + 1);
      final meals = items.where((item) {
        final date = item.timestamp.toLocal();
        return !date.isBefore(start) &&
            date.isBefore(end) &&
            date.isBefore(tomorrow);
      }).toList();
      final totals = DayTotals.of(meals);
      final loggedDays = meals
          .map((meal) {
            final date = meal.timestamp.toLocal();
            return (date.year, date.month, date.day);
          })
          .toSet()
          .length;
      buckets.add(
        NutritionBucket(
          start: start,
          end: end,
          averageCalories: loggedDays == 0 ? 0 : totals.calories / loggedDays,
          averageProtein: loggedDays == 0 ? 0 : totals.protein / loggedDays,
          averageFat: loggedDays == 0 ? 0 : totals.fat / loggedDays,
          averageCarbs: loggedDays == 0 ? 0 : totals.carbs / loggedDays,
          loggedDays: loggedDays,
          itemCount: totals.itemCount,
        ),
      );
    }
    return NutritionSummary._(period, List.unmodifiable(buckets));
  }

  final NutritionPeriod period;
  final List<NutritionBucket> buckets;

  bool get hasData => buckets.any((bucket) => bucket.itemCount > 0);
}
