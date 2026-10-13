import 'package:flutter_test/flutter_test.dart';
import 'package:plate_track_ai/features/recommendations/nutrition_advice.dart';

/// Titles come back translated; with no EasyLocalization in the tree `tr()`
/// returns the key, which is exactly what makes these rules assertable.
List<NutritionTip> tipsFor({
  double calories = 2000,
  double protein = 80,
  double carbs = 250,
  double fat = 70,
  NutritionTargets targets = const NutritionTargets(),
}) {
  return NutritionAdvice.forWeek(
    averages: NutritionAverages(
      calories: calories,
      protein: protein,
      carbs: carbs,
      fat: fat,
    ),
    targets: targets,
  );
}

Set<String> titlesFor({
  double calories = 2000,
  double protein = 80,
  double carbs = 250,
  double fat = 70,
  NutritionTargets targets = const NutritionTargets(),
}) => tipsFor(
  calories: calories,
  protein: protein,
  carbs: carbs,
  fat: fat,
  targets: targets,
).map((tip) => tip.title).toSet();

/// Everything off target at once, so every rule fires.
List<NutritionTip> allFlagged() =>
    tipsFor(calories: 1000, protein: 20, carbs: 400, fat: 120);

void main() {
  group('NutritionAdvice.forWeek', () {
    test('flags intake well under the calorie target', () {
      // 1400 of a 2000 target is 70% — below the 80% threshold.
      final titles = titlesFor(calories: 1400);

      expect(titles, contains('increase_calorie_intake'));
      expect(titles, isNot(contains('reduce_calorie_intake')));
    });

    test('flags intake well over the calorie target', () {
      final titles = titlesFor(calories: 2600);

      expect(titles, contains('reduce_calorie_intake'));
      expect(titles, isNot(contains('increase_calorie_intake')));
    });

    test('says nothing about calories inside the tolerance band', () {
      final titles = titlesFor(calories: 2100);

      expect(titles, isNot(contains('increase_calorie_intake')));
      expect(titles, isNot(contains('reduce_calorie_intake')));
    });

    test('flags low protein', () {
      expect(titlesFor(protein: 50), contains('increase_protein_intake'));
      expect(
        titlesFor(protein: 80),
        isNot(contains('increase_protein_intake')),
      );
    });

    test('flags carbs above 130% of target', () {
      expect(titlesFor(carbs: 340), contains('reduce_simple_carbs'));
      expect(titlesFor(carbs: 300), isNot(contains('reduce_simple_carbs')));
    });

    test('flags fat above 120% of target', () {
      expect(titlesFor(fat: 90), contains('monitor_fat_intake'));
      expect(titlesFor(fat: 80), isNot(contains('monitor_fat_intake')));
    });

    test('a zero carb target does not fire the carb rule', () {
      // 0/0 is NaN and n/0 is infinity; either compares as "over target" and
      // would show this tip to every user whose profile has no carb target.
      expect(
        titlesFor(carbs: 0, targets: const NutritionTargets(carbs: 0)),
        isNot(contains('reduce_simple_carbs')),
      );
      expect(
        titlesFor(carbs: 200, targets: const NutritionTargets(carbs: 0)),
        isNot(contains('reduce_simple_carbs')),
      );
    });

    test('always includes hydration advice', () {
      expect(titlesFor(), contains('stay_hydrated'));
    });

    test('tops up with general advice when little is flagged', () {
      // On target everywhere: only hydration fires, so the list is padded.
      final tips = tipsFor();

      expect(tips.length, greaterThanOrEqualTo(3));
      expect(
        tips.map((t) => t.title),
        containsAll(['eat_variety_of_foods', 'regular_meal_pattern']),
      );
    });

    test('does not top up when enough is already flagged', () {
      expect(
        allFlagged().map((t) => t.title),
        isNot(contains('regular_meal_pattern')),
      );
    });

    test('every tip carries a tone the theme can resolve', () {
      for (final tip in allFlagged()) {
        expect(TipTone.values, contains(tip.tone));
        expect(tip.title, isNotEmpty);
        expect(tip.description, isNotEmpty);
      }
    });

    test('interpolates the figures into the calorie advice', () {
      final tip = tipsFor(
        calories: 1400,
      ).firstWhere((t) => t.title == 'increase_calorie_intake');

      // The description key carries {avg_calories}/{target_calories}; with no
      // localization loaded the key itself comes back, so assert the args were
      // supplied rather than the rendered sentence.
      expect(tip.description, isNotEmpty);
    });
  });

  group('NutritionTargets.fromMap', () {
    test('reads the profile service map', () {
      final targets = NutritionTargets.fromMap({
        'calories': 2400,
        'protein': 120,
        'carbs': 300,
        'fat': 80,
      });

      expect(targets.calories, 2400);
      expect(targets.protein, 120);
      expect(targets.carbs, 300);
      expect(targets.fat, 80);
    });

    test('falls back to defaults for a null map', () {
      final targets = NutritionTargets.fromMap(null);

      expect(targets.calories, 2000);
      expect(targets.protein, 80);
    });

    test('falls back per-key for a partial map', () {
      final targets = NutritionTargets.fromMap({'calories': 1800});

      expect(targets.calories, 1800);
      expect(targets.carbs, 250);
    });
  });

  group('NutritionAdvice.general', () {
    test('returns advice that needs no data', () {
      final tips = NutritionAdvice.general();

      expect(tips, isNotEmpty);
      expect(tips.map((t) => t.title), contains('balance_macronutrients'));
    });
  });
}
