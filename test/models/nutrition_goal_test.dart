import 'package:flutter_test/flutter_test.dart';
import 'package:plate_track_ai/shared/models/user_profile.dart';

UserProfile profile({
  NutritionGoal goal = NutritionGoal.maintenance,
  CalorieReduction reduction = CalorieReduction.moderate,
}) => UserProfile(
  id: 'nutrition',
  age: 35,
  weight: 80,
  height: 180,
  gender: Gender.male,
  activityLevel: ActivityLevel.moderatelyActive,
  createdAt: DateTime(2026),
  nutritionGoal: goal,
  calorieReduction: reduction,
);

void main() {
  test(
    'maintenance is the default and uses the full estimated expenditure',
    () {
      final value = profile();
      expect(value.nutritionGoal, NutritionGoal.maintenance);
      expect(value.calculateCalorieTarget(), closeTo(2983.5, 0.0001));
      final targets = value.calculateNutritionTargets();
      expect(targets['protein'], closeTo(149.175, 0.0001));
      expect(targets['carbs'], closeTo(372.9375, 0.0001));
      expect(targets['fat'], closeTo(99.45, 0.0001));
    },
  );

  for (final entry in {
    CalorieReduction.gentle: 2685.15,
    CalorieReduction.moderate: 2535.975,
    CalorieReduction.substantial: 2386.8,
  }.entries) {
    test('${entry.key} reduces intake but not maintenance expenditure', () {
      final value = profile(
        goal: NutritionGoal.weightLoss,
        reduction: entry.key,
      );
      expect(value.calculateTDEE(), closeTo(2983.5, 0.0001));
      expect(value.calculateCalorieTarget(), closeTo(entry.value, 0.0001));
      final targets = value.calculateNutritionTargets();
      expect(targets['calories'], closeTo(entry.value, 0.0001));
      expect(targets['protein'], closeTo(112, 0.0001));
      expect(targets['fat']! * 9 / entry.value, closeTo(0.30, 0.0001));
      expect(
        targets['protein']! * 4 + targets['fat']! * 9 + targets['carbs']! * 4,
        closeTo(entry.value, 0.0001),
      );
    });
  }

  test('unsupported weight-loss profiles do not receive automatic macros', () {
    final loss = profile(goal: NutritionGoal.weightLoss);
    for (final unsupported in [
      loss.copyWith(age: 17),
      loss.copyWith(weight: 45, height: 180),
      loss.copyWith(
        age: 120,
        weight: 40,
        height: 100,
        gender: Gender.female,
        activityLevel: ActivityLevel.sedentary,
        calorieReduction: CalorieReduction.substantial,
      ),
    ]) {
      expect(unsupported.canUseWeightLossTargets, isFalse);
      expect(unsupported.calculateCalorieTarget, throwsStateError);
      expect(unsupported.calculateNutritionTargets, throwsStateError);
    }
    expect(loss.canUseWeightLossTargets, isTrue);
  });

  test('goal settings survive copy, equality and JSON', () {
    final original = profile();
    final changed = original.copyWith(
      nutritionGoal: NutritionGoal.weightLoss,
      calorieReduction: CalorieReduction.substantial,
    );
    expect(changed, isNot(original));
    expect(
      changed.copyWith(weight: 78).nutritionGoal,
      NutritionGoal.weightLoss,
    );
    expect(
      changed.copyWith(weight: 78).calorieReduction,
      CalorieReduction.substantial,
    );
    expect(UserProfile.fromJson(changed.toJson()), changed);
    expect(
      changed
          .copyWith(nutritionGoal: NutritionGoal.maintenance)
          .calculateCalorieTarget(),
      closeTo(2983.5, 0.0001),
    );
  });

  test('old JSON profiles default to maintenance without a deficit', () {
    final json = profile().toJson()
      ..remove('nutritionGoal')
      ..remove('calorieReduction');
    final restored = UserProfile.fromJson(json);
    expect(restored.nutritionGoal, NutritionGoal.maintenance);
    expect(restored.calorieReduction, CalorieReduction.moderate);
    expect(restored.calculateCalorieTarget(), restored.calculateTDEE());
  });
}
