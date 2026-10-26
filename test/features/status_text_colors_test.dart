import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:hive_test/hive_test.dart';
import 'package:plate_track_ai/core/services/food_storage_service.dart';
import 'package:plate_track_ai/core/services/user_profile_service.dart';
import 'package:plate_track_ai/core/themes/app_theme.dart';
import 'package:plate_track_ai/features/profile/profile_management_screen.dart';
import 'package:plate_track_ai/features/recommendations/recommendations_screen.dart';
import 'package:plate_track_ai/features/user_setup/user_setup_screen.dart';
import 'package:plate_track_ai/shared/models/food_item_adapters.dart';
import 'package:plate_track_ai/shared/models/user_profile.dart';
import 'package:plate_track_ai/shared/models/user_profile_adapters.dart';

import '../color_test_utils.dart';
import '../test_utils.dart';
import '../widgets/localized_pump.dart';

void main() {
  setUpAll(() async {
    await initLocalization();
    await setUpTestHive();
    Hive.registerAdapter(FoodItemAdapter());
    Hive.registerAdapter(NutritionFactsAdapter());
    Hive.registerAdapter(UserProfileAdapter());
    Hive.registerAdapter(GenderAdapter());
    Hive.registerAdapter(ActivityLevelAdapter());
    await Hive.openBox<UserProfile>('userProfile', bytes: Uint8List(0));
    await Hive.openBox('weight_history', bytes: Uint8List(0));
    await Hive.openBox('food_items', bytes: Uint8List(0));
    final profiles = UserProfileService();
    await profiles.initialize();
    await profiles.createProfile(
      age: 30,
      weight: 70,
      height: 175,
      gender: Gender.male,
      activityLevel: ActivityLevel.moderatelyActive,
    );
    final foods = FoodStorageService();
    await foods.initialize();
    await foods.saveFoodItem(TestDataFactory.createFoodItem(calories: 99999));
  });
  tearDownAll(Hive.close);

  testWidgets('BMR, advice and reset labels stay readable in all themes', (
    tester,
  ) async {
    await pumpLocalized(
      tester,
      Scaffold(
        body: SingleChildScrollView(
          child: Column(
            children: [
              for (final theme in [
                AppTheme.lightTheme,
                AppTheme.darkTheme,
                AppTheme.pickMeTheme,
              ])
                Theme(
                  data: theme,
                  child: Column(
                    children: const [
                      SizedBox(
                        height: 1000,
                        child: UserSetupScreen(isEditing: true),
                      ),
                      SizedBox(height: 1000, child: UserSetupScreen()),
                      SizedBox(height: 1000, child: RecommendationsScreen()),
                      SizedBox(height: 1000, child: ProfileManagementScreen()),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
      // This test checks colours; leave room for the harness's wide Ahem font.
      size: const Size(600, 1200),
    );
    expect(tester.takeException(), isNull);

    // The profile person icon has no circular coloured avatar background.
    final avatarBackgrounds = find.ancestor(
      of: find.byIcon(Icons.person_rounded),
      matching: find.byWidgetPredicate(
        (widget) =>
            widget is Container &&
            widget.constraints?.maxWidth == 64 &&
            widget.constraints?.maxHeight == 64 &&
            widget.decoration != null,
      ),
    );
    expect(find.byIcon(Icons.person_rounded), findsNWidgets(3));
    expect(avatarBackgrounds, findsNothing);

    // Include small explanatory text, not only the large BMR values/titles.
    final secondary = find.descendant(
      of: find.byType(UserSetupScreen),
      matching: find.byType(Text),
    );
    for (final element in secondary.evaluate()) {
      final text = element.widget as Text;
      if (text.style?.color == null) continue;
      final containers = tester.widgetList<Container>(
        find.ancestor(
          of: find.byWidget(text),
          matching: find.byType(Container),
        ),
      );
      final fills = containers
          .where(
            (w) =>
                w.decoration is BoxDecoration &&
                (w.decoration as BoxDecoration).color != null,
          )
          .toList();
      if (fills.isEmpty) continue;
      var background = Theme.of(element).colorScheme.surface;
      for (final panel in fills.reversed) {
        background = Color.alphaBlend(
          (panel.decoration as BoxDecoration).color!,
          background,
        );
      }
      expect(
        contrastOn(text.style!.color!, background),
        greaterThanOrEqualTo(4.5),
        reason: text.data,
      );
    }

    final values = find.descendant(
      of: find.byType(UserSetupScreen),
      matching: find.byWidgetPredicate(
        (w) => w is Text && (w.data?.endsWith('kcal/day') ?? false),
      ),
    );
    expect(values, findsNWidgets(6));
    for (final element in values.evaluate()) {
      final text = element.widget as Text;
      final panels = find.ancestor(
        of: find.byWidget(text),
        matching: find.byType(Container),
      );
      final panel = tester
          .widgetList<Container>(panels)
          .firstWhere(
            (w) =>
                w.decoration is BoxDecoration &&
                (w.decoration as BoxDecoration).color != null,
          );
      final background = (panel.decoration as BoxDecoration).color!;
      expect(
        contrastOn(
          text.style!.color!,
          background,
          surface: Theme.of(element).colorScheme.surface,
        ),
        greaterThanOrEqualTo(4.5),
      );
    }

    final reset = find.descendant(
      of: find.byType(ProfileManagementScreen),
      matching: find.byWidgetPredicate((w) => w is OutlinedButton),
    );
    expect(reset, findsNWidgets(3));
    for (final element in reset.evaluate()) {
      final button = element.widget as OutlinedButton;
      final foreground = button.style!.foregroundColor!.resolve({})!;
      expect(
        contrastOn(foreground, Theme.of(element).colorScheme.surface),
        greaterThanOrEqualTo(4.5),
      );
    }

    expect(find.byType(RefreshIndicator), findsNothing);
    expect(find.byTooltip('Refresh'), findsNothing);
    expect(find.text('Reduce calorie intake'), findsNWidgets(3));
    // All mounted recommendation views must actually recalculate on writes.
    await tester.runAsync(() async {
      await FoodStorageService().clearAllData();
      await Future<void>.delayed(Duration.zero);
    });
    await tester.pumpAndSettle();
    expect(find.text('Reduce calorie intake'), findsNothing);
    expect(find.text('Increase calorie intake'), findsNWidgets(3));
    final editor = UserProfileService();
    await editor.initialize();
    await editor.updateProfile(weight: 82);
    await tester.pumpAndSettle();
    final newTarget = editor.getNutritionTargets()!['calories']!.toInt();
    expect(
      find.textContaining('below your target ($newTarget kcal)'),
      findsNWidgets(3),
    );
    // The profile cards also pick up a different service instance's edits.
    expect(
      find.descendant(
        of: find.byType(ProfileManagementScreen),
        matching: find.text('82.0 kg'),
      ),
      findsNWidgets(3),
    );
    expect(tester.takeException(), isNull);
  });
}
