import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plate_track_ai/core/themes/app_theme.dart';
import 'package:plate_track_ai/shared/widgets/common_widgets.dart';

import '../test_utils.dart';

Future<void> pump(WidgetTester tester, Widget child) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.lightTheme,
      home: Scaffold(body: Padding(padding: const EdgeInsets.all(16), child: child)),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  final item = TestDataFactory.createFoodItem(
    name: 'Grilled chicken salad',
    calories: 407,
    mass: 100,
    timestamp: DateTime(2026, 8, 18, 13, 20),
  );

  group('FoodItemCard', () {
    testWidgets('prints the timestamp by default', (tester) async {
      await pump(tester, FoodItemCard(item: item));

      expect(find.textContaining('Aug 18'), findsOneWidget);
    });

    testWidgets('drops the timestamp but keeps the portion when asked', (
      tester,
    ) async {
      await pump(tester, FoodItemCard(item: item, showTimestamp: false));

      expect(find.textContaining('Aug 18'), findsNothing);
      expect(find.textContaining('1:20'), findsNothing);
      expect(find.text('100g'), findsOneWidget);
    });

    testWidgets('fires onTap', (tester) async {
      var tapped = false;
      await pump(
        tester,
        FoodItemCard(item: item, onTap: () => tapped = true),
      );

      await tester.tap(find.text('Grilled chicken salad'));
      expect(tapped, isTrue);
    });

    testWidgets('hides the inline delete control unless asked', (tester) async {
      await pump(tester, FoodItemCard(item: item, onDelete: () {}));

      expect(find.byIcon(Icons.close_rounded), findsNothing);
    });
  });
}
