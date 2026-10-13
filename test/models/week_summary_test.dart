import 'package:flutter_test/flutter_test.dart';
import 'package:plate_track_ai/shared/models/food_item.dart';
import 'package:plate_track_ai/shared/models/week_summary.dart';

import '../test_utils.dart';

/// A day holding one item whose per-100 g facts are scaled by [mass].
List<FoodItem> day({
  double calories = 100,
  double protein = 10,
  double carbs = 20,
  double fat = 5,
  double mass = 100,
  int count = 1,
}) {
  return List.generate(
    count,
    (_) => TestDataFactory.createFoodItem(
      calories: calories,
      protein: protein,
      carbs: carbs,
      fat: fat,
      mass: mass,
    ),
  );
}

void main() {
  group('DayTotals', () {
    test('scales per-100g facts by the eaten mass', () {
      final totals = DayTotals.of(day(calories: 100, protein: 10, mass: 250));

      expect(totals.calories, closeTo(250, 1e-9));
      expect(totals.protein, closeTo(25, 1e-9));
      expect(totals.itemCount, 1);
    });

    test('treats a missing mass as a 100g portion', () {
      final item = FoodItem(
        name: 'No mass',
        calories: 100,
        nutritionFacts: NutritionFacts(protein: 10, carbs: 20, fat: 5),
      );

      expect(DayTotals.of([item]).calories, closeTo(100, 1e-9));
    });

    test('an empty day is empty', () {
      expect(DayTotals.of([]).isEmpty, isTrue);
      expect(const DayTotals().isEmpty, isTrue);
    });
  });

  group('WeekSummary', () {
    test('today is the last day, matching draw order', () {
      final week = WeekSummary.fromDays([
        for (var i = 0; i < 6; i++) day(calories: 100),
        day(calories: 900),
      ]);

      expect(week.today.calories, closeTo(900, 1e-9));
      expect(week.dailyCalories.last, closeTo(900, 1e-9));
      expect(week.dailyCalories.first, closeTo(100, 1e-9));
    });

    test('averages divide by logged days, not by seven', () {
      // Two days at 600 kcal. Averaging over seven would report 171.
      final week = WeekSummary.fromDays([
        day(calories: 600),
        day(calories: 600),
        [],
        [],
        [],
        [],
        [],
      ]);

      expect(week.daysWithData, 2);
      expect(week.averageCalories, closeTo(600, 1e-9));
    });

    test('averages every macro over the logged days', () {
      final week = WeekSummary.fromDays([
        day(protein: 30, carbs: 60, fat: 20),
        day(protein: 10, carbs: 20, fat: 10),
        [],
        [],
        [],
        [],
        [],
      ]);

      expect(week.averageProtein, closeTo(20, 1e-9));
      expect(week.averageCarbs, closeTo(40, 1e-9));
      expect(week.averageFat, closeTo(15, 1e-9));
    });

    test('an all-empty week averages to zero rather than dividing by zero', () {
      final week = WeekSummary.fromDays(List.generate(7, (_) => []));

      expect(week.hasData, isFalse);
      expect(week.daysWithData, 0);
      expect(week.averageCalories, 0);
      expect(week.averageProtein, 0);
    });

    test('empty() is a seven-day week with nothing in it', () {
      final week = WeekSummary.empty();

      expect(week.days, hasLength(7));
      expect(week.hasData, isFalse);
      expect(week.dailyCalories, everyElement(0));
    });

    test('sums multiple items within a day', () {
      final week = WeekSummary.fromDays([
        day(calories: 100, count: 3),
        [],
        [],
        [],
        [],
        [],
        [],
      ]);

      expect(week.days.first.calories, closeTo(300, 1e-9));
      expect(week.days.first.itemCount, 3);
    });

    test('days are unmodifiable so callers cannot corrupt a summary', () {
      final week = WeekSummary.fromDays(List.generate(7, (_) => []));

      expect(
        () => week.days.add(const DayTotals()),
        throwsUnsupportedError,
      );
    });
  });
}
