import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plate_track_ai/core/themes/app_colors.dart';
import 'package:plate_track_ai/core/themes/app_theme.dart';
import 'package:plate_track_ai/features/meals/meal_detail_screen.dart';
import 'package:plate_track_ai/shared/models/food_item.dart';
import 'package:plate_track_ai/features/recommendations/nutrition_advice.dart';
import 'package:plate_track_ai/shared/widgets/macro_chip.dart';
import 'package:plate_track_ai/shared/widgets/calorie_gauge.dart';
import 'package:plate_track_ai/shared/widgets/tip_card.dart';
import 'localized_pump.dart';

void main() {
  setUpAll(initLocalization);
  testWidgets('meal macro icons have no tinted backgrounds', (tester) async {
    await pumpLocalized(
      tester,
      MealDetailScreen(
        item: FoodItem(
          name: 'Meal',
          calories: 200,
          timestamp: DateTime(2026),
          nutritionFacts: NutritionFacts(protein: 10, carbs: 20, fat: 8),
        ),
      ),
    );
    for (final icon in [Icons.fitness_center, Icons.grain, Icons.opacity]) {
      final tile = tester.widget<Container>(
        find
            .ancestor(of: find.byIcon(icon), matching: find.byType(Container))
            .first,
      );
      expect(
        (tile.decoration! as BoxDecoration).color,
        AppTheme.lightTheme.colorScheme.surface,
      );
    }
  });

  testWidgets('macro chips and advice keep original hues on neutral surfaces', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1170, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await (FontLoader(AppTheme.fontFamily)..addFont(
          rootBundle.load('assets/fonts/Montserrat/Montserrat-Regular.ttf'),
        ))
        .load();
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
    final key = GlobalKey();
    final themes = [
      AppTheme.lightTheme,
      AppTheme.darkTheme,
      AppTheme.pickMeTheme,
    ];
    final macros = [Macro.protein, Macro.carbs, Macro.fat];
    const colors = [AppColors.protein, AppColors.carbs, AppColors.fat];
    const tones = [TipTone.protein, TipTone.carbs, TipTone.fat];
    await tester.pumpWidget(
      RepaintBoundary(
        key: key,
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: Row(
            children: [
              for (final theme in themes)
                Expanded(
                  child: MaterialApp(
                    debugShowCheckedModeBanner: false,
                    theme: theme,
                    home: Scaffold(
                      body: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            const CalorieGauge(consumed: 1200, target: 2000),
                            const SizedBox(height: 24),
                            for (var i = 0; i < macros.length; i++) ...[
                              MacroChip(macro: macros[i], grams: 42),
                              const SizedBox(height: 12),
                              TipCard(
                                tip: NutritionTip(
                                  title: ['Protein', 'Carbs', 'Fat'][i],
                                  description:
                                      'Original colour, no alternate shades',
                                  icon: Icons.circle,
                                  tone: tones[i],
                                ),
                              ),
                              const SizedBox(height: 20),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final chips = find.byType(MacroChip);
    final tips = find.byType(TipCard);
    for (var t = 0; t < themes.length; t++) {
      for (var m = 0; m < macros.length; m++) {
        final index = t * macros.length + m;
        final chipText = tester.widget<Text>(
          find.descendant(of: chips.at(index), matching: find.byType(Text)),
        );
        expect(chipText.style!.color, colors[m]);
        final icon = tester.widget<Icon>(
          find.descendant(of: tips.at(index), matching: find.byType(Icon)),
        );
        expect(icon.color, colors[m]);
        final tile = tester.widget<Container>(
          find
              .ancestor(
                of: find.descendant(
                  of: tips.at(index),
                  matching: find.byType(Icon),
                ),
                matching: find.byType(Container),
              )
              .first,
        );
        expect(
          (tile.decoration! as BoxDecoration).color,
          themes[t].colorScheme.surface,
        );
      }
    }
    expect(tester.takeException(), isNull);
    const output = String.fromEnvironment('MACRO_PREVIEW');
    if (output.isNotEmpty) {
      final boundary =
          key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      await tester.runAsync(() async {
        final image = await boundary.toImage();
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        await File(output).writeAsBytes(bytes!.buffer.asUint8List());
        image.dispose();
      });
    }
  });
}
