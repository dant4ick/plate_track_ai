import 'package:plate_track_ai/shared/models/food_item.dart';
import 'package:plate_track_ai/shared/models/user_profile.dart';

/// Test utilities for creating common test data
class TestDataFactory {
  /// Creates a basic FoodItem for testing
  static FoodItem createFoodItem({
    String? name,
    double? calories,
    double? protein,
    double? carbs,
    double? fat,
    double? mass,
    DateTime? timestamp,
    String? imagePath,
  }) {
    return FoodItem(
      name: name ?? 'Test Food',
      calories: calories ?? 100.0,
      nutritionFacts: NutritionFacts(
        protein: protein ?? 5.0,
        carbs: carbs ?? 15.0,
        fat: fat ?? 3.0,
        mass: mass ?? 100.0,
      ),
      timestamp: timestamp,
      imagePath: imagePath,
    );
  }

  /// Creates a basic UserProfile for testing
  static UserProfile createUserProfile({
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
      id: id ?? 'test-profile-id',
      age: age ?? 30,
      weight: weight ?? 70.0,
      height: height ?? 170.0,
      gender: gender ?? Gender.male,
      activityLevel: activityLevel ?? ActivityLevel.moderatelyActive,
      createdAt: createdAt ?? DateTime.now(),
      updatedAt: updatedAt,
    );
  }

  /// Creates a list of sample food items for testing
  static List<FoodItem> createSampleFoodItems() {
    return [
      createFoodItem(
        name: 'Apple',
        calories: 52,
        protein: 0.3,
        carbs: 14,
        fat: 0.2,
        mass: 100,
      ),
      createFoodItem(
        name: 'Chicken Breast',
        calories: 165,
        protein: 31,
        carbs: 0,
        fat: 3.6,
        mass: 100,
      ),
      createFoodItem(
        name: 'Brown Rice',
        calories: 123,
        protein: 2.3,
        carbs: 23,
        fat: 0.9,
        mass: 100,
      ),
      createFoodItem(
        name: 'Broccoli',
        calories: 25,
        protein: 3,
        carbs: 5,
        fat: 0.4,
        mass: 100,
      ),
    ];
  }

  /// Creates food items for specific dates
  static List<FoodItem> createFoodItemsForDate(DateTime date, int count) {
    return List.generate(count, (index) {
      return createFoodItem(
        name: 'Food Item ${index + 1}',
        calories: 100 + (index * 50).toDouble(),
        timestamp: date.add(Duration(hours: index + 8)), // Spread throughout the day
      );
    });
  }

  /// Creates a week's worth of food items
  static List<FoodItem> createWeeklyFoodItems() {
    final items = <FoodItem>[];
    final today = DateTime.now();
    
    for (int day = 0; day < 7; day++) {
      final date = today.subtract(Duration(days: day));
      items.addAll(createFoodItemsForDate(date, 3)); // 3 meals per day
    }
    
    return items;
  }

  /// Creates nutrition facts with specific macronutrient ratios
  static NutritionFacts createNutritionFacts({
    double? totalCalories,
    double? proteinPercent, // as decimal (0.2 = 20%)
    double? carbsPercent,
    double? fatPercent,
    double? mass,
  }) {
    final calories = totalCalories ?? 100.0;
    final proteinRatio = proteinPercent ?? 0.2;
    final carbsRatio = carbsPercent ?? 0.5;
    final fatRatio = fatPercent ?? 0.3;
    
    // Calculate macros based on calories per gram
    final protein = (calories * proteinRatio) / 4; // 4 cal/g protein
    final carbs = (calories * carbsRatio) / 4; // 4 cal/g carbs
    final fat = (calories * fatRatio) / 9; // 9 cal/g fat
    
    return NutritionFacts(
      protein: protein,
      carbs: carbs,
      fat: fat,
      mass: mass ?? 100.0,
    );
  }
}

/// Test utilities for common assertions and calculations
class TestCalculations {
  /// Calculate total calories from a list of food items
  static double calculateTotalCalories(List<FoodItem> items) {
    return items.fold(0.0, (sum, item) {
      final mass = item.nutritionFacts.mass ?? 100.0;
      return sum + (item.calories * mass / 100.0);
    });
  }

