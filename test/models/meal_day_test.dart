import 'package:flutter_test/flutter_test.dart';
import 'package:plate_track_ai/shared/models/meal_day.dart';

import '../test_utils.dart';

void main() {
  group('groupMealsByDay', () {
    test('returns nothing for no meals', () {
      expect(groupMealsByDay(const []), isEmpty);
    });

    test('groups by calendar day, newest day first, newest meal first', () {
      final items = [
        TestDataFactory.createFoodItem(
          name: 'Old lunch',
          timestamp: DateTime(2026, 8, 20, 13),
        ),
        TestDataFactory.createFoodItem(
          name: 'Breakfast',
          timestamp: DateTime(2026, 8, 25, 8),
        ),
        TestDataFactory.createFoodItem(
          name: 'Dinner',
          timestamp: DateTime(2026, 8, 25, 19),
        ),
        TestDataFactory.createFoodItem(
          name: 'Old breakfast',
          timestamp: DateTime(2026, 8, 20, 8),
        ),
      ];

      final days = groupMealsByDay(items);

      expect(days.map((d) => d.date), [
        DateTime(2026, 8, 25),
        DateTime(2026, 8, 20),
      ]);
      expect(days[0].items.map((i) => i.name), ['Dinner', 'Breakfast']);
      expect(days[1].items.map((i) => i.name), ['Old lunch', 'Old breakfast']);
    });

    test('a day sums the calories of its meals by portion', () {
      final day = groupMealsByDay([
        TestDataFactory.createFoodItem(
          calories: 200,
          mass: 150,
          timestamp: DateTime(2026, 8, 25, 8),
        ),
        TestDataFactory.createFoodItem(
          calories: 100,
          mass: 100,
          timestamp: DateTime(2026, 8, 25, 12),
        ),
      ]).single;

      expect(day.totals.calories, closeTo(400, 1e-9));
      expect(day.totals.itemCount, 2);
    });
  });
}
