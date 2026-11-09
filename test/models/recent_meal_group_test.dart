import 'package:flutter_test/flutter_test.dart';
import 'package:plate_track_ai/shared/models/food_item.dart';
import 'package:plate_track_ai/shared/models/recent_meal_group.dart';

FoodItem meal(String name, DateTime time) => FoodItem(
  name: name,
  calories: 100,
  nutritionFacts: const NutritionFacts(protein: 1, carbs: 2, fat: 3),
  timestamp: time,
);

void main() {
  test('empty input has no groups', () {
    expect(groupRecentMeals([], now: DateTime(2026, 1, 1)), isEmpty);
  });

  test('local midnight across year boundary uses dates, not elapsed hours', () {
    final groups = groupRecentMeals([
      meal('December night', DateTime(2025, 12, 31, 23, 59)),
      meal('December morning', DateTime(2025, 12, 31, 0, 1)),
      meal('January', DateTime(2026, 1, 1, 0, 1)),
      meal('Two days ago', DateTime(2025, 12, 30, 23, 59)),
    ], now: DateTime(2026, 1, 1, 0, 2));
    expect(groups.map((g) => g.date), [
      DateTime(2026, 1, 1),
      DateTime(2025, 12, 31),
      DateTime(2025, 12, 30),
    ]);
    expect(groups.map((g) => g.hour), [0, null, null]);
    expect(groups[1].items.map((m) => m.name), [
      'December night',
      'December morning',
    ]);
  });

  test(
    'UTC instants use local dates and hours, including the reference clock',
    () {
      // Run under TZ=Europe/Moscow and TZ=America/New_York as well as UTC.
      final localMidnight = DateTime(2026, 3, 1, 0, 5);
      final localYesterday = DateTime(2026, 2, 28, 23, 55);
      final groups = groupRecentMeals([
        meal('yesterday UTC', localYesterday.toUtc()),
        meal('today UTC', localMidnight.toUtc()),
      ], now: DateTime(2026, 3, 1, 0, 10).toUtc());
      expect(groups.map((g) => g.date), [
        DateTime(2026, 3, 1),
        DateTime(2026, 2, 28),
      ]);
      expect(groups.map((g) => g.hour), [0, null]);
      expect(groups.first.items.single.timestamp.isUtc, isTrue);
    },
  );

  test('DST fall-back keeps both occurrences in the same local hour', () {
    final groups = groupRecentMeals([
      meal('first occurrence', DateTime.parse('2026-11-01T01:20:00-04:00')),
      meal('second occurrence', DateTime.parse('2026-11-01T01:10:00-05:00')),
    ], now: DateTime(2026, 11, 1, 12));
    // Meaningful DST assertion when run with TZ=America/New_York.
    if (DateTime(2026, 11, 1, 12).timeZoneOffset == const Duration(hours: -5)) {
      expect(groups, hasLength(1));
      expect(groups.single.hour, 1);
      expect(groups.single.items.map((m) => m.name), [
        'second occurrence',
        'first occurrence',
      ]);
    }
    expect(groups.expand((g) => g.items), hasLength(2));
  });

  test('mixed days collapse yesterday and older dates regardless of hour', () {
    final groups = groupRecentMeals([
      meal('old morning', DateTime(2026, 10, 31, 8)),
      meal('yesterday morning', DateTime(2026, 11, 8, 6)),
      meal('today', DateTime(2026, 11, 9, 0, 1)),
      meal('old evening', DateTime(2026, 10, 31, 23)),
      meal('yesterday night', DateTime(2026, 11, 8, 23, 59)),
    ], now: DateTime(2026, 11, 9, 0, 2));
    expect(groups.map((g) => g.hour), [0, null, null]);
    expect(groups.map((g) => g.date), [
      DateTime(2026, 11, 9),
      DateTime(2026, 11, 8),
      DateTime(2026, 10, 31),
    ]);
    expect(groups.map((g) => g.items.length), [1, 2, 2]);
    expect(groups[1].items.first.name, 'yesterday night');
    expect(groups[2].items.first.name, 'old evening');
  });

  test('today groups by local hour, newest first, without changing input', () {
    final early = meal('early', DateTime(2026, 11, 9, 8, 5));
    final late = meal('late', DateTime(2026, 11, 9, 14, 50));
    final middle = meal('middle', DateTime(2026, 11, 9, 14, 10));
    final input = List<FoodItem>.unmodifiable([early, middle, late]);
    final groups = groupRecentMeals(input, now: DateTime(2026, 11, 9, 15));
    expect(groups.map((g) => g.hour), [14, 8]);
    expect(groups.map((g) => g.items.map((m) => m.name).toList()), [
      ['late', 'middle'],
      ['early'],
    ]);
    expect(input, [early, middle, late]);
  });
}
