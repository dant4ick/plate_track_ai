import 'package:flutter/foundation.dart';

import 'food_item.dart';

/// A recent-meals divider: one local hour today, otherwise one calendar day.
@immutable
class RecentMealGroup {
  const RecentMealGroup({
    required this.date,
    required this.hour,
    required this.items,
  });

  /// Local calendar midnight, never an elapsed-duration bucket.
  final DateTime date;

  /// Local wall-clock hour for today; null for every other calendar date.
  final int? hour;
  final List<FoodItem> items;
}

/// Newest first, with copied lists and the original meals/timestamps intact.
/// Converting both the reference clock and meals keeps UTC storage consistent
/// with local calendar boundaries (including month, year and DST changes).
List<RecentMealGroup> groupRecentMeals(
  List<FoodItem> items, {
  required DateTime now,
}) {
  final localNow = now.toLocal();
  final today = DateTime(localNow.year, localNow.month, localNow.day);
  final sorted = [...items]..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  final buckets = <(DateTime, int?), List<FoodItem>>{};
  for (final item in sorted) {
    final time = item.timestamp.toLocal();
    final date = DateTime(time.year, time.month, time.day);
    final key = (date, date == today ? time.hour : null);
    buckets.putIfAbsent(key, () => []).add(item);
  }
  return [
    for (final entry in buckets.entries)
      RecentMealGroup(
        date: entry.key.$1,
        hour: entry.key.$2,
        items: List.unmodifiable(entry.value),
      ),
  ];
}
