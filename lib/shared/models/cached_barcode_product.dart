import 'package:equatable/equatable.dart';
import 'package:hive/hive.dart';

@HiveType(typeId: 5)
class CachedBarcodeProduct extends Equatable {
  @HiveField(0)
  final String barcode;

  @HiveField(1)
  final String productName;

  @HiveField(2)
  final double caloriesPer100g;

  @HiveField(3)
  final double proteinPer100g;

  @HiveField(4)
  final double carbsPer100g;

  @HiveField(5)
  final double fatPer100g;

  @HiveField(6)
  final DateTime cachedAt;

  const CachedBarcodeProduct({
    required this.barcode,
    required this.productName,
    required this.caloriesPer100g,
    required this.proteinPer100g,
    required this.carbsPer100g,
    required this.fatPer100g,
    required this.cachedAt,
  });

  @override
  List<Object?> get props => [
        barcode,
        productName,
        caloriesPer100g,
        proteinPer100g,
        carbsPer100g,
        fatPer100g,
        cachedAt,
      ];
}
