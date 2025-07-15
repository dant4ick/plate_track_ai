import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:hive_test/hive_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:plate_track_ai/core/services/user_profile_service.dart';
import 'package:plate_track_ai/core/services/food_storage_service.dart';
import 'package:plate_track_ai/shared/models/user_profile.dart';
import 'package:plate_track_ai/shared/models/food_item.dart';
import 'package:plate_track_ai/shared/models/food_item_adapters.dart';
import 'package:plate_track_ai/shared/models/user_profile_adapters.dart';

void main() {
  group('Integration Tests', () {
    late UserProfileService userProfileService;
    late FoodStorageService foodStorageService;

    setUpAll(() async {
      await setUpTestHive();
      
      // Register all adapters
      if (!Hive.isAdapterRegistered(0)) {
        Hive.registerAdapter(FoodItemAdapter());
      }
      if (!Hive.isAdapterRegistered(1)) {
        Hive.registerAdapter(NutritionFactsAdapter());
      }
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
      userProfileService = UserProfileService();
      foodStorageService = FoodStorageService();
      
      await userProfileService.initialize();
      await foodStorageService.initialize();
    });

    tearDown(() async {
      // Clean up
      if (userProfileService.hasUserProfile) {
        await userProfileService.deleteProfile();
      }
      await foodStorageService.clearAllData();
    });

    tearDownAll(() async {
      await Hive.close();
    });

    group('User Onboarding and Food Tracking Flow', () {
      test('should complete full user journey', () async {
        // 1. User creates profile
        final profile = await userProfileService.createProfile(
          age: 30,
          weight: 75.0,
          height: 175.0,
          gender: Gender.male,
          activityLevel: ActivityLevel.moderatelyActive,
        );

        expect(userProfileService.hasUserProfile, isTrue);
        expect(profile.age, 30);

        // 2. User gets nutrition targets
        final targets = userProfileService.getNutritionTargets();
        expect(targets, isNotNull);
        expect(targets!['calories'], greaterThan(0));
        expect(targets['protein'], greaterThan(0));

        // 3. User tracks food throughout the day
        final breakfast = FoodItem(
          name: 'Oatmeal',
          calories: 300,
          nutritionFacts: NutritionFacts(
            protein: 10,
            carbs: 50,
            fat: 5,
            mass: 200,
          ),
          timestamp: DateTime.now().copyWith(hour: 8),
        );

        final lunch = FoodItem(
          name: 'Chicken Salad',
          calories: 450,
          nutritionFacts: NutritionFacts(
            protein: 35,
            carbs: 20,
            fat: 15,
            mass: 300,
          ),
          timestamp: DateTime.now().copyWith(hour: 13),
        );

        final dinner = FoodItem(
          name: 'Salmon with Rice',
          calories: 550,
          nutritionFacts: NutritionFacts(
            protein: 40,
            carbs: 45,
            fat: 18,
            mass: 350,
          ),
          timestamp: DateTime.now().copyWith(hour: 19),
        );

        await foodStorageService.saveFoodItem(breakfast);
        await foodStorageService.saveFoodItem(lunch);
        await foodStorageService.saveFoodItem(dinner);

        // 4. User checks daily progress
        final todayItems = await foodStorageService.getFoodItemsByDate(DateTime.now());
        expect(todayItems.length, 3);

        // Calculate total nutrition (values are per 100g, so with given masses it's different)
        double totalCalories = todayItems.fold(0.0, (sum, item) {
          final mass = item.nutritionFacts.mass ?? 100.0;
          return sum + (item.calories * mass / 100.0);
        });

        double totalProtein = todayItems.fold(0.0, (sum, item) {
          final mass = item.nutritionFacts.mass ?? 100.0;
          return sum + (item.nutritionFacts.protein * mass / 100.0);
        });

        // Expected calories: (300*200/100) + (450*300/100) + (550*350/100) = 600 + 1350 + 1925 = 3875
        expect(totalCalories, closeTo(3875, 10)); // Corrected calculation
        expect(totalProtein, closeTo(265, 10)); // (10*200/100) + (35*300/100) + (40*350/100) = 20 + 105 + 140 = 265

        // 5. Check if user is meeting targets
        final calorieTarget = targets['calories']!;
        final proteinTarget = targets['protein']!;

        expect(totalCalories / calorieTarget, lessThan(1.3)); // Within reasonable range
        expect(totalProtein / proteinTarget, greaterThan(0.8)); // Meeting protein needs
      });

      test('should handle profile updates affecting targets', () async {
        // Create initial profile
        await userProfileService.createProfile(
          age: 25,
          weight: 60.0,
          height: 165.0,
          gender: Gender.female,
          activityLevel: ActivityLevel.lightlyActive,
        );

        final initialTargets = userProfileService.getNutritionTargets();
        final initialCalories = initialTargets!['calories']!;

        // Update activity level (should increase calorie needs)
        await userProfileService.updateProfile(
          activityLevel: ActivityLevel.veryActive,
        );

        final updatedTargets = userProfileService.getNutritionTargets();
        final updatedCalories = updatedTargets!['calories']!;

        expect(updatedCalories, greaterThan(initialCalories));
      });

      test('should maintain data consistency across service restarts', () async {
        // Create profile and add food
        final profile = await userProfileService.createProfile(
          age: 35,
          weight: 80.0,
          height: 180.0,
          gender: Gender.male,
          activityLevel: ActivityLevel.moderatelyActive,
        );

        final foodItem = FoodItem(
          name: 'Test Food',
          calories: 200,
          nutritionFacts: NutritionFacts(
            protein: 15,
            carbs: 25,
            fat: 8,
            mass: 150,
          ),
        );

        await foodStorageService.saveFoodItem(foodItem);

        // Simulate app restart by creating new service instances
        final newUserService = UserProfileService();
        final newFoodService = FoodStorageService();

        await newUserService.initialize();
        await newFoodService.initialize();

        // Verify data persistence
        expect(newUserService.hasUserProfile, isTrue);
        expect(newUserService.currentProfile?.id, profile.id);

        final allFoodItems = await newFoodService.getAllFoodItems();
        expect(allFoodItems.length, 1);
        expect(allFoodItems.first.id, foodItem.id);
      });

      test('should handle multiple days of food tracking', () async {
        await userProfileService.createProfile(
          age: 28,
          weight: 70.0,
          height: 172.0,
          gender: Gender.female,
          activityLevel: ActivityLevel.moderatelyActive,
        );

        final today = DateTime.now();
        final yesterday = today.subtract(Duration(days: 1));
        final twoDaysAgo = today.subtract(Duration(days: 2));

        // Add food items for different days
        final todayFoods = [
          FoodItem(
            name: 'Today Breakfast',
            calories: 300,
            nutritionFacts: NutritionFacts(protein: 12, carbs: 40, fat: 8, mass: 200),
            timestamp: today,
          ),
          FoodItem(
            name: 'Today Lunch',
            calories: 400,
            nutritionFacts: NutritionFacts(protein: 25, carbs: 35, fat: 12, mass: 250),
            timestamp: today,
          ),
        ];

        final yesterdayFoods = [
          FoodItem(
            name: 'Yesterday Dinner',
            calories: 500,
            nutritionFacts: NutritionFacts(protein: 30, carbs: 45, fat: 15, mass: 300),
            timestamp: yesterday,
          ),
        ];

        final twoDaysAgoFoods = [
          FoodItem(
            name: 'Two Days Ago Snack',
            calories: 150,
            nutritionFacts: NutritionFacts(protein: 5, carbs: 20, fat: 6, mass: 100),
            timestamp: twoDaysAgo,
          ),
        ];

        // Save all items
        for (final item in [...todayFoods, ...yesterdayFoods, ...twoDaysAgoFoods]) {
          await foodStorageService.saveFoodItem(item);
        }

        // Verify day-specific filtering
        final todayItems = await foodStorageService.getFoodItemsByDate(today);
        final yesterdayItems = await foodStorageService.getFoodItemsByDate(yesterday);
        final twoDaysAgoItems = await foodStorageService.getFoodItemsByDate(twoDaysAgo);

        expect(todayItems.length, 2);
        expect(yesterdayItems.length, 1);
        expect(twoDaysAgoItems.length, 1);

        // Verify all items are stored
        final allItems = await foodStorageService.getAllFoodItems();
        expect(allItems.length, 4);
      });
    });

    group('Error Scenarios', () {
      test('should handle food tracking without profile', () async {
        // Don't create a profile
        expect(userProfileService.hasUserProfile, isFalse);
        expect(userProfileService.getNutritionTargets(), isNull);
        expect(userProfileService.calculateBMR(), isNull);
        expect(userProfileService.calculateDailyCalorieNeeds(), isNull);

        // Food tracking should still work
        final foodItem = FoodItem(
          name: 'Orphan Food',
          calories: 100,
          nutritionFacts: NutritionFacts(protein: 5, carbs: 10, fat: 2, mass: 100),
        );

        await foodStorageService.saveFoodItem(foodItem);
        final items = await foodStorageService.getAllFoodItems();
        expect(items.length, 1);
      });

      test('should handle profile deletion with existing food data', () async {
        // Create profile and add food
        await userProfileService.createProfile(
          age: 25,
          weight: 65.0,
          height: 160.0,
          gender: Gender.female,
          activityLevel: ActivityLevel.lightlyActive,
        );

        final foodItem = FoodItem(
          name: 'Test Food',
          calories: 200,
          nutritionFacts: NutritionFacts(protein: 10, carbs: 20, fat: 5, mass: 150),
        );

        await foodStorageService.saveFoodItem(foodItem);

        // Delete profile
        await userProfileService.deleteProfile();
        expect(userProfileService.hasUserProfile, isFalse);

        // Food data should still exist
        final items = await foodStorageService.getAllFoodItems();
        expect(items.length, 1);
        expect(items.first.id, foodItem.id);
      });
    });
  });
}
