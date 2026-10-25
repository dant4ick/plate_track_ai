import 'package:flutter_test/flutter_test.dart';
import 'package:plate_track_ai/features/nutrition_stats/nutrition_summary.dart';
import 'package:plate_track_ai/shared/models/food_item.dart';

import '../test_utils.dart';

FoodItem meal(DateTime time, {double calories = 100, double mass = 100}) =>
    TestDataFactory.createFoodItem(
      timestamp: time,
      calories: calories,
      mass: mass,
    );

void main() {
  final now = DateTime(2026, 1, 3, 18);

  test(
    'eight days include today, scale portions and leave missing days visible',
    () {
      final summary = NutritionSummary.fromItems(
        [
          meal(DateTime(2025, 12, 26, 23, 59), calories: 999),
          meal(DateTime(2025, 12, 27), calories: 200),
          meal(DateTime(2026, 1, 3), mass: 250),
          meal(DateTime(2026, 1, 3, 17)),
          meal(DateTime(2026, 1, 4), calories: 999),
        ],
        period: NutritionPeriod.day,
        now: now,
      );
      expect(summary.buckets, hasLength(8));
      expect(summary.buckets.first.start, DateTime(2025, 12, 27));
      expect(summary.buckets.last.start, DateTime(2026, 1, 3));
      expect(summary.buckets.map((b) => b.averageCalories), [
        200,
        0,
        0,
        0,
        0,
        0,
        0,
        350,
      ]);
      expect(summary.buckets.last.itemCount, 2);
      expect(summary.buckets.last.loggedDays, 1);
      expect(summary.buckets.last.averageProtein, 17.5);
      expect(summary.buckets.last.averageFat, 10.5);
      expect(summary.buckets.last.averageCarbs, 52.5);
    },
  );

  test('eight calendar weeks start on Monday and cross year boundaries', () {
    final summary = NutritionSummary.fromItems(
      [
        meal(DateTime(2025, 11, 10), calories: 200),
        meal(DateTime(2025, 12, 28, 23, 59), calories: 300),
        meal(DateTime(2025, 12, 29), calories: 400),
        meal(DateTime(2026, 1, 3), calories: 500),
        meal(DateTime(2026, 1, 4), calories: 999),
      ],
      period: NutritionPeriod.week,
      now: now,
    );
    expect(summary.buckets, hasLength(8));
    expect(summary.buckets.first.start, DateTime(2025, 11, 10));
    expect(summary.buckets.last.start, DateTime(2025, 12, 29));
    expect(summary.buckets.last.end, DateTime(2026, 1, 5));
    expect(summary.buckets.last.averageCalories, 450);
    expect(summary.buckets.last.loggedDays, 2);
    expect(summary.buckets.last.averageProtein, 5);
    expect(summary.buckets.last.averageFat, 3);
    expect(summary.buckets.last.averageCarbs, 15);
    expect(summary.buckets[6].averageCalories, 300);
    expect(
      summary.buckets.every((b) => b.start.weekday == DateTime.monday),
      isTrue,
    );
  });

  test(
    'monthly bars average logged days rather than meals or calendar length',
    () {
      final summary = NutritionSummary.fromItems(
        [
          meal(DateTime(2023, 8, 1), calories: 200),
          meal(DateTime(2024, 2, 1), calories: 1000),
          meal(DateTime(2024, 2, 1, 12), calories: 500),
          meal(DateTime(2024, 2, 29, 23, 59), calories: 2500),
          meal(DateTime(2024, 3, 1), calories: 400),
        ],
        period: NutritionPeriod.month,
        now: DateTime(2024, 3, 3),
      );
      expect(summary.buckets, hasLength(8));
      expect(summary.buckets.first.start, DateTime(2023, 8));
      expect(summary.buckets.last.start, DateTime(2024, 3));
      expect(summary.buckets.last.end, DateTime(2024, 4));
      expect(summary.buckets[6].averageCalories, 2000);
      expect(summary.buckets[6].loggedDays, 2);
      expect(summary.buckets[6].averageProtein, 7.5);
      expect(summary.buckets[6].averageFat, 4.5);
      expect(summary.buckets[6].averageCarbs, 22.5);

      expect(summary.buckets.first.averageCalories, 200);
      expect(summary.buckets.last.averageCalories, 400);
    },
  );

  test(
    'empty history still supplies eight finite zero averages in every mode',
    () {
      for (final period in NutritionPeriod.values) {
        final summary = NutritionSummary.fromItems(
          [],
          period: period,
          now: now,
        );
        expect(summary.hasData, isFalse);
        expect(summary.buckets, hasLength(8));
        expect(summary.buckets.every((b) => b.averageCalories == 0), isTrue);
        expect(summary.buckets.every((b) => b.loggedDays == 0), isTrue);
        expect(
          summary.buckets.every(
            (b) =>
                b.averageProtein == 0 &&
                b.averageFat == 0 &&
                b.averageCarbs == 0,
          ),
          isTrue,
        );
      }
    },
  );
}
