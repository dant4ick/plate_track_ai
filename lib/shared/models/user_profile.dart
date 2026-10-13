import 'package:equatable/equatable.dart';
import 'package:hive/hive.dart';
import 'package:easy_localization/easy_localization.dart';

@HiveType(typeId: 2)
class UserProfile extends Equatable {
  @HiveField(0)
  final String id;
  
  @HiveField(1)
  final int age;
  
  @HiveField(2)
  final double weight; // in kg
  
  @HiveField(3)
  final double height; // in cm
  
  @HiveField(4)
  final Gender gender;
  
  @HiveField(5)
  final ActivityLevel activityLevel;
  
  @HiveField(6)
  final DateTime createdAt;
  
  @HiveField(7)
  final DateTime? updatedAt;

  /// Weight when the user started tracking, in kg. Null on profiles created
  /// before goal tracking existed — [effectiveStartWeight] covers that case.
  @HiveField(8)
  final double? startWeight;

  /// Target weight in kg, or null if the user has not set a goal.
  @HiveField(9)
  final double? goalWeight;

  const UserProfile({
    required this.id,
    required this.age,
    required this.weight,
    required this.height,
    required this.gender,
    required this.activityLevel,
    required this.createdAt,
    this.updatedAt,
    this.startWeight,
    this.goalWeight,
  });

  /// The weight the goal is measured from. Profiles saved before goal tracking
  /// have no recorded start, so today's weight stands in and progress reads 0
  /// rather than being unavailable.
  double get effectiveStartWeight => startWeight ?? weight;

  /// How far the user is from [effectiveStartWeight] to [goalWeight], in 0..1.
  ///
  /// Null when there is nothing to measure: no goal set, or a goal equal to the
  /// start (which would divide by zero). Works in both directions — losing and
  /// gaining — because it is the *travelled* fraction of the total distance,
  /// not a comparison of magnitudes.
  double? get weightProgress {
    final goal = goalWeight;
    if (goal == null) return null;

    final start = effectiveStartWeight;
    final distance = goal - start;
    if (distance == 0) return null;

    return ((weight - start) / distance).clamp(0.0, 1.0);
  }

  /// Body mass index, kg/m².
  double get bmi => weight / ((height / 100) * (height / 100));

  /// The lowest weight that still counts as a healthy BMI (18.5) at [heightCm].
  ///
  /// Used as the floor for goal weights: a target below this would be a target
  /// for being underweight, which the app should not help set.
  static double minimumHealthyWeight(double heightCm) {
    final metres = heightCm / 100;
    return 18.5 * metres * metres;
  }

  /// [minimumHealthyWeight] at this profile's height.
  double get minimumGoalWeight => minimumHealthyWeight(height);

  // Calculate BMR (Basal Metabolic Rate) using the provided formulas
  double calculateBMR() {
    switch (gender) {
      case Gender.male:
        return 260 + (9.65 * weight) + (5.73 * height) - (5.08 * age);
      case Gender.female:
        return 43 + (7.38 * weight) + (6.07 * height) - (2.31 * age);
    }
  }

  // Calculate Total Daily Energy Expenditure (TDEE) using activity level multiplier
  double calculateTDEE() {
    final bmr = calculateBMR();
    return bmr * activityLevel.multiplier;
  }

  UserProfile copyWith({
    String? id,
    int? age,
    double? weight,
    double? height,
    Gender? gender,
    ActivityLevel? activityLevel,
    DateTime? createdAt,
    DateTime? updatedAt,
    double? startWeight,
    double? goalWeight,
    bool clearGoalWeight = false,
  }) {
    return UserProfile(
      id: id ?? this.id,
      age: age ?? this.age,
      weight: weight ?? this.weight,
      height: height ?? this.height,
      gender: gender ?? this.gender,
      activityLevel: activityLevel ?? this.activityLevel,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      startWeight: startWeight ?? this.startWeight,
      // A null `goalWeight` means "leave it alone", which is what every other
      // field here means too — so removing a goal needs its own flag rather
      // than being expressible as a null argument.
      goalWeight: clearGoalWeight ? null : (goalWeight ?? this.goalWeight),
    );
  }

  @override
  List<Object?> get props => [
        id,
        age,
        weight,
        height,
        gender,
        activityLevel,
        createdAt,
        updatedAt,
        startWeight,
        goalWeight,
      ];

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'age': age,
      'weight': weight,
      'height': height,
      'gender': gender.name,
      'activityLevel': activityLevel.name,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'startWeight': startWeight,
      'goalWeight': goalWeight,
    };
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'],
      age: json['age'],
      weight: json['weight'],
      height: json['height'],
      gender: Gender.values.firstWhere((e) => e.name == json['gender']),
      activityLevel: ActivityLevel.values.firstWhere((e) => e.name == json['activityLevel']),
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
      startWeight: (json['startWeight'] as num?)?.toDouble(),
      goalWeight: (json['goalWeight'] as num?)?.toDouble(),
    );
  }
}

@HiveType(typeId: 3)
enum Gender {
  @HiveField(0)
  male,
  @HiveField(1)
  female;

  String get displayName {
    switch (this) {
      case Gender.male:
        return 'male'.tr();
      case Gender.female:
        return 'female'.tr();
    }
  }
}

@HiveType(typeId: 4)
enum ActivityLevel {
  @HiveField(0)
  sedentary,
  @HiveField(1)
  lightlyActive,
  @HiveField(2)
  moderatelyActive,
  @HiveField(3)
  veryActive,
  @HiveField(4)
  extremelyActive;

  String get displayName {
    switch (this) {
      case ActivityLevel.sedentary:
        return 'activity_sedentary'.tr();
      case ActivityLevel.lightlyActive:
        return 'activity_lightly_active'.tr();
      case ActivityLevel.moderatelyActive:
        return 'activity_moderately_active'.tr();
      case ActivityLevel.veryActive:
        return 'activity_very_active'.tr();
      case ActivityLevel.extremelyActive:
        return 'activity_extremely_active'.tr();
    }
  }

  String get description {
    switch (this) {
      case ActivityLevel.sedentary:
        return 'activity_sedentary_desc'.tr();
      case ActivityLevel.lightlyActive:
        return 'activity_lightly_active_desc'.tr();
      case ActivityLevel.moderatelyActive:
        return 'activity_moderately_active_desc'.tr();
      case ActivityLevel.veryActive:
        return 'activity_very_active_desc'.tr();
      case ActivityLevel.extremelyActive:
        return 'activity_extremely_active_desc'.tr();
    }
  }

  double get multiplier {
    switch (this) {
      case ActivityLevel.sedentary:
        return 1.40;
      case ActivityLevel.lightlyActive:
        return 1.55;
      case ActivityLevel.moderatelyActive:
        return 1.70;
      case ActivityLevel.veryActive:
        return 1.95;
      case ActivityLevel.extremelyActive:
        return 2.20;
    }
  }
}
