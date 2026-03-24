import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:openfoodfacts/openfoodfacts.dart';
import 'package:plate_track_ai/shared/models/cached_barcode_product.dart';

enum OpenFoodFactsFailureReason { notFound, networkError, parseError }

class OpenFoodFactsException implements Exception {
  final OpenFoodFactsFailureReason reason;
  const OpenFoodFactsException(this.reason);

  @override
  String toString() => 'OpenFoodFactsException(${reason.name})';
}

class OpenFoodFactsService {
  static final OpenFoodFactsService _instance = OpenFoodFactsService._internal();
  factory OpenFoodFactsService() => _instance;

  OpenFoodFactsService._internal() {
    OpenFoodAPIConfiguration.globalUser = const User(
      userId: 'plate_track_ai',
      password: '',
    );
    OpenFoodAPIConfiguration.globalLanguages = [
      OpenFoodFactsLanguage.RUSSIAN,
      OpenFoodFactsLanguage.ENGLISH,
    ];
  }

  Future<CachedBarcodeProduct> fetchProduct(String barcode) async {
    try {
      final config = ProductQueryConfiguration(
        barcode,
        language: OpenFoodFactsLanguage.RUSSIAN,
        country: OpenFoodFactsCountry.RUSSIA,
        version: ProductQueryVersion.v3,
        fields: [
          ProductField.NAME,
          ProductField.NAME_IN_LANGUAGES,
          ProductField.NUTRIMENTS,
        ],
      );

      final result = await OpenFoodAPIClient.getProductV3(config);

      if (kDebugMode) {
        debugPrint('OpenFoodFacts: status=${result.status} for barcode=$barcode');
      }

      if (result.product == null) {
        throw const OpenFoodFactsException(OpenFoodFactsFailureReason.notFound);
      }

      final product = result.product!;
      final nutriments = product.nutriments;

      // Product name: prefer Russian, fall back to English, then barcode.
      final name = product.productNameInLanguages?[OpenFoodFactsLanguage.RUSSIAN]?.trim() ??
          product.productNameInLanguages?[OpenFoodFactsLanguage.ENGLISH]?.trim() ??
          product.productName?.trim() ??
          '';

      // The SDK resolves energy-kcal vs energy-kj automatically.
      final caloriesPer100g =
          nutriments?.getValue(Nutrient.energyKCal, PerSize.oneHundredGrams) ?? 0.0;
      final proteinPer100g =
          nutriments?.getValue(Nutrient.proteins, PerSize.oneHundredGrams) ?? 0.0;
      final carbsPer100g =
          nutriments?.getValue(Nutrient.carbohydrates, PerSize.oneHundredGrams) ?? 0.0;
      final fatPer100g =
          nutriments?.getValue(Nutrient.fat, PerSize.oneHundredGrams) ?? 0.0;

      if (kDebugMode) {
        debugPrint(
          'OpenFoodFacts: "$name" — '
          '${caloriesPer100g.toStringAsFixed(1)} kcal, '
          'P${proteinPer100g.toStringAsFixed(1)} '
          'C${carbsPer100g.toStringAsFixed(1)} '
          'F${fatPer100g.toStringAsFixed(1)}',
        );
      }

      return CachedBarcodeProduct(
        barcode: barcode,
        productName: name.isNotEmpty ? name : barcode,
        caloriesPer100g: caloriesPer100g,
        proteinPer100g: proteinPer100g,
        carbsPer100g: carbsPer100g,
        fatPer100g: fatPer100g,
        cachedAt: DateTime.now(),
      );
    } on OpenFoodFactsException {
      rethrow;
    } on SocketException {
      throw const OpenFoodFactsException(OpenFoodFactsFailureReason.networkError);
    } catch (e) {
      if (kDebugMode) debugPrint('OpenFoodFacts: unexpected error: $e');
      throw const OpenFoodFactsException(OpenFoodFactsFailureReason.parseError);
    }
  }
}
