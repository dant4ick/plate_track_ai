import 'package:equatable/equatable.dart';
import 'package:hive/hive.dart';

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

  const UserProfile({
    required this.id,
    required this.age,
    required this.weight,
    required this.height,
    required this.gender,
    required this.activityLevel,
    required this.createdAt,
    this.updatedAt,
  });

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
        return 'Male';
      case Gender.female:
        return 'Female';
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
        return 'Sedentary';
      case ActivityLevel.lightlyActive:
        return 'Lightly Active';
      case ActivityLevel.moderatelyActive:
        return 'Moderately Active';
      case ActivityLevel.veryActive:
        return 'Very Active';
      case ActivityLevel.extremelyActive:
        return 'Extremely Active';
    }
  }

  String get description {
    switch (this) {
      case ActivityLevel.sedentary:
        return 'Little or no exercise';
      case ActivityLevel.lightlyActive:
        return 'Light exercise 1-3 days/week';
      case ActivityLevel.moderatelyActive:
        return 'Moderate exercise 3-5 days/week';
      case ActivityLevel.veryActive:
        return 'Hard exercise 6-7 days/week';
      case ActivityLevel.extremelyActive:
        return 'Very hard exercise & physical job';
    }
  }

  double get multiplier {
    switch (this) {
      case ActivityLevel.sedentary:
        return 1.2;
      case ActivityLevel.lightlyActive:
        return 1.375;
      case ActivityLevel.moderatelyActive:
        return 1.55;
      case ActivityLevel.veryActive:
        return 1.725;
      case ActivityLevel.extremelyActive:
        return 1.9;
    }
  }
}
