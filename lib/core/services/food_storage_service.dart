import 'package:hive_flutter/hive_flutter.dart';
import 'package:plate_track_ai/shared/models/food_item.dart';
import 'dart:async';
import 'package:flutter/foundation.dart';

class FoodStorageService {
  static const String _foodBoxName = 'food_items';
  static final FoodStorageService _instance = FoodStorageService._internal();
  
  late Box<dynamic> _foodBox;
  bool _isInitialized = false;
  
  // Stream controller to broadcast data changes
  final StreamController<void> _changeController = StreamController<void>.broadcast();
  
  // Public stream that widgets can listen to
  Stream<void> get onDataChanged => _changeController.stream;
  
  factory FoodStorageService() {
    return _instance;
  }
  
  FoodStorageService._internal();
  
  Future<void> initialize() async {
    if (!_isInitialized) {
      try {
        // Open a dynamic box, not a typed box
        _foodBox = await Hive.openBox(_foodBoxName);
        _isInitialized = true;
        
        // Listen to Hive box changes
        _foodBox.listenable().addListener(_notifyListeners);
      } catch (e) {
        print('Error initializing food storage: $e');
        // Try to delete the box if it's corrupted
        await Hive.deleteBoxFromDisk(_foodBoxName);
        // Try to open again
        _foodBox = await Hive.openBox(_foodBoxName);
        _isInitialized = true;
        
        // Listen to Hive box changes
        _foodBox.listenable().addListener(_notifyListeners);
      }
    }
  }
  
  void _notifyListeners() {
    // Notify all listeners about the data change
    _changeController.add(null);
  }

  void dispose() {
    _changeController.close();
  }
  
  // Returns a ValueListenable that the UI can listen to directly
  ValueListenable<Box<dynamic>> get foodBoxListenable {
    if (!_isInitialized) {
      initialize();
    }
    return _foodBox.listenable();
  }
  
  Future<void> saveFoodItem(FoodItem foodItem) async {
    await initialize();
    await _foodBox.put(foodItem.id, foodItem);
  }
  
  Future<List<FoodItem>> getAllFoodItems() async {
    await initialize();
    final items = <FoodItem>[];
    
    try {
      for (final key in _foodBox.keys) {
        final dynamic item = _foodBox.get(key);
        if (item is FoodItem) {
          items.add(item);
        } else {
          print('Skipping item with key $key: Not a FoodItem');
        }
      }
    } catch (e) {
      print('Error retrieving food items: $e');
    }
    
    return items;
  }
  
  Future<List<FoodItem>> getFoodItemsByDate(DateTime date) async {
    await initialize();
    
    // Filter items by date (same day)
    final allItems = await getAllFoodItems();
    return allItems.where((item) {
      final itemDate = item.timestamp;
      return itemDate.year == date.year && 
             itemDate.month == date.month && 
             itemDate.day == date.day;
    }).toList();
  }
  
  Future<void> deleteFoodItem(String id) async {
    await initialize();
    await _foodBox.delete(id);
  }
  
  Future<void> clearAllData() async {
    await initialize();
    await _foodBox.clear();
  }
}