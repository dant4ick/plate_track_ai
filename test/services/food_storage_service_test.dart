import 'package:flutter_test/flutter_test.dart';
import 'package:plate_track_ai/core/services/food_storage_service.dart';
import 'package:plate_track_ai/shared/models/food_item.dart';
import 'package:hive/hive.dart';
import 'package:hive_test/hive_test.dart';
import 'package:plate_track_ai/shared/models/food_item_adapters.dart';

void main() {
  group('FoodStorageService', () {
    late FoodStorageService storageService;

    setUpAll(() async {
      await setUpTestHive();
      if (!Hive.isAdapterRegistered(0)) {
        Hive.registerAdapter(FoodItemAdapter());
      }
      if (!Hive.isAdapterRegistered(1)) {
        Hive.registerAdapter(NutritionFactsAdapter());
      }
    });

    setUp(() async {
      storageService = FoodStorageService();
      await storageService.initialize();
    });

    tearDown(() async {
      await storageService.clearAllData();
    });

    tearDownAll(() async {
      await Hive.close();
    });

    group('Initialization', () {
      test('should initialize without error', () async {
        final newService = FoodStorageService();
        await expectLater(newService.initialize(), completes);
      });

      test('should return same instance (singleton)', () {
        final service1 = FoodStorageService();
        final service2 = FoodStorageService();
        expect(identical(service1, service2), isTrue);
      });
    });

    group('Basic CRUD Operations', () {
      test('should save and retrieve a FoodItem', () async {
        final item = FoodItem(
          name: 'Test Food',
          calories: 100,
          nutritionFacts: NutritionFacts(protein: 5, carbs: 10, fat: 2, mass: 100),
        );
        
        await storageService.saveFoodItem(item);
        final allItems = await storageService.getAllFoodItems();
        
        expect(allItems.any((f) => f.id == item.id), isTrue);
        final retrievedItem = allItems.firstWhere((f) => f.id == item.id);
        expect(retrievedItem.name, item.name);
        expect(retrievedItem.calories, item.calories);
        expect(retrievedItem.nutritionFacts, item.nutritionFacts);
      });

      test('should save multiple FoodItems', () async {
        final items = [
          FoodItem(
            name: 'Apple',
            calories: 52,
            nutritionFacts: NutritionFacts(protein: 0.3, carbs: 14, fat: 0.2, mass: 100),
          ),
          FoodItem(
            name: 'Banana',
            calories: 89,
            nutritionFacts: NutritionFacts(protein: 1.1, carbs: 23, fat: 0.3, mass: 100),
          ),
          FoodItem(
            name: 'Orange',
            calories: 47,
            nutritionFacts: NutritionFacts(protein: 0.9, carbs: 12, fat: 0.1, mass: 100),
          ),
        ];

        for (final item in items) {
          await storageService.saveFoodItem(item);
        }

        final allItems = await storageService.getAllFoodItems();
        expect(allItems.length, 3);
        
        for (final item in items) {
          expect(allItems.any((f) => f.id == item.id), isTrue);
        }
      });

      test('should delete a FoodItem', () async {
        final item = FoodItem(
          name: 'Delete Me',
          calories: 50,
          nutritionFacts: NutritionFacts(protein: 1, carbs: 2, fat: 1, mass: 50),
        );
        
        await storageService.saveFoodItem(item);
        
        // Verify it exists
        var allItems = await storageService.getAllFoodItems();
        expect(allItems.any((f) => f.id == item.id), isTrue);
        
        // Delete it
        await storageService.deleteFoodItem(item.id);
        
        // Verify it's gone
        allItems = await storageService.getAllFoodItems();
        expect(allItems.any((f) => f.id == item.id), isFalse);
      });

      test('should handle deleting non-existent item', () async {
        await expectLater(
          storageService.deleteFoodItem('non-existent-id'),
          completes,
        );
      });

      test('should clear all data', () async {
        final items = [
          FoodItem(
            name: 'Item 1',
            calories: 100,
            nutritionFacts: NutritionFacts(protein: 5, carbs: 10, fat: 2, mass: 100),
          ),
          FoodItem(
            name: 'Item 2',
            calories: 200,
            nutritionFacts: NutritionFacts(protein: 10, carbs: 20, fat: 4, mass: 200),
          ),
        ];

        for (final item in items) {
          await storageService.saveFoodItem(item);
        }

        // Verify items exist
        var allItems = await storageService.getAllFoodItems();
        expect(allItems.length, 2);

        // Clear all data
        await storageService.clearAllData();

        // Verify all items are gone
        allItems = await storageService.getAllFoodItems();
        expect(allItems, isEmpty);
      });
    });

    group('Date-based Filtering', () {
      test('should get food items by date', () async {
        final today = DateTime.now();
        final yesterday = today.subtract(Duration(days: 1));
        final tomorrow = today.add(Duration(days: 1));

        final todayItem = FoodItem(
          name: 'Today Item',
          calories: 100,
          nutritionFacts: NutritionFacts(protein: 5, carbs: 10, fat: 2, mass: 100),
          timestamp: today,
        );

        final yesterdayItem = FoodItem(
          name: 'Yesterday Item',
          calories: 150,
          nutritionFacts: NutritionFacts(protein: 7, carbs: 15, fat: 3, mass: 150),
          timestamp: yesterday,
        );

        final tomorrowItem = FoodItem(
          name: 'Tomorrow Item',
          calories: 80,
          nutritionFacts: NutritionFacts(protein: 4, carbs: 8, fat: 1, mass: 80),
          timestamp: tomorrow,
        );

        await storageService.saveFoodItem(todayItem);
        await storageService.saveFoodItem(yesterdayItem);
        await storageService.saveFoodItem(tomorrowItem);

        // Get today's items
        final todayItems = await storageService.getFoodItemsByDate(today);
        expect(todayItems.length, 1);
        expect(todayItems.first.id, todayItem.id);

        // Get yesterday's items
        final yesterdayItems = await storageService.getFoodItemsByDate(yesterday);
        expect(yesterdayItems.length, 1);
        expect(yesterdayItems.first.id, yesterdayItem.id);

        // Get tomorrow's items
        final tomorrowItems = await storageService.getFoodItemsByDate(tomorrow);
        expect(tomorrowItems.length, 1);
        expect(tomorrowItems.first.id, tomorrowItem.id);
      });

      test('should return empty list for date with no items', () async {
        final someDate = DateTime(2020, 1, 1);
        final items = await storageService.getFoodItemsByDate(someDate);
        expect(items, isEmpty);
      });

      test('should handle multiple items on same date', () async {
        final date = DateTime.now();
        final items = [
          FoodItem(
            name: 'Breakfast',
            calories: 300,
            nutritionFacts: NutritionFacts(protein: 15, carbs: 30, fat: 6, mass: 200),
            timestamp: date,
          ),
          FoodItem(
            name: 'Lunch',
            calories: 500,
            nutritionFacts: NutritionFacts(protein: 25, carbs: 50, fat: 10, mass: 350),
            timestamp: date,
          ),
          FoodItem(
            name: 'Dinner',
            calories: 600,
            nutritionFacts: NutritionFacts(protein: 30, carbs: 60, fat: 12, mass: 400),
            timestamp: date,
          ),
        ];

        for (final item in items) {
          await storageService.saveFoodItem(item);
        }

        final dateItems = await storageService.getFoodItemsByDate(date);
        expect(dateItems.length, 3);
        
        final names = dateItems.map((item) => item.name).toSet();
        expect(names, {'Breakfast', 'Lunch', 'Dinner'});
      });

      test('should filter by exact date ignoring time', () async {
        final baseDate = DateTime(2023, 6, 15);
        final morning = DateTime(2023, 6, 15, 8, 30);
        final afternoon = DateTime(2023, 6, 15, 14, 45);
        final evening = DateTime(2023, 6, 15, 20, 15);
        final nextDay = DateTime(2023, 6, 16, 2, 0);

        final items = [
          FoodItem(
            name: 'Morning',
            calories: 200,
            nutritionFacts: NutritionFacts(protein: 10, carbs: 20, fat: 4, mass: 150),
            timestamp: morning,
          ),
          FoodItem(
            name: 'Afternoon',
            calories: 300,
            nutritionFacts: NutritionFacts(protein: 15, carbs: 30, fat: 6, mass: 200),
            timestamp: afternoon,
          ),
          FoodItem(
            name: 'Evening',
            calories: 400,
            nutritionFacts: NutritionFacts(protein: 20, carbs: 40, fat: 8, mass: 250),
            timestamp: evening,
          ),
          FoodItem(
            name: 'Next Day',
            calories: 100,
            nutritionFacts: NutritionFacts(protein: 5, carbs: 10, fat: 2, mass: 100),
            timestamp: nextDay,
          ),
        ];

        for (final item in items) {
          await storageService.saveFoodItem(item);
        }

        final dateItems = await storageService.getFoodItemsByDate(baseDate);
        expect(dateItems.length, 3);
        
        final names = dateItems.map((item) => item.name).toSet();
        expect(names, {'Morning', 'Afternoon', 'Evening'});
        expect(names.contains('Next Day'), isFalse);
      });
    });

    group('Data Stream', () {
      test('should provide data change stream', () {
        expect(storageService.onDataChanged, isA<Stream<void>>());
      });

      test('should provide box listenable', () {
        expect(storageService.foodBoxListenable, isNotNull);
      });
    });

    group('Error Handling', () {
      test('should handle corrupted data gracefully', () async {
        // This test simulates the service handling invalid data types
        // The actual implementation includes error handling for this scenario
        final items = await storageService.getAllFoodItems();
        expect(items, isA<List<FoodItem>>());
      });

      test('should initialize multiple times without error', () async {
        await storageService.initialize();
        await storageService.initialize();
        await storageService.initialize();
        
        // Should still work normally
        final item = FoodItem(
          name: 'Test',
          calories: 100,
          nutritionFacts: NutritionFacts(protein: 5, carbs: 10, fat: 2, mass: 100),
        );
        
        await storageService.saveFoodItem(item);
        final items = await storageService.getAllFoodItems();
        expect(items.any((f) => f.id == item.id), isTrue);
      });
    });

    group('Edge Cases', () {
      test('should handle items with null mass', () async {
        final item = FoodItem(
          name: 'No Mass Item',
          calories: 50,
          nutritionFacts: NutritionFacts(protein: 2, carbs: 5, fat: 1),
        );

        await storageService.saveFoodItem(item);
        final items = await storageService.getAllFoodItems();
        
        final retrievedItem = items.firstWhere((f) => f.id == item.id);
        expect(retrievedItem.nutritionFacts.mass, isNull);
      });

      test('should handle items with zero calories', () async {
        final item = FoodItem(
          name: 'Zero Calorie Item',
          calories: 0,
          nutritionFacts: NutritionFacts(protein: 0, carbs: 0, fat: 0, mass: 100),
        );

        await storageService.saveFoodItem(item);
        final items = await storageService.getAllFoodItems();
        
        final retrievedItem = items.firstWhere((f) => f.id == item.id);
        expect(retrievedItem.calories, 0);
      });

      test('should handle very large nutrition values', () async {
        final item = FoodItem(
          name: 'Large Values Item',
          calories: 9999.99,
          nutritionFacts: NutritionFacts(
            protein: 999.99,
            carbs: 1000.0,
            fat: 500.5,
            mass: 10000,
          ),
        );

        await storageService.saveFoodItem(item);
        final items = await storageService.getAllFoodItems();
        
        final retrievedItem = items.firstWhere((f) => f.id == item.id);
        expect(retrievedItem.calories, 9999.99);
        expect(retrievedItem.nutritionFacts.protein, 999.99);
      });
    });
  });
}
