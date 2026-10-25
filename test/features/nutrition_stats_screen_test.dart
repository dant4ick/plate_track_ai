import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:hive_test/hive_test.dart';
import 'package:plate_track_ai/core/services/food_storage_service.dart';
import 'package:plate_track_ai/core/services/user_profile_service.dart';
import 'package:plate_track_ai/core/themes/app_theme.dart';
import 'package:plate_track_ai/features/nutrition_stats/nutrition_stats_screen.dart';
import 'package:plate_track_ai/features/nutrition_stats/nutrition_trend_chart.dart';
import 'package:plate_track_ai/features/nutrition_stats/nutrition_macro_breakdown.dart';
import 'package:plate_track_ai/shared/models/food_item_adapters.dart';
import 'package:plate_track_ai/shared/models/user_profile.dart';
import 'package:plate_track_ai/shared/models/user_profile_adapters.dart';

import '../test_utils.dart';
import '../widgets/localized_pump.dart';

void main() {
  final storage = FoodStorageService();
  final translations = <String, Map<String, dynamic>>{};
  late double dailyGoal;
  setUpAll(() async {
    await initLocalization();
    for (final locale in ['en', 'ru']) {
      translations[locale] =
          jsonDecode(
                await rootBundle.loadString('assets/translations/$locale.json'),
              )
              as Map<String, dynamic>;
    }
    final fonts = FontLoader(AppTheme.fontFamily);
    for (final face in ['Regular', 'Medium', 'SemiBold', 'Bold']) {
      fonts.addFont(
        rootBundle.load('assets/fonts/Montserrat/Montserrat-$face.ttf'),
      );
    }
    await fonts.load();
    await setUpTestHive();
    Hive.registerAdapter(FoodItemAdapter());
    Hive.registerAdapter(NutritionFactsAdapter());
    Hive.registerAdapter(UserProfileAdapter());
    Hive.registerAdapter(GenderAdapter());
    Hive.registerAdapter(ActivityLevelAdapter());
    await Hive.openBox('food_items', bytes: Uint8List(0));
    await Hive.openBox<UserProfile>('userProfile', bytes: Uint8List(0));
    await Hive.openBox('weight_history', bytes: Uint8List(0));
    final profiles = UserProfileService();
    await profiles.initialize();
    await profiles.createProfile(
      age: 30,
      weight: 70,
      height: 175,
      gender: Gender.male,
      activityLevel: ActivityLevel.moderatelyActive,
    );
    dailyGoal = profiles.getNutritionTargets()!['calories']!;
    await storage.initialize();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    for (var i = 0; i < 8; i++) {
      await storage.saveFoodItem(
        TestDataFactory.createFoodItem(
          name: 'Meal $i',
          calories: i == 0 ? 200 : 300 + i * 150,
          mass: i == 0 ? 150 : 100,
          protein: 10 + i * 10,
          fat: 5 + i * 5,
          carbs: 20 + i * 20,
          timestamp: DateTime(today.year, today.month, today.day - i),
        ),
      );
    }
  });
  tearDownAll(Hive.close);

  testWidgets('daily calorie averages use the same daily goal in every period', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final appearance = ValueNotifier((AppTheme.lightTheme, 1.0));
    addTearDown(appearance.dispose);
    final preview = GlobalKey();
    await tester.pumpWidget(
      EasyLocalization(
        supportedLocales: const [Locale('en'), Locale('ru')],
        path: 'assets/translations',
        assetLoader: _Translations(translations),
        startLocale: const Locale('en'),
        fallbackLocale: const Locale('en'),
        saveLocale: false,
        child: Builder(
          builder: (context) => ValueListenableBuilder(
            valueListenable: appearance,
            builder: (context, value, _) => MaterialApp(
              debugShowCheckedModeBanner: false,
              theme: value.$1,
              localizationsDelegates: context.localizationDelegates,
              supportedLocales: context.supportedLocales,
              locale: context.locale,
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(
                  context,
                ).copyWith(textScaler: TextScaler.linear(value.$2)),
                child: child!,
              ),
              home: RepaintBoundary(
                key: preview,
                child: const NutritionStatsScreen(),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    Future<void> select(String label) async {
      final chip = find.widgetWithText(ChoiceChip, label);
      await tester.ensureVisible(chip);
      await tester.tap(chip);
      await tester.pumpAndSettle();
    }

    String? text(String key) =>
        tester.widget<Text>(find.byKey(ValueKey(key))).data;
    NutritionTrendChart chart() =>
        tester.widget<NutritionTrendChart>(find.byType(NutritionTrendChart));
    final bars = find.byWidgetPredicate(
      (w) =>
          w is InkWell &&
          w.key is ValueKey<String> &&
          (w.key as ValueKey<String>).value.startsWith('calorie-bar-'),
    );
    expect(find.text('Your calories'), findsOneWidget);
    expect(text('stats-total-calories'), '300 kcal');
    expect(
      text('stats-macro-protein'),
      '15 / ${(dailyGoal * .2 / 4).round()} g',
    );
    expect(text('stats-macro-fat'), '8 / ${(dailyGoal * .3 / 9).round()} g');
    expect(text('stats-macro-carbs'), '30 / ${(dailyGoal * .5 / 4).round()} g');
    expect(bars, findsNWidgets(8));
    expect(chart().dailyTarget, dailyGoal);
    final goalText =
        'Goal: ${NumberFormat.decimalPattern('en').format(dailyGoal.round())} kcal/day';
    expect(text('stats-calorie-goal'), goalText);
    expect(find.textContaining('Meal '), findsNothing);
    expect(find.text('Recent meals'), findsNothing);
    expect(find.text('Daily average'), findsNothing);
    expect(find.text('All time'), findsNothing);
    expect(find.byType(TabBar), findsNothing);

    expect(find.byType(RefreshIndicator), findsNothing);
    expect(find.byTooltip('Refresh'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('calorie-bar-5')));
    await tester.pumpAndSettle();
    expect(text('stats-total-calories'), '600 kcal');
    expect(
      text('stats-macro-protein'),
      '30 / ${(dailyGoal * .2 / 4).round()} g',
    );
    expect(chart().selectedIndex, 5);
    await select('Week');
    expect(bars, findsNWidgets(8));
    expect(chart().selectedIndex, 7);
    expect(chart().dailyTarget, dailyGoal);
    expect(
      chart().summary.buckets.last.averageCalories,
      300 + 75 * (DateTime.now().weekday - 1),
    );
    expect(text('stats-calorie-goal'), goalText);
    await select('Month');
    expect(bars, findsNWidgets(8));
    expect(chart().dailyTarget, dailyGoal);
    expect(text('stats-calorie-goal'), goalText);
    expect(text('stats-total-calories'), endsWith('kcal/day'));
    expect(find.text('Daily average / daily target'), findsOneWidget);

    for (final locale in ['en', 'ru']) {
      await tester
          .element(find.byType(NutritionStatsScreen))
          .setLocale(Locale(locale));
      await tester.pumpAndSettle();
      final themes = [
        AppTheme.lightTheme,
        AppTheme.darkTheme,
        AppTheme.pickMeTheme,
      ];
      for (var theme = 0; theme < themes.length; theme++) {
        for (final width in [320.0, 390.0]) {
          for (final scale in [1.0, 1.5]) {
            tester.view.physicalSize = Size(width, 1000);
            appearance.value = (themes[theme], scale);
            await tester.pumpAndSettle();
            for (final label
                in locale == 'en'
                    ? ['Day', 'Week', 'Month']
                    : ['День', 'Неделя', 'Месяц']) {
              await select(label);
              expect(bars, findsNWidgets(8));
              expect(chart().dailyTarget, dailyGoal);
              final breakdown = tester.widget<NutritionMacroBreakdown>(
                find.byType(NutritionMacroBreakdown),
              );
              expect(
                breakdown.bucket,
                same(chart().summary.buckets[chart().selectedIndex]),
              );
              expect(
                breakdown.targets!['protein'],
                closeTo(dailyGoal * .2 / 4, .001),
              );
              expect(
                text('stats-calorie-goal'),
                '${locale == 'en' ? 'Goal' : 'Цель'}: ${NumberFormat.decimalPattern(locale).format(dailyGoal.round())} ${locale == 'en' ? 'kcal/day' : 'Ккал/день'}',
              );
              expect(
                tester.takeException(),
                isNull,
                reason: '$locale theme=$theme width=$width scale=$scale $label',
              );
            }
            if (Platform.environment['STATS_PREVIEW'] == '1' &&
                locale == 'ru' &&
                width == 390 &&
                scale == 1) {
              await select('День');
              final boundary =
                  preview.currentContext!.findRenderObject()
                      as RenderRepaintBoundary;
              await tester.runAsync(() async {
                final image = await boundary.toImage();
                final bytes = await image.toByteData(
                  format: ui.ImageByteFormat.png,
                );
                final file = File('build/previews/calories-$locale-$theme.png');
                await file.parent.create(recursive: true);
                await file.writeAsBytes(bytes!.buffer.asUint8List());
                image.dispose();
              });
            }
          }
        }
      }
    }
    final editor = UserProfileService();
    await editor.initialize();
    await editor.updateProfile(weight: 85);
    await tester.pumpAndSettle();
    dailyGoal = editor.getNutritionTargets()!['calories']!;
    expect(chart().dailyTarget, dailyGoal);

    await select('День');
    // Hive's stream listener was registered in setUpAll's real async zone.
    await tester.runAsync(() async {
      await storage.clearAllData();
      await Future<void>.delayed(Duration.zero);
    });
    await tester.pumpAndSettle();
    expect(text('stats-total-calories'), '0 Ккал');
    expect(bars, findsNWidgets(8));
    expect(find.text('За этот период пока нет записей о еде'), findsOneWidget);
    expect(chart().dailyTarget, dailyGoal);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
  });
}

class _Translations extends AssetLoader {
  const _Translations(this.data);
  final Map<String, Map<String, dynamic>> data;
  @override
  Future<Map<String, dynamic>> load(String path, Locale locale) async =>
      data[locale.languageCode]!;
}
