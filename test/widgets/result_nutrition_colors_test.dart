import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plate_track_ai/core/themes/app_colors.dart';
import 'package:plate_track_ai/core/themes/app_theme.dart';
import 'package:plate_track_ai/features/barcode_scan/barcode_result_screen.dart';
import 'package:plate_track_ai/features/food_recognition/recognition_result_screen.dart';
import 'package:plate_track_ai/shared/models/cached_barcode_product.dart';
import 'package:plate_track_ai/shared/models/food_item.dart';

import 'localized_pump.dart';

void main() {
  setUpAll(initLocalization);
  testWidgets('recognition and barcode nutrition icons use neutral fills', (
    tester,
  ) async {
    final product = CachedBarcodeProduct(
      barcode: '1234567890123',
      productName: 'Test meal',
      caloriesPer100g: 200,
      proteinPer100g: 10,
      carbsPer100g: 20,
      fatPer100g: 8,
      cachedAt: DateTime(2026),
    );
    await pumpLocalized(
      tester,
      Scaffold(
        body: Row(
          children: [
            for (final theme in [
              AppTheme.lightTheme,
              AppTheme.darkTheme,
              AppTheme.pickMeTheme,
            ])
              for (final screen in [
                BarcodeResultScreen(
                  barcode: product.barcode,
                  initialProduct: product,
                  onSave: (_) {},
                ),
                RecognitionResultScreen(
                  imageFile: File('assets/icons/app_icon_color.png'),
                  foodItem: FoodItem(
                    name: 'Test meal',
                    calories: 200,
                    nutritionFacts: NutritionFacts(
                      protein: 10,
                      carbs: 20,
                      fat: 8,
                      mass: 100,
                    ),
                  ),
                  onSave: (_) {},
                ),
              ])
                Expanded(
                  child: Theme(data: theme, child: screen),
                ),
          ],
        ),
      ),
      size: const Size(3600, 1400),
    );
    for (final entry in {
      Icons.local_fire_department: AppColors.calories,
      Icons.fitness_center: AppColors.protein,
      Icons.grain: AppColors.carbs,
      Icons.opacity: AppColors.fat,
    }.entries) {
      final icons = find.byIcon(entry.key);
      expect(icons, findsNWidgets(6));
      for (final element in icons.evaluate()) {
        expect((element.widget as Icon).color, entry.value);
        final tile = tester.widget<Container>(
          find
              .ancestor(
                of: find.byWidget(element.widget),
                matching: find.byType(Container),
              )
              .first,
        );
        expect(
          (tile.decoration! as BoxDecoration).color,
          Theme.of(element).colorScheme.surface,
        );
      }
    }
    expect(tester.takeException(), isNull);
  });
}
