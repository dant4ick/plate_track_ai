import 'package:equatable/equatable.dart';
import 'package:uuid/uuid.dart';
import 'package:hive/hive.dart';

// Remove the part directive since we're using manual adapters
// part 'food_item.g.dart';

@HiveType(typeId: 0)
class FoodItem extends Equatable {
  @HiveField(0)
  final String id;
  
  @HiveField(1)
  final String name;
  
  @HiveField(2)
  final double calories;
  
  @HiveField(3)
  final NutritionFacts nutritionFacts;
  
  @HiveField(4)
  final DateTime timestamp;
  
  @HiveField(5)
  final String? imagePath;

  FoodItem({
    String? id,
    required this.name,
    required this.calories,
    required this.nutritionFacts,
    DateTime? timestamp,
    this.imagePath,
  }) : 
    id = id ?? const Uuid().v4(),
    timestamp = timestamp ?? DateTime.now();

  @override
  List<Object?> get props => [id, name, calories, nutritionFacts, timestamp, imagePath];

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'calories': calories,
      'nutritionFacts': nutritionFacts.toJson(),
      'timestamp': timestamp.toIso8601String(),
      'imagePath': imagePath,
    };
  }

  factory FoodItem.fromJson(Map<String, dynamic> json) {
    return FoodItem(
      id: json['id'],
      name: json['name'],
      calories: json['calories'],
      nutritionFacts: NutritionFacts.fromJson(json['nutritionFacts']),
      timestamp: DateTime.parse(json['timestamp']),
      imagePath: json['imagePath'],
    );
  }
}

@HiveType(typeId: 1)
class NutritionFacts extends Equatable {
  @HiveField(0)
  final double protein; // in grams
  
  @HiveField(1)
  final double carbohydrates; // in grams
  
  @HiveField(2)
  final double fat; // in grams
  
  @HiveField(3)
  final double? mass; // in grams

  const NutritionFacts({
    required this.protein,
    required this.carbohydrates,
    required this.fat,
    this.mass,
  });

  @override
  List<Object?> get props => [protein, carbohydrates, fat, mass];

  Map<String, dynamic> toJson() {
    return {
      'protein': protein,
      'carbohydrates': carbohydrates,
      'fat': fat,
      'mass': mass,
    };
  }

  factory NutritionFacts.fromJson(Map<String, dynamic> json) {
    return NutritionFacts(
      protein: json['protein'],
      carbohydrates: json['carbohydrates'],
      fat: json['fat'],
      mass: json['mass'],
    );
  }
}