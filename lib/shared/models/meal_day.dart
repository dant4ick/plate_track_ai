import 'package:flutter/foundation.dart';

import 'package:plate_track_ai/shared/models/food_item.dart';
import 'package:plate_track_ai/shared/models/week_summary.dart';

/// One calendar day of logged meals, newest meal first.
@immutable
class MealDay {
  const MealDay({required this.date, required this.items});

  /// Midnight at the start of the day.
  final DateTime date;

  final List<FoodItem> items;

  DayTotals get totals => DayTotals.of(items);
}

/// Groups meals by the calendar day they were logged on, newest day first and
/// newest meal first within each day — the order a history list reads in.
List<MealDay> groupMealsByDay(List<FoodItem> items) {
  final byDay = <DateTime, List<FoodItem>>{};

  for (final item in items) {
    final t = item.timestamp;
    final day = DateTime(t.year, t.month, t.day);
    byDay.putIfAbsent(day, () => []).add(item);
  }

  final days = byDay.keys.toList()..sort((a, b) => b.compareTo(a));

  return [
    for (final day in days)
      MealDay(
        date: day,
        items: List.unmodifiable(
          byDay[day]!..sort((a, b) => b.timestamp.compareTo(a.timestamp)),
        ),
      ),
  ];
}
