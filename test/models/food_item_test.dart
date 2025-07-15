import 'package:flutter_test/flutter_test.dart';
import 'package:plate_track_ai/shared/models/food_item.dart';

void main() {
  group('FoodItem', () {
    test('should create FoodItem with correct values', () {
      final nutrition = NutritionFacts(protein: 10, carbs: 20, fat: 5, mass: 150);
      final item = FoodItem(
        name: 'Apple',
        calories: 52,
        nutritionFacts: nutrition,
        imagePath: 'path/to/image.png',
      );
      expect(item.name, 'Apple');
      expect(item.calories, 52);
      expect(item.nutritionFacts, nutrition);
      expect(item.imagePath, 'path/to/image.png');
      expect(item.id, isNotNull);
      expect(item.timestamp, isNotNull);
    });

    test('should create FoodItem with auto-generated ID when not provided', () {
      final nutrition = NutritionFacts(protein: 2, carbs: 5, fat: 0.1, mass: 100);
      final item = FoodItem(
        name: 'Test Food',
        calories: 50,
        nutritionFacts: nutrition,
      );
      expect(item.id, isNotNull);
      expect(item.id.length, greaterThan(0));
    });

    test('should create FoodItem with current timestamp when not provided', () {
      final before = DateTime.now();
      final nutrition = NutritionFacts(protein: 1, carbs: 2, fat: 0.5, mass: 50);
      final item = FoodItem(
        name: 'Test Food',
        calories: 25,
        nutritionFacts: nutrition,
      );
      final after = DateTime.now();
      
      expect(item.timestamp.isAfter(before.subtract(Duration(seconds: 1))), isTrue);
      expect(item.timestamp.isBefore(after.add(Duration(seconds: 1))), isTrue);
    });

    test('should handle null imagePath', () {
      final nutrition = NutritionFacts(protein: 1, carbs: 2, fat: 0.5, mass: 50);
      final item = FoodItem(
        name: 'Test Food',
        calories: 25,
        nutritionFacts: nutrition,
      );
      expect(item.imagePath, isNull);
    });

    test('should convert to and from JSON', () {
      final nutrition = NutritionFacts(protein: 2, carbs: 15, fat: 0.5, mass: 100);
      final item = FoodItem(
        name: 'Banana',
        calories: 89,
        nutritionFacts: nutrition,
      );
      final json = item.toJson();
      final fromJson = FoodItem.fromJson(json);
      expect(fromJson.name, item.name);
      expect(fromJson.calories, item.calories);
      expect(fromJson.nutritionFacts, item.nutritionFacts);
      expect(fromJson.imagePath, item.imagePath);
      expect(fromJson.id, item.id);
      expect(fromJson.timestamp, item.timestamp);
    });

    test('should handle JSON with null imagePath', () {
      final nutrition = NutritionFacts(protein: 1, carbs: 2, fat: 0.1, mass: 50);
      final item = FoodItem(
        name: 'Test',
        calories: 10,
        nutritionFacts: nutrition,
      );
      final json = item.toJson();
      expect(json['imagePath'], isNull);
      
      final fromJson = FoodItem.fromJson(json);
      expect(fromJson.imagePath, isNull);
    });

    test('should maintain equality with same values', () {
      final nutrition = NutritionFacts(protein: 1, carbs: 2, fat: 0.1, mass: 50);
      final timestamp = DateTime.now();
      final item1 = FoodItem(
        id: 'test-id',
        name: 'Test',
        calories: 10,
        nutritionFacts: nutrition,
        timestamp: timestamp,
      );
      final item2 = FoodItem(
        id: 'test-id',
        name: 'Test',
        calories: 10,
        nutritionFacts: nutrition,
        timestamp: timestamp,
      );
      expect(item1, equals(item2));
    });
  });

  group('NutritionFacts', () {
    test('should create NutritionFacts with correct values', () {
      final facts = NutritionFacts(protein: 3, carbs: 10, fat: 1, mass: 50);
      expect(facts.protein, 3);
      expect(facts.carbs, 10);
      expect(facts.fat, 1);
      expect(facts.mass, 50);
    });

    test('should handle null mass', () {
      final facts = NutritionFacts(protein: 3, carbs: 10, fat: 1);
      expect(facts.protein, 3);
      expect(facts.carbs, 10);
      expect(facts.fat, 1);
      expect(facts.mass, isNull);
    });

    test('should handle zero values', () {
      final facts = NutritionFacts(protein: 0, carbs: 0, fat: 0, mass: 0);
      expect(facts.protein, 0);
      expect(facts.carbs, 0);
      expect(facts.fat, 0);
      expect(facts.mass, 0);
    });

    test('should handle large values', () {
      final facts = NutritionFacts(
        protein: 999.99, 
        carbs: 1000.0, 
        fat: 500.5, 
        mass: 10000
      );
      expect(facts.protein, 999.99);
      expect(facts.carbs, 1000.0);
      expect(facts.fat, 500.5);
      expect(facts.mass, 10000);
    });

    test('should convert to and from JSON', () {
      final facts = NutritionFacts(protein: 1, carbs: 2, fat: 3, mass: 100);
      final json = facts.toJson();
      final fromJson = NutritionFacts.fromJson(json);
      expect(fromJson.protein, facts.protein);
      expect(fromJson.carbs, facts.carbs);
      expect(fromJson.fat, facts.fat);
      expect(fromJson.mass, facts.mass);
    });

    test('should handle JSON with null mass', () {
      final facts = NutritionFacts(protein: 1, carbs: 2, fat: 3);
      final json = facts.toJson();
      expect(json['mass'], isNull);
      
      final fromJson = NutritionFacts.fromJson(json);
      expect(fromJson.mass, isNull);
    });

    test('should maintain equality with same values', () {
      final facts1 = NutritionFacts(protein: 1, carbs: 2, fat: 3, mass: 100);
      final facts2 = NutritionFacts(protein: 1, carbs: 2, fat: 3, mass: 100);
      expect(facts1, equals(facts2));
    });

    test('should not be equal with different values', () {
      final facts1 = NutritionFacts(protein: 1, carbs: 2, fat: 3, mass: 100);
      final facts2 = NutritionFacts(protein: 2, carbs: 2, fat: 3, mass: 100);
      expect(facts1, isNot(equals(facts2)));
    });
  });
}
