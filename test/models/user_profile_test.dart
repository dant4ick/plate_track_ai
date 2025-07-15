import 'package:flutter_test/flutter_test.dart';
import 'package:plate_track_ai/shared/models/user_profile.dart';

void main() {
  group('UserProfile', () {
    test('should calculate BMR for male', () {
      final profile = UserProfile(
        id: '1',
        age: 30,
        weight: 80,
        height: 180,
        gender: Gender.male,
        activityLevel: ActivityLevel.moderatelyActive,
        createdAt: DateTime.now(),
      );
      final bmr = profile.calculateBMR();
      expect(bmr, closeTo(260 + 9.65 * 80 + 5.73 * 180 - 5.08 * 30, 0.01));
    });

    test('should calculate BMR for female', () {
      final profile = UserProfile(
        id: '2',
        age: 25,
        weight: 60,
        height: 165,
        gender: Gender.female,
        activityLevel: ActivityLevel.lightlyActive,
        createdAt: DateTime.now(),
      );
      final bmr = profile.calculateBMR();
      expect(bmr, closeTo(43 + 7.38 * 60 + 6.07 * 165 - 2.31 * 25, 0.01));
    });

    test('should calculate TDEE', () {
      final profile = UserProfile(
        id: '2',
        age: 25,
        weight: 70,
        height: 170,
        gender: Gender.female,
        activityLevel: ActivityLevel.veryActive,
        createdAt: DateTime.now(),
      );
      final tdee = profile.calculateTDEE();
      final bmr = profile.calculateBMR();
      expect(tdee, closeTo(bmr * ActivityLevel.veryActive.multiplier, 0.01));
    });

    test('should calculate BMR with edge case values', () {
      // Test with minimum reasonable values
      final profile1 = UserProfile(
        id: '3',
        age: 18,
        weight: 40,
        height: 140,
        gender: Gender.female,
        activityLevel: ActivityLevel.sedentary,
        createdAt: DateTime.now(),
      );
      final bmr1 = profile1.calculateBMR();
      expect(bmr1, greaterThan(0));

      // Test with maximum reasonable values
      final profile2 = UserProfile(
        id: '4',
        age: 80,
        weight: 120,
        height: 200,
        gender: Gender.male,
        activityLevel: ActivityLevel.extremelyActive,
        createdAt: DateTime.now(),
      );
      final bmr2 = profile2.calculateBMR();
      expect(bmr2, greaterThan(0));
    });

    test('should copyWith updated fields', () {
      final profile = UserProfile(
        id: '3',
        age: 40,
        weight: 90,
        height: 175,
        gender: Gender.male,
        activityLevel: ActivityLevel.sedentary,
        createdAt: DateTime.now(),
      );
      final updated = profile.copyWith(weight: 95, age: 41);
      expect(updated.weight, 95);
      expect(updated.age, 41);
      expect(updated.height, profile.height);
      expect(updated.id, profile.id);
      expect(updated.createdAt, profile.createdAt);
    });

    test('should copyWith preserve original when no changes', () {
      final createdAt = DateTime.now();
      final profile = UserProfile(
        id: '5',
        age: 30,
        weight: 70,
        height: 170,
        gender: Gender.female,
        activityLevel: ActivityLevel.moderatelyActive,
        createdAt: createdAt,
      );
      final updated = profile.copyWith();
      expect(updated.age, profile.age);
      expect(updated.weight, profile.weight);
      expect(updated.height, profile.height);
      expect(updated.gender, profile.gender);
      expect(updated.activityLevel, profile.activityLevel);
      expect(updated.createdAt, createdAt);
    });

    test('should convert to and from JSON', () {
      final createdAt = DateTime.now();
      final updatedAt = DateTime.now().add(Duration(hours: 1));
      final profile = UserProfile(
        id: '6',
        age: 35,
        weight: 75,
        height: 175,
        gender: Gender.male,
        activityLevel: ActivityLevel.veryActive,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );
      
      final json = profile.toJson();
      final fromJson = UserProfile.fromJson(json);
      
      expect(fromJson.id, profile.id);
      expect(fromJson.age, profile.age);
      expect(fromJson.weight, profile.weight);
      expect(fromJson.height, profile.height);
      expect(fromJson.gender, profile.gender);
      expect(fromJson.activityLevel, profile.activityLevel);
      expect(fromJson.createdAt, profile.createdAt);
      expect(fromJson.updatedAt, profile.updatedAt);
    });

    test('should handle JSON with null updatedAt', () {
      final profile = UserProfile(
        id: '7',
        age: 25,
        weight: 65,
        height: 160,
        gender: Gender.female,
        activityLevel: ActivityLevel.lightlyActive,
        createdAt: DateTime.now(),
      );
      
      final json = profile.toJson();
      expect(json['updatedAt'], isNull);
      
      final fromJson = UserProfile.fromJson(json);
      expect(fromJson.updatedAt, isNull);
    });

    test('should maintain equality with same values', () {
      final createdAt = DateTime.now();
      final profile1 = UserProfile(
        id: 'same-id',
        age: 30,
        weight: 70,
        height: 170,
        gender: Gender.male,
        activityLevel: ActivityLevel.moderatelyActive,
        createdAt: createdAt,
      );
      final profile2 = UserProfile(
        id: 'same-id',
        age: 30,
        weight: 70,
        height: 170,
        gender: Gender.male,
        activityLevel: ActivityLevel.moderatelyActive,
        createdAt: createdAt,
      );
      expect(profile1, equals(profile2));
    });
  });

  group('Gender', () {
    test('should have correct values', () {
      expect(Gender.male, isA<Gender>());
      expect(Gender.female, isA<Gender>());
      expect(Gender.values.length, 2);
    });

    test('should have correct enum ordering', () {
      expect(Gender.values[0], Gender.male);
      expect(Gender.values[1], Gender.female);
    });
  });

  group('ActivityLevel', () {
    test('should have correct multiplier', () {
      expect(ActivityLevel.sedentary.multiplier, 1.40);
      expect(ActivityLevel.lightlyActive.multiplier, 1.55);
      expect(ActivityLevel.moderatelyActive.multiplier, 1.70);
      expect(ActivityLevel.veryActive.multiplier, 1.95);
      expect(ActivityLevel.extremelyActive.multiplier, 2.20);
    });

    test('should have multipliers in ascending order', () {
      final multipliers = ActivityLevel.values.map((level) => level.multiplier).toList();
      for (int i = 1; i < multipliers.length; i++) {
        expect(multipliers[i], greaterThan(multipliers[i - 1]));
      }
    });

    test('should have all required activity levels', () {
      expect(ActivityLevel.values.length, 5);
      expect(ActivityLevel.values.contains(ActivityLevel.sedentary), isTrue);
      expect(ActivityLevel.values.contains(ActivityLevel.lightlyActive), isTrue);
      expect(ActivityLevel.values.contains(ActivityLevel.moderatelyActive), isTrue);
      expect(ActivityLevel.values.contains(ActivityLevel.veryActive), isTrue);
      expect(ActivityLevel.values.contains(ActivityLevel.extremelyActive), isTrue);
    });

    test('should have reasonable multiplier ranges', () {
      for (final level in ActivityLevel.values) {
        expect(level.multiplier, greaterThan(1.0));
        expect(level.multiplier, lessThan(3.0));
      }
    });
  });
}
