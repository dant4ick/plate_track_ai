import 'dart:io';

import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:hive_test/hive_test.dart';
import 'package:plate_track_ai/core/services/food_storage_service.dart';
import 'package:plate_track_ai/core/themes/app_theme.dart';
import 'package:plate_track_ai/features/meals/meal_detail_screen.dart';
import 'package:plate_track_ai/shared/models/food_item_adapters.dart';

import '../color_test_utils.dart';
import '../test_utils.dart';
import 'localized_pump.dart';

// Opt-in PNG export: --dart-define=NOTIFICATION_PREVIEW_DIR=/path/to/scratch
void main() {
  setUpAll(() async {
    await initLocalization();
    await setUpTestHive();
    Hive.registerAdapter(FoodItemAdapter());
    Hive.registerAdapter(NutritionFactsAdapter());
    await Hive.openBox('food_items', bytes: Uint8List(0));
    await FoodStorageService().initialize();
  });

  tearDownAll(() async => Hive.close());

  testWidgets('real meal deletion shows a readable brand card in every theme', (
    tester,
  ) async {
    const output = String.fromEnvironment('NOTIFICATION_PREVIEW_DIR');
    final previousShadows = debugDisableShadows;
    try {
      if (output.isNotEmpty) {
        debugDisableShadows = false;
        await tester.runAsync(() async {
          await (FontLoader(AppTheme.fontFamily)..addFont(
                rootBundle.load(
                  'assets/fonts/Montserrat/Montserrat-Regular.ttf',
                ),
              ))
              .load();
          final icons = File(
            '${Platform.resolvedExecutable.split('/artifacts/').first}'
            '/artifacts/material_fonts/MaterialIcons-Regular.otf',
          );
          await (FontLoader('MaterialIcons')..addFont(
                Future.value(ByteData.sublistView(await icons.readAsBytes())),
              ))
              .load();
        });
      }
      for (final entry in {
        'light': AppTheme.lightTheme,
        'dark': AppTheme.darkTheme,
        'pick-me': AppTheme.pickMeTheme,
      }.entries) {
        final item = TestDataFactory.createFoodItem(name: 'Lunch bowl');
        await tester.runAsync(() => FoodStorageService().saveFoodItem(item));
        final boundaryKey = GlobalKey();
        await pumpLocalized(
          tester,
          RepaintBoundary(
            key: boundaryKey,
            child: Scaffold(
              appBar: AppBar(title: Text('${entry.key} · Meals')),
              body: Builder(
                builder: (context) => TextButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => MealDetailScreen(item: item),
                    ),
                  ),
                  child: const Text('Open meal'),
                ),
              ),
            ),
          ),
          theme: entry.value,
        );
        await tester.tap(find.text('Open meal'));
        await tester.pumpAndSettle();
        await tester.tap(find.widgetWithText(ElevatedButton, 'Delete'));
        await tester.pumpAndSettle();
        // Cancellation must neither delete nor announce success.
        await tester.tap(find.text('Cancel'));
        await tester.pumpAndSettle();
        expect(find.byType(SnackBar), findsNothing);
        expect(
          (await FoodStorageService().getAllFoodItems()).any(
            (food) => food.id == item.id,
          ),
          isTrue,
        );
        await tester.tap(find.widgetWithText(ElevatedButton, 'Delete'));
        await tester.pumpAndSettle();
        await tester.tap(find.widgetWithText(ElevatedButton, 'Delete').last);
        await tester.pumpAndSettle();
        expect(find.byType(MealDetailScreen), findsNothing);
        expect(
          (await FoodStorageService().getAllFoodItems()).any(
            (food) => food.id == item.id,
          ),
          isFalse,
        );
        final bar = tester.widget<SnackBar>(find.byType(SnackBar));
        final text = tester.widget<Text>(
          find.text('Food item deleted successfully'),
        );
        expect(bar.backgroundColor, entry.value.colorScheme.surface);
        expect(
          contrastOn(text.style!.color!, bar.backgroundColor!),
          greaterThanOrEqualTo(4.5),
        );
        expect(find.byIcon(Icons.check_circle), findsOneWidget);
        expect(tester.takeException(), isNull);
        if (output.isNotEmpty) {
          await tester.runAsync(() async {
            final boundary =
                boundaryKey.currentContext!.findRenderObject()
                    as RenderRepaintBoundary;
            final image = await boundary.toImage(pixelRatio: 2);
            final bytes = await image.toByteData(
              format: ui.ImageByteFormat.png,
            );
            final file = File('$output/deletion-${entry.key}.png');
            await file.parent.create(recursive: true);
            await file.writeAsBytes(bytes!.buffer.asUint8List());
            image.dispose();
          });
        }
        // Clear the messenger before switching themes.
        ScaffoldMessenger.of(
          tester.element(find.byType(Scaffold).first),
        ).removeCurrentSnackBar();
        await tester.pumpAndSettle();
      }
    } finally {
      debugDisableShadows = previousShadows;
    }
  });
}