  /// Calculate total protein from a list of food items
  static double calculateTotalProtein(List<FoodItem> items) {
    return items.fold(0.0, (sum, item) {
      final mass = item.nutritionFacts.mass ?? 100.0;
      return sum + (item.nutritionFacts.protein * mass / 100.0);
    });
  }

  /// Calculate total carbs from a list of food items
  static double calculateTotalCarbs(List<FoodItem> items) {
    return items.fold(0.0, (sum, item) {
      final mass = item.nutritionFacts.mass ?? 100.0;
      return sum + (item.nutritionFacts.carbs * mass / 100.0);
    });
  }

  /// Calculate total fat from a list of food items
  static double calculateTotalFat(List<FoodItem> items) {
    return items.fold(0.0, (sum, item) {
      final mass = item.nutritionFacts.mass ?? 100.0;
      return sum + (item.nutritionFacts.fat * mass / 100.0);
    });
  }

  /// Verify if BMR calculation is correct for given profile
  static bool verifyBMRCalculation(UserProfile profile) {
    final calculatedBMR = profile.calculateBMR();
    double expectedBMR;
    
    switch (profile.gender) {
      case Gender.male:
        expectedBMR = 260 + (9.65 * profile.weight) + (5.73 * profile.height) - (5.08 * profile.age);
        break;
      case Gender.female:
        expectedBMR = 43 + (7.38 * profile.weight) + (6.07 * profile.height) - (2.31 * profile.age);
        break;
    }
    
    return (calculatedBMR - expectedBMR).abs() < 0.01;
  }

  /// Verify if TDEE calculation is correct for given profile
  static bool verifyTDEECalculation(UserProfile profile) {
    final calculatedTDEE = profile.calculateTDEE();
    final expectedTDEE = profile.calculateBMR() * profile.activityLevel.multiplier;
    
    return (calculatedTDEE - expectedTDEE).abs() < 0.01;
  }

  /// Check if nutrition targets follow expected macro distribution
  static bool verifyNutritionTargets(Map<String, double> targets) {
    final calories = targets['calories'] ?? 0;
    final protein = targets['protein'] ?? 0;
    final carbs = targets['carbs'] ?? 0;
    final fat = targets['fat'] ?? 0;
    
    // Check if macro calories add up correctly
    final proteinCalories = protein * 4;
    final carbsCalories = carbs * 4;
    final fatCalories = fat * 9;
    final totalMacroCalories = proteinCalories + carbsCalories + fatCalories;
    
    // Should be within 1% of total calories
    return (totalMacroCalories - calories).abs() / calories < 0.01;
  }
}

/// Constants for testing
class TestConstants {
  // BMR formula constants
  static const double maleBMRConstant = 260;
  static const double maleBMRWeightMultiplier = 9.65;
  static const double maleBMRHeightMultiplier = 5.73;
  static const double maleBMRAgeMultiplier = 5.08;
  
  static const double femaleBMRConstant = 43;
  static const double femaleBMRWeightMultiplier = 7.38;
  static const double femaleBMRHeightMultiplier = 6.07;
  static const double femaleBMRAgeMultiplier = 2.31;
  
  // Activity level multipliers
  static const Map<ActivityLevel, double> activityMultipliers = {
    ActivityLevel.sedentary: 1.40,
    ActivityLevel.lightlyActive: 1.55,
    ActivityLevel.moderatelyActive: 1.70,
    ActivityLevel.veryActive: 1.95,
    ActivityLevel.extremelyActive: 2.20,
  };
  
  // Macro distribution percentages
  static const double proteinPercentage = 0.20;
  static const double carbsPercentage = 0.50;
  static const double fatPercentage = 0.30;
  
  // Calories per gram
  static const double proteinCaloriesPerGram = 4;
  static const double carbsCaloriesPerGram = 4;
  static const double fatCaloriesPerGram = 9;
  
  // Test data ranges
  static const int minAge = 18;
  static const int maxAge = 80;
  static const double minWeight = 40.0;
  static const double maxWeight = 150.0;
  static const double minHeight = 140.0;
  static const double maxHeight = 220.0;
}
