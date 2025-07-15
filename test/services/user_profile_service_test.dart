import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:hive_test/hive_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:plate_track_ai/core/services/user_profile_service.dart';
import 'package:plate_track_ai/shared/models/user_profile.dart';
import 'package:plate_track_ai/shared/models/user_profile_adapters.dart';

void main() {
  group('UserProfileService', () {
    late UserProfileService service;

    setUpAll(() async {
      await setUpTestHive();
      if (!Hive.isAdapterRegistered(2)) {
        Hive.registerAdapter(UserProfileAdapter());
      }
      if (!Hive.isAdapterRegistered(3)) {
        Hive.registerAdapter(GenderAdapter());
      }
      if (!Hive.isAdapterRegistered(4)) {
        Hive.registerAdapter(ActivityLevelAdapter());
      }
    });

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      service = UserProfileService();
      await service.initialize();
    });

    tearDown(() async {
      // Clean up for next test
      if (service.hasUserProfile) {
        await service.deleteProfile();
      }
    });

    tearDownAll(() async {
      await Hive.close();
    });

    group('Initialization', () {
      test('should initialize without error', () async {
        final newService = UserProfileService();
        await expectLater(newService.initialize(), completes);
      });

      test('should have no profile initially', () {
        expect(service.hasUserProfile, isFalse);
        expect(service.currentProfile, isNull);
      });
    });

    group('Profile Creation', () {
      test('should create profile successfully', () async {
        final profile = await service.createProfile(
          age: 25,
          weight: 70.0,
          height: 175.0,
          gender: Gender.male,
          activityLevel: ActivityLevel.moderatelyActive,
        );

        expect(profile.age, 25);
        expect(profile.weight, 70.0);
        expect(profile.height, 175.0);
        expect(profile.gender, Gender.male);
        expect(profile.activityLevel, ActivityLevel.moderatelyActive);
        expect(profile.id, isNotEmpty);
        expect(profile.createdAt, isNotNull);
        expect(service.hasUserProfile, isTrue);
        expect(service.currentProfile, equals(profile));
      });

      test('should create profile with minimum valid values', () async {
        final profile = await service.createProfile(
          age: 18,
          weight: 40.0,
          height: 140.0,
          gender: Gender.female,
          activityLevel: ActivityLevel.sedentary,
        );

        expect(profile.age, 18);
        expect(profile.weight, 40.0);
        expect(profile.height, 140.0);
        expect(profile.gender, Gender.female);
        expect(profile.activityLevel, ActivityLevel.sedentary);
      });

      test('should create profile with maximum reasonable values', () async {
        final profile = await service.createProfile(
          age: 80,
          weight: 150.0,
          height: 220.0,
          gender: Gender.male,
          activityLevel: ActivityLevel.extremelyActive,
        );

        expect(profile.age, 80);
        expect(profile.weight, 150.0);
        expect(profile.height, 220.0);
        expect(profile.gender, Gender.male);
        expect(profile.activityLevel, ActivityLevel.extremelyActive);
      });

      test('should generate unique IDs for different profiles', () async {
        final profile1 = await service.createProfile(
          age: 25,
          weight: 70.0,
          height: 175.0,
          gender: Gender.male,
          activityLevel: ActivityLevel.moderatelyActive,
        );

        await service.deleteProfile();

        final profile2 = await service.createProfile(
          age: 30,
          weight: 80.0,
          height: 180.0,
          gender: Gender.female,
          activityLevel: ActivityLevel.veryActive,
        );

        expect(profile1.id, isNot(equals(profile2.id)));
      });
    });

    group('Profile Updates', () {
      late UserProfile initialProfile;

      setUp(() async {
        initialProfile = await service.createProfile(
          age: 25,
          weight: 70.0,
          height: 175.0,
          gender: Gender.male,
          activityLevel: ActivityLevel.moderatelyActive,
        );
      });

      test('should update profile age', () async {
        final updated = await service.updateProfile(age: 26);
        
        expect(updated.age, 26);
        expect(updated.weight, initialProfile.weight);
        expect(updated.height, initialProfile.height);
        expect(updated.gender, initialProfile.gender);
        expect(updated.activityLevel, initialProfile.activityLevel);
        expect(updated.updatedAt, isNotNull);
        expect(service.currentProfile, equals(updated));
      });

      test('should update profile weight', () async {
        final updated = await service.updateProfile(weight: 75.0);
        
        expect(updated.weight, 75.0);
        expect(updated.age, initialProfile.age);
        expect(updated.updatedAt, isNotNull);
      });

      test('should update profile height', () async {
        final updated = await service.updateProfile(height: 180.0);
        
        expect(updated.height, 180.0);
        expect(updated.age, initialProfile.age);
        expect(updated.weight, initialProfile.weight);
      });

      test('should update profile gender', () async {
        final updated = await service.updateProfile(gender: Gender.female);
        
        expect(updated.gender, Gender.female);
        expect(updated.age, initialProfile.age);
        expect(updated.weight, initialProfile.weight);
        expect(updated.height, initialProfile.height);
      });

      test('should update profile activity level', () async {
        final updated = await service.updateProfile(
          activityLevel: ActivityLevel.veryActive,
        );
        
        expect(updated.activityLevel, ActivityLevel.veryActive);
        expect(updated.age, initialProfile.age);
        expect(updated.weight, initialProfile.weight);
      });

      test('should update multiple fields at once', () async {
        final updated = await service.updateProfile(
          age: 30,
          weight: 80.0,
          height: 180.0,
          gender: Gender.female,
          activityLevel: ActivityLevel.veryActive,
        );
        
        expect(updated.age, 30);
        expect(updated.weight, 80.0);
        expect(updated.height, 180.0);
        expect(updated.gender, Gender.female);
        expect(updated.activityLevel, ActivityLevel.veryActive);
        expect(updated.id, initialProfile.id);
        expect(updated.createdAt, initialProfile.createdAt);
        expect(updated.updatedAt, isNotNull);
      });

      test('should throw when updating without profile', () async {
        await service.deleteProfile();
        
        expect(
          () => service.updateProfile(age: 30),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('Profile Deletion', () {
      test('should delete profile successfully', () async {
        await service.createProfile(
          age: 25,
          weight: 70.0,
          height: 175.0,
          gender: Gender.male,
          activityLevel: ActivityLevel.moderatelyActive,
        );

        expect(service.hasUserProfile, isTrue);
        
        await service.deleteProfile();
        
        expect(service.hasUserProfile, isFalse);
        expect(service.currentProfile, isNull);
      });

      test('should handle deleting when no profile exists', () async {
        expect(service.hasUserProfile, isFalse);
        
        await expectLater(service.deleteProfile(), completes);
        
        expect(service.hasUserProfile, isFalse);
      });
    });

    group('Nutrition Calculations', () {
      test('should calculate daily calorie needs', () async {
        await service.createProfile(
          age: 30,
          weight: 80.0,
          height: 180.0,
          gender: Gender.male,
          activityLevel: ActivityLevel.moderatelyActive,
        );

        final calories = service.calculateDailyCalorieNeeds();
        expect(calories, isNotNull);
        expect(calories!, greaterThan(0));
        
        final expectedBMR = 260 + (9.65 * 80) + (5.73 * 180) - (5.08 * 30);
        final expectedTDEE = expectedBMR * ActivityLevel.moderatelyActive.multiplier;
        expect(calories, closeTo(expectedTDEE, 0.01));
      });

      test('should calculate BMR', () async {
        await service.createProfile(
          age: 25,
          weight: 65.0,
          height: 165.0,
          gender: Gender.female,
          activityLevel: ActivityLevel.lightlyActive,
        );

        final bmr = service.calculateBMR();
        expect(bmr, isNotNull);
        expect(bmr!, greaterThan(0));
        
        final expectedBMR = 43 + (7.38 * 65) + (6.07 * 165) - (2.31 * 25);
        expect(bmr, closeTo(expectedBMR, 0.01));
      });

      test('should return null when no profile exists', () {
        expect(service.calculateDailyCalorieNeeds(), isNull);
        expect(service.calculateBMR(), isNull);
        expect(service.getNutritionTargets(), isNull);
      });

      test('should get nutrition targets', () async {
        await service.createProfile(
          age: 30,
          weight: 70.0,
          height: 170.0,
          gender: Gender.male,
          activityLevel: ActivityLevel.moderatelyActive,
        );

        final targets = service.getNutritionTargets();
        expect(targets, isNotNull);
        expect(targets!['calories'], greaterThan(0));
        expect(targets['protein'], greaterThan(0));
        expect(targets['carbs'], greaterThan(0));
        expect(targets['fat'], greaterThan(0));
        
        // Verify macro distribution percentages
        final calories = targets['calories']!;
        final proteinCalories = targets['protein']! * 4; // 4 cal/g
        final carbsCalories = targets['carbs']! * 4; // 4 cal/g
        final fatCalories = targets['fat']! * 9; // 9 cal/g
        
        expect(proteinCalories / calories, closeTo(0.20, 0.01)); // 20%
        expect(carbsCalories / calories, closeTo(0.50, 0.01)); // 50%
        expect(fatCalories / calories, closeTo(0.30, 0.01)); // 30%
      });
    });

    group('Service Persistence', () {
      test('should persist profile across service instances', () async {
        // Create profile with first service instance
        final profile = await service.createProfile(
          age: 35,
          weight: 85.0,
          height: 185.0,
          gender: Gender.male,
          activityLevel: ActivityLevel.veryActive,
        );

        // Create new service instance
        final newService = UserProfileService();
        await newService.initialize();

        // Should load the same profile
        expect(newService.hasUserProfile, isTrue);
        expect(newService.currentProfile?.id, profile.id);
        expect(newService.currentProfile?.age, profile.age);
        expect(newService.currentProfile?.weight, profile.weight);
      });
    });
  });
}
