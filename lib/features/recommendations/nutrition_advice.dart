import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// The palette role a tip's icon takes. Storing a role rather than a `Color`
/// keeps the rules free of theme lookups, so they can run before a widget tree
/// exists and be unit-tested without pumping one.
enum TipTone { protein, carbs, fat, warning, danger, success, info, accent }

/// One piece of advice: what to do, why, and how to colour it.
@immutable
class NutritionTip {
  const NutritionTip({
    required this.title,
    required this.description,
    required this.icon,
    required this.tone,
  });

  final String title;
  final String description;
  final IconData icon;
  final TipTone tone;
}

/// Daily targets a week's intake is judged against.
@immutable
class NutritionTargets {
  const NutritionTargets({
    this.calories = 2000,
    this.protein = 80,
    this.carbs = 250,
    this.fat = 70,
  });

  /// Reads the map [UserProfileService.getNutritionTargets] returns, falling
  /// back to the defaults for anything absent.
  factory NutritionTargets.fromMap(Map<String, double>? map) {
    const fallback = NutritionTargets();
    if (map == null) return fallback;
    return NutritionTargets(
      calories: map['calories'] ?? fallback.calories,
      protein: map['protein'] ?? fallback.protein,
      carbs: map['carbs'] ?? fallback.carbs,
      fat: map['fat'] ?? fallback.fat,
    );
  }

  final double calories;
  final double protein;
  final double carbs;
  final double fat;
}

/// Average daily intake, as measured over the days that were logged.
@immutable
class NutritionAverages {
  const NutritionAverages({
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
  });

  final double calories;
  final double protein;
  final double carbs;
  final double fat;
}

/// Turns a week of averages into personalised advice.
///
/// Pure: same inputs, same tips, no `BuildContext`. Translation still happens
/// here via `tr()`, which reads a global and needs no context.
class NutritionAdvice {
  NutritionAdvice._();

  /// Thresholds the rules fire on, named so the intent is legible at the call
  /// site rather than appearing as bare multipliers.
  static const _wellUnder = 0.8;
  static const _wellOver = 1.2;
  static const _carbsWellOver = 1.3;

  /// Below this many tips, general advice is appended so the list never looks
  /// empty just because the user is on target.
  static const _minimumTips = 3;

  static List<NutritionTip> forWeek({
    required NutritionAverages averages,
    required NutritionTargets targets,
  }) {
    final tips = <NutritionTip>[];

    if (averages.calories < targets.calories * _wellUnder) {
      tips.add(
        NutritionTip(
          title: 'increase_calorie_intake'.tr(),
          description: 'increase_calorie_intake_desc'.tr(
            namedArgs: {
              'avg_calories': averages.calories.toInt().toString(),
              'target_calories': targets.calories.toInt().toString(),
            },
          ),
          icon: Icons.add_circle,
          tone: TipTone.warning,
        ),
      );
    } else if (averages.calories > targets.calories * _wellOver) {
      tips.add(
        NutritionTip(
          title: 'reduce_calorie_intake'.tr(),
          description: 'reduce_calorie_intake_desc'.tr(
            namedArgs: {
              'avg_calories': averages.calories.toInt().toString(),
              'target_calories': targets.calories.toInt().toString(),
            },
          ),
          icon: Icons.remove_circle,
          tone: TipTone.danger,
        ),
      );
    }

    if (averages.protein < targets.protein * _wellUnder) {
      tips.add(
        NutritionTip(
          title: 'increase_protein_intake'.tr(),
          description: 'increase_protein_intake_desc'.tr(),
          icon: Icons.fitness_center,
          tone: TipTone.protein,
        ),
      );
    }

    // Guarded: a zero target would make the ratio infinite (or NaN at 0/0) and
    // fire this rule for every user whose profile has no carb target.
    if (targets.carbs > 0 &&
        averages.carbs / targets.carbs > _carbsWellOver) {
      tips.add(
        NutritionTip(
          title: 'reduce_simple_carbs'.tr(),
          description: 'reduce_simple_carbs_desc'.tr(),
          icon: Icons.grain,
          tone: TipTone.carbs,
        ),
      );
    }

    if (averages.fat > targets.fat * _wellOver) {
      tips.add(
        NutritionTip(
          title: 'monitor_fat_intake'.tr(),
          description: 'monitor_fat_intake_desc'.tr(),
          icon: Icons.opacity,
          tone: TipTone.fat,
        ),
      );
    }

    tips.add(
      NutritionTip(
        title: 'stay_hydrated'.tr(),
        description: 'stay_hydrated_desc'.tr(),
        icon: Icons.water_drop,
        tone: TipTone.fat,
      ),
    );

    if (tips.length < _minimumTips) {
      tips.addAll([
        NutritionTip(
          title: 'eat_variety_of_foods'.tr(),
          description: 'eat_variety_of_foods_desc'.tr(),
          icon: Icons.diversity_1,
          tone: TipTone.accent,
        ),
        NutritionTip(
          title: 'regular_meal_pattern'.tr(),
          description: 'regular_meal_pattern_desc'.tr(),
          icon: Icons.schedule,
          tone: TipTone.info,
        ),
      ]);
    }

    return tips;
  }

  /// General advice, for when there is no data to personalise against.
  static List<NutritionTip> general() => [
    NutritionTip(
      title: 'balance_macronutrients'.tr(),
      description: 'balance_macronutrients_desc'.tr(),
      icon: Icons.balance,
      tone: TipTone.protein,
    ),
    NutritionTip(
      title: 'stay_hydrated'.tr(),
      description: 'stay_hydrated_desc'.tr(),
      icon: Icons.water_drop,
      tone: TipTone.fat,
    ),
    NutritionTip(
      title: 'portion_control'.tr(),
      description: 'portion_control_desc'.tr(),
      icon: Icons.pie_chart,
      tone: TipTone.warning,
    ),
    NutritionTip(
      title: 'eat_more_whole_foods'.tr(),
      description: 'eat_more_whole_foods_desc'.tr(),
      icon: Icons.restaurant,
      tone: TipTone.success,
    ),
  ];
}
