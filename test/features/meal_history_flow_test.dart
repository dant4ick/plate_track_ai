import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:hive_test/hive_test.dart';
import 'package:plate_track_ai/core/services/food_storage_service.dart';
import 'package:plate_track_ai/features/meals/meal_detail_screen.dart';
import 'package:plate_track_ai/features/meals/meal_history_screen.dart';
import 'package:plate_track_ai/shared/models/food_item_adapters.dart';

import '../test_utils.dart';
import '../color_test_utils.dart';
import '../widgets/localized_pump.dart';

void main() {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final threeDaysAgo = today.subtract(const Duration(days: 3));

  // Everything that touches storage happens here, outside the widget test's
  // fake-async zone. The box is opened *in memory* first: the service's own
  // `openBox` then gets that instance back, so a delete from the detail screen
  // never waits on file I/O the fake zone would leave hanging.
  setUpAll(() async {
    await initLocalization();
    await setUpTestHive();
    if (!Hive.isAdapterRegistered(0)) Hive.registerAdapter(FoodItemAdapter());
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(NutritionFactsAdapter());
    }
    await Hive.openBox('food_items', bytes: Uint8List(0));

    final storage = FoodStorageService();
    await storage.initialize();

    await storage.saveFoodItem(
      TestDataFactory.createFoodItem(
        name: 'Breakfast bowl',
        calories: 300,
        mass: 100,
        timestamp: today.add(const Duration(hours: 8)),
      ),
    );
    await storage.saveFoodItem(
      TestDataFactory.createFoodItem(
        name: 'Lunch wrap',
        calories: 500,
        mass: 100,
        timestamp: today.add(const Duration(hours: 13)),
      ),
    );
    await storage.saveFoodItem(
      TestDataFactory.createFoodItem(
        name: 'Old dinner',
        calories: 650,
        mass: 100,
        timestamp: threeDaysAgo.add(const Duration(hours: 19)),
      ),
    );
  });

  tearDownAll(() async {
    await Hive.close();
  });

  testWidgets('groups meals by day, opens a meal, deletes it from the detail', (
    tester,
  ) async {
    await pumpLocalized(tester, const MealHistoryScreen());

    expect(tester.takeException(), isNull);
    expect(find.text('All meals'), findsOneWidget);
    expect(find.text('Today'), findsOneWidget);
    // Today's header sums its two meals.
    expect(find.text('800 kcal'), findsOneWidget);
    expect(find.text('650 kcal'), findsOneWidget);
    // Newest meal first within the day.
    expect(
      tester.getTopLeft(find.text('Lunch wrap')).dy,
      lessThan(tester.getTopLeft(find.text('Breakfast bowl')).dy),
    );
    // Rows show a time, never the date the header already gives.
    expect(find.textContaining('08:00'), findsOneWidget);
    expect(find.textContaining('Old dinner'), findsOneWidget);

    // Tap a meal → detail screen.
    await tester.tap(find.text('Lunch wrap'));
    await tester.pumpAndSettle();

    expect(find.byType(MealDetailScreen), findsOneWidget);
    expect(find.text('Meal details'), findsOneWidget);
    expect(find.text('500 kcal'), findsOneWidget);
    expect(find.text('100 g'), findsOneWidget);
    final delete = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
    final theme = Theme.of(tester.element(find.byType(ElevatedButton)));
    final style = theme.elevatedButtonTheme.style!.merge(delete.style);
    for (final states in [
      <WidgetState>{},
      {WidgetState.pressed},
      {WidgetState.focused},
    ]) {
      final background = style.backgroundColor!.resolve(states)!;
      final overlay = style.overlayColor?.resolve(states);
      expect(
        contrastOn(
          style.foregroundColor!.resolve(states)!,
          overlay == null ? background : Color.alphaBlend(overlay, background),
        ),
        greaterThanOrEqualTo(4.5),
      );
    }

    // Delete → confirm → back on the list without it.
    await tester.tap(find.widgetWithText(ElevatedButton, 'Delete'));
    await tester.pumpAndSettle();
    expect(find.text('Delete food item'), findsOneWidget);

    await tester.tap(find.widgetWithText(ElevatedButton, 'Delete').last);
    await tester.pumpAndSettle();

    expect(find.byType(MealDetailScreen), findsNothing);
    expect(find.byType(MealHistoryScreen), findsOneWidget);
    expect(find.text('Lunch wrap'), findsNothing);
    expect(find.text('Breakfast bowl'), findsOneWidget);
    expect(find.text('300 kcal'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
