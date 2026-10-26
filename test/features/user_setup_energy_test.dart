import 'dart:io';
import 'dart:ui' as ui;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:hive_test/hive_test.dart';
import 'package:plate_track_ai/core/services/user_profile_service.dart';
import 'package:plate_track_ai/core/themes/app_theme.dart';
import 'package:plate_track_ai/features/profile/profile_management_screen.dart';
import 'package:plate_track_ai/features/user_setup/user_setup_screen.dart';
import 'package:plate_track_ai/shared/models/user_profile.dart';
import 'package:plate_track_ai/shared/models/user_profile_adapters.dart';

import '../widgets/localized_pump.dart';

void main() {
  setUpAll(() async {
    await initLocalization();
    final fonts = FontLoader(AppTheme.fontFamily);
    for (final face in ['Regular', 'Medium', 'SemiBold', 'Bold']) {
      fonts.addFont(
        rootBundle.load('assets/fonts/Montserrat/Montserrat-$face.ttf'),
      );
    }
    await fonts.load();
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
    await setUpTestHive();
    Hive.registerAdapter(UserProfileAdapter());
    Hive.registerAdapter(GenderAdapter());
    Hive.registerAdapter(ActivityLevelAdapter());
    await Hive.openBox<UserProfile>('userProfile', bytes: Uint8List(0));
    await Hive.openBox('weight_history', bytes: Uint8List(0));
  });
  tearDownAll(Hive.close);

  testWidgets('weight loss reveals named deficits and recalculates target', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final boundary = GlobalKey();
    await tester.pumpWidget(
      EasyLocalization(
        supportedLocales: const [Locale('en'), Locale('ru')],
        path: 'assets/translations',
        startLocale: const Locale('en'),
        fallbackLocale: const Locale('en'),
        saveLocale: false,
        child: Builder(
          builder: (context) => RepaintBoundary(
            key: boundary,
            child: MaterialApp(
              debugShowCheckedModeBanner: false,
              theme: AppTheme.lightTheme,
              localizationsDelegates: context.localizationDelegates,
              supportedLocales: context.supportedLocales,
              locale: context.locale,
              home: const UserSetupScreen(),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), '30');
    await tester.enterText(fields.at(1), '70');
    await tester.enterText(fields.at(2), '175');
    await tester.enterText(fields.at(3), '65');
    await tester.pumpAndSettle();
    expect(find.text('Weight loss'), findsOneWidget);
    expect(find.text('Moderate (15%)'), findsNothing);
    await tester.ensureVisible(find.text('Weight loss'));
    await tester.tap(find.text('Weight loss'));
    await tester.pumpAndSettle();
    expect(find.text('Gentle (10%)'), findsOneWidget);
    expect(find.text('Moderate (15%)'), findsOneWidget);
    expect(find.text('Substantial (20%)'), findsOneWidget);
    expect(find.text('1648 kcal/day'), findsOneWidget);
    expect(find.text('2802 kcal/day'), findsOneWidget);
    expect(find.text('2382 kcal/day'), findsOneWidget);
    await tester.ensureVisible(find.text('Substantial (20%)'));
    await tester.tap(find.text('Substantial (20%)'));
    await tester.pumpAndSettle();
    expect(find.text('2242 kcal/day'), findsOneWidget);
    await tester.ensureVisible(find.text('Complete'));
    await tester.tap(find.text('Complete'));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    final saved = UserProfileService();
    await saved.initialize();
    expect(saved.currentProfile!.nutritionGoal, NutritionGoal.weightLoss);
    expect(
      saved.currentProfile!.calorieReduction,
      CalorieReduction.substantial,
    );

    final navigator = Navigator.of(
      tester.element(find.byType(UserSetupScreen)),
    );
    navigator.push(
      MaterialPageRoute<void>(builder: (_) => const ProfileManagementScreen()),
    );
    await tester.pumpAndSettle();
    expect(find.text('Weight loss'), findsOneWidget);
    expect(find.text('Substantial (20%)'), findsOneWidget);
    expect(find.textContaining('Protein: 1.4 g/kg'), findsOneWidget);
    expect(find.textContaining('not a measurement'), findsOneWidget);
    await tester.tap(find.byTooltip('Edit profile'));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<RadioGroup<NutritionGoal>>(
            find.byType(RadioGroup<NutritionGoal>),
          )
          .groupValue,
      NutritionGoal.weightLoss,
    );
    expect(
      tester
          .widget<RadioGroup<CalorieReduction>>(
            find.byType(RadioGroup<CalorieReduction>),
          )
          .groupValue,
      CalorieReduction.substantial,
    );
    await tester.ensureVisible(find.text('Maintain weight'));
    await tester.tap(find.text('Maintain weight'));
    await tester.pumpAndSettle();
    expect(find.text('Substantial (20%)'), findsNothing);
    expect(find.text('Daily calorie target'), findsNothing);
    await tester.ensureVisible(find.text('Save changes'));
    await tester.tap(find.text('Save changes'));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    await saved.initialize();
    expect(saved.currentProfile!.nutritionGoal, NutritionGoal.maintenance);
    expect(
      find.textContaining('20% protein, 50% carbs, 30% fat'),
      findsOneWidget,
    );
    expect(find.text('Substantial (20%)'), findsNothing);

    await tester.ensureVisible(find.byTooltip('Edit profile'));
    await tester.tap(find.byTooltip('Edit profile'));
    await tester.pumpAndSettle();
    final editingFields = find.byType(TextFormField);
    await tester.ensureVisible(editingFields.at(0));
    await tester.enterText(editingFields.at(0), '');
    await tester.pumpAndSettle();
    expect(find.text('1648 kcal/day'), findsNothing);
    expect(find.text('2802 kcal/day'), findsNothing);
    await tester.enterText(editingFields.at(0), '30');
    await tester.enterText(editingFields.at(2), '99');
    await tester.pumpAndSettle();
    expect(find.text('1648 kcal/day'), findsNothing);
    await tester.enterText(editingFields.at(2), '175');
    await tester.ensureVisible(find.text('Русский'));
    await tester.tap(find.text('Русский'));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    expect(find.text('Цель питания'), findsOneWidget);
    await tester.ensureVisible(find.text('Снижение веса'));
    await tester.tap(find.text('Снижение веса'));
    await tester.pumpAndSettle();
    expect(find.text('Мягкий (10%)'), findsOneWidget);
    expect(find.text('Умеренный (15%)'), findsOneWidget);
    expect(find.text('Выраженный (20%)'), findsOneWidget);
    await tester.ensureVisible(find.text('Умеренный (15%)'));
    await tester.tap(find.text('Умеренный (15%)'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Цель питания'));
    await tester.pumpAndSettle();
    const screenshotDir = String.fromEnvironment('SCREENSHOT_DIR');
    if (screenshotDir.isNotEmpty) {
      final render =
          boundary.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      await tester.runAsync(() async {
        final image = await render.toImage(pixelRatio: 1);
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        await Directory(screenshotDir).create(recursive: true);
        await File(
          '$screenshotDir/nutrition-goal-ru.png',
        ).writeAsBytes(bytes!.buffer.asUint8List());
        image.dispose();
      });
    }
    await tester.ensureVisible(editingFields.at(0));
    await tester.enterText(editingFields.at(0), '17');
    await tester.pumpAndSettle();
    expect(find.text('Дневная цель калорий'), findsNothing);
    expect(find.textContaining('только для взрослых'), findsOneWidget);
    await tester.ensureVisible(find.text('Сохранить изменения'));
    await tester.tap(find.text('Сохранить изменения'));
    await tester.pumpAndSettle();
    await saved.initialize();
    expect(saved.currentProfile!.nutritionGoal, NutritionGoal.maintenance);
    await tester.ensureVisible(editingFields.at(0));
    await tester.enterText(editingFields.at(0), '30');
    await tester.enterText(editingFields.at(1), '50');
    await tester.pumpAndSettle();
    expect(find.text('Дневная цель калорий'), findsNothing);
    expect(find.textContaining('только для взрослых'), findsWidgets);
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    await tester.ensureVisible(editingFields.at(0));
    await tester.enterText(editingFields.at(0), '120');
    await tester.enterText(editingFields.at(1), '20');
    await tester.enterText(editingFields.at(2), '100');
    await tester.enterText(editingFields.at(3), '20');
    await tester.ensureVisible(find.text('Женщина'));
    await tester.tap(find.text('Женщина'));
    await tester.ensureVisible(find.text('Малоподвижный'));
    await tester.tap(find.text('Малоподвижный'));
    await tester.pumpAndSettle();
    expect(find.text('Дневная цель калорий'), findsNothing);
    await tester.ensureVisible(find.text('Сохранить изменения'));
    await tester.tap(find.text('Сохранить изменения'));
    await tester.pumpAndSettle();
    await saved.initialize();
    expect(saved.currentProfile!.nutritionGoal, NutritionGoal.maintenance);
    expect(find.byType(UserSetupScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
