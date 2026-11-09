import 'dart:io';
import 'dart:ui' as ui;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plate_track_ai/core/themes/app_theme.dart';
import 'package:plate_track_ai/shared/models/food_item.dart';
import 'package:plate_track_ai/shared/widgets/common_widgets.dart';
import 'package:plate_track_ai/shared/widgets/food_items.dart';

import 'localized_pump.dart';

// Optional real-widget PNG (no golden files or screenshot I/O in normal CI):
// flutter test --dart-define=SCREENSHOT_DIR=build/recent-meals-preview \
//   test/widgets/recent_meals_test.dart
void main() {
  setUpAll(() async {
    await initLocalization();
    await (FontLoader(AppTheme.fontFamily)..addFont(
          rootBundle.load('assets/fonts/Montserrat/Montserrat-Regular.ttf'),
        ))
        .load();
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
  });

  testWidgets('localized chronological dividers keep real cards and controls', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 1500);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    final older = DateTime(now.year, now.month, now.day - 2);
    final lastYear = DateTime(now.year - 1, 1, 1);
    FoodItem meal(String name, DateTime date, int hour, int minute) => FoodItem(
      name: name,
      calories: 100,
      nutritionFacts: const NutritionFacts(
        protein: 10,
        carbs: 15,
        fat: 5,
        mass: 100,
      ),
      timestamp: DateTime(date.year, date.month, date.day, hour, minute),
    );
    final items = [
      meal('Breakfast', today, 8, 5),
      meal('Yesterday breakfast', yesterday, 6, 15),
      meal('Lunch', today, 14, 50),
      meal('Previous year', lastYear, 20, 30),
      meal('Yesterday dinner', yesterday, 23, 59),
      meal('Older meal', older, 18, 10),
      meal('Snack', today, 14, 10),
    ];
    final boundary = GlobalKey();
    final visibleItems = ValueNotifier(items);
    final timestamps = ValueNotifier(true);
    addTearDown(visibleItems.dispose);
    addTearDown(timestamps.dispose);
    late BuildContext sectionContext;
    await tester.pumpWidget(
      EasyLocalization(
        supportedLocales: const [Locale('en'), Locale('ru')],
        path: 'assets/translations',
        startLocale: const Locale('en'),
        fallbackLocale: const Locale('en'),
        saveLocale: false,
        child: Builder(
          builder: (context) => MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            localizationsDelegates: context.localizationDelegates,
            supportedLocales: context.supportedLocales,
            locale: context.locale,
            home: RepaintBoundary(
              key: boundary,
              child: Scaffold(
                body: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Builder(
                    builder: (context) {
                      sectionContext = context;
                      return ValueListenableBuilder<List<FoodItem>>(
                        valueListenable: visibleItems,
                        builder: (context, currentItems, _) =>
                            ValueListenableBuilder<bool>(
                              valueListenable: timestamps,
                              builder: (context, showTimestamp, _) =>
                                  buildFoodItemSection(
                                    context: context,
                                    items: currentItems,
                                    refreshCallback: () {},
                                    showDeleteButton: true,
                                    showTimestamp: showTimestamp,
                                    trailing: TextButton(
                                      onPressed: () {},
                                      child: const Text('See all'),
                                    ),
                                  ),
                            ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Today · 14:00–14:59'), findsOneWidget);
    expect(find.text('Today · 08:00–08:59'), findsOneWidget);
    expect(find.text('Yesterday'), findsOneWidget);
    expect(
      find.text(
        (older.year == now.year
                ? DateFormat.MMMMd('en')
                : DateFormat.yMMMMd('en'))
            .format(older),
      ),
      findsOneWidget,
    );
    expect(find.text(DateFormat.yMMMMd('en').format(lastYear)), findsOneWidget);
    expect(find.byType(Divider), findsNWidgets(5));
    final cards = tester
        .widgetList<FoodItemCard>(find.byType(FoodItemCard))
        .toList();
    expect(cards.map((c) => c.item.name), [
      'Lunch',
      'Snack',
      'Breakfast',
      'Yesterday dinner',
      'Yesterday breakfast',
      'Older meal',
      'Previous year',
    ]);
    expect(
      cards.every(
        (c) =>
            c.showTimestamp &&
            c.showDeleteButton &&
            c.onTap != null &&
            c.onDelete != null,
      ),
      isTrue,
    );
    expect(find.text('See all'), findsOneWidget);
    expect(find.textContaining('2:50 PM'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await sectionContext.setLocale(const Locale('ru'));
    await tester.pumpAndSettle();
    expect(find.text('Сегодня · 14:00–14:59'), findsOneWidget);
    expect(find.text('Сегодня · 08:00–08:59'), findsOneWidget);
    expect(find.text('Вчера'), findsOneWidget);
    expect(
      find.text(
        (older.year == now.year
                ? DateFormat.MMMMd('ru')
                : DateFormat.yMMMMd('ru'))
            .format(older),
      ),
      findsOneWidget,
    );
    expect(find.text(DateFormat.yMMMMd('ru').format(lastYear)), findsOneWidget);
    expect(tester.takeException(), isNull);

    const screenshotDir = String.fromEnvironment('SCREENSHOT_DIR');
    if (screenshotDir.isNotEmpty) {
      await tester.runAsync(() async {
        final render =
            boundary.currentContext!.findRenderObject()!
                as RenderRepaintBoundary;
        final image = await render.toImage(pixelRatio: 1);
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        await Directory(screenshotDir).create(recursive: true);
        await File(
          '$screenshotDir/recent-meals-ru.png',
        ).writeAsBytes(bytes!.buffer.asUint8List());
        image.dispose();
      });
    }

    timestamps.value = false;
    await tester.pumpAndSettle();
    expect(
      tester
          .widgetList<FoodItemCard>(find.byType(FoodItemCard))
          .every((c) => !c.showTimestamp),
      isTrue,
    );
    expect(find.text('Сегодня · 14:00–14:59'), findsOneWidget);
    visibleItems.value = [];
    await tester.pumpAndSettle();
    expect(find.byType(FoodItemCard), findsNothing);
    expect(find.byType(Divider), findsNothing);
    expect(find.text('Недавние блюда'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
