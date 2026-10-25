import 'package:flutter/foundation.dart';

import 'package:plate_track_ai/shared/models/food_item.dart';

/// One day's nutrition totals, already scaled from per-100 g facts to the mass
/// actually eaten.
@immutable
class DayTotals {
  const DayTotals({
    this.calories = 0,
    this.protein = 0,
    this.carbs = 0,
    this.fat = 0,
    this.itemCount = 0,
  });

  /// Sums a day's items, scaling each by its mass.
  factory DayTotals.of(List<FoodItem> items) {
    double calories = 0, protein = 0, carbs = 0, fat = 0;

    for (final item in items) {
      // Nutrition facts are stored per 100 g.
      final scale = (item.nutritionFacts.mass ?? 100.0) / 100.0;
      calories += item.calories * scale;
      protein += item.nutritionFacts.protein * scale;
      carbs += item.nutritionFacts.carbs * scale;
      fat += item.nutritionFacts.fat * scale;
    }

    return DayTotals(
      calories: calories,
      protein: protein,
      carbs: carbs,
      fat: fat,
      itemCount: items.length,
    );
  }

  final double calories;
  final double protein;
  final double carbs;
  final double fat;
  final int itemCount;

  bool get isEmpty => itemCount == 0;
}

/// Seven days of totals, oldest first, plus the averages derived from them.
///
/// Averages divide by the number of days that actually have data, not by seven.
/// A user who logged two days does not want their intake reported as two-sevenths
/// of what they ate.
@immutable
class WeekSummary {
  const WeekSummary._(this.days);

  /// Builds a summary from seven days of items, **oldest first** — index 6 is
  /// today, which is the order the chart draws them in.
  factory WeekSummary.fromDays(List<List<FoodItem>> daysOldestFirst) {
    return WeekSummary._(
      List.unmodifiable(daysOldestFirst.map(DayTotals.of)),
    );
  }

  /// An empty week, for the loading and no-data states.
  factory WeekSummary.empty() => WeekSummary._(
    List.unmodifiable(List.generate(7, (_) => const DayTotals())),
  );

  final List<DayTotals> days;

  /// Today's totals — the last entry.
  DayTotals get today => days.last;

  int get daysWithData => days.where((day) => !day.isEmpty).length;

  bool get hasData => daysWithData > 0;

  double _averageOf(double Function(DayTotals) field) {
    final logged = days.where((day) => !day.isEmpty);
    if (logged.isEmpty) return 0;
    return logged.map(field).reduce((a, b) => a + b) / logged.length;
  }

  double get averageCalories => _averageOf((day) => day.calories);
  double get averageProtein => _averageOf((day) => day.protein);
  double get averageCarbs => _averageOf((day) => day.carbs);
  double get averageFat => _averageOf((day) => day.fat);

  /// Per-day calorie totals in draw order, for the weekly chart.
  List<double> get dailyCalories =>
      days.map((day) => day.calories).toList(growable: false);
}
