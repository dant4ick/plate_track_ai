import 'dart:io';
import 'dart:typed_data';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show FontLoader;
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:plate_track_ai/core/themes/app_colors.dart';
import 'package:plate_track_ai/core/themes/app_dimens.dart';
import 'package:plate_track_ai/core/themes/app_theme.dart';
import 'package:plate_track_ai/shared/models/food_item.dart';
import 'package:plate_track_ai/shared/widgets/app_logo.dart';
import 'package:plate_track_ai/shared/widgets/calorie_gauge.dart';
import 'package:plate_track_ai/shared/widgets/common_widgets.dart';
import 'package:plate_track_ai/shared/widgets/macro_bars.dart';
import 'package:plate_track_ai/shared/widgets/soft_card.dart';
import 'package:plate_track_ai/shared/widgets/weight_card.dart';

/// Builds the redesigned dashboard from fixed data — the real screen is driven
/// by Hive-backed services, so the composition is reassembled here from the same
/// widgets.
///
/// Two jobs, deliberately split:
///
///  * Always: assert the composition lays out without overflow at phone width in
///    both themes, and that the figures reach the screen. This is the part CI
///    runs, and it holds on any platform.
///  * Opt-in: with `DESIGN_PREVIEW=1`, also compare against a golden PNG. Golden
///    pixels depend on the host's fonts, so that comparison is never part of a
///    normal `flutter test`. Regenerate the image with:
///
///        DESIGN_PREVIEW=1 flutter test test/design --update-goldens
void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    // easy_localization persists the selected locale through shared_preferences,
    // which has no platform implementation under `flutter test`.
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
    await _loadPreviewFont();
  });

  // LOCAL PREVIEW ONLY — see _loadPreviewFont.
  // Both themes render in a single pump: EasyLocalization initialises once per
  // process, so a second pumpWidget in the same file comes up empty.
  testWidgets('dashboard — light and dark', (tester) async {
    const width = 390.0;
    tester.view.physicalSize = const Size(width * 2, 1900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      EasyLocalization(
        supportedLocales: const [Locale('en')],
        path: 'assets/translations',
        fallbackLocale: const Locale('en'),
        startLocale: const Locale('en'),
        child: Builder(
          builder: (context) => MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            localizationsDelegates: context.localizationDelegates,
            supportedLocales: context.supportedLocales,
            locale: context.locale,
            home: Row(
              children: [
                for (final base in [AppTheme.lightTheme, AppTheme.darkTheme])
                  SizedBox(
                    width: width,
                    child: Theme(
                      data: base.copyWith(
                        textTheme: base.textTheme.apply(
                          fontFamily: _previewFamily,
                        ),
                      ),
                      child: const _DashboardPreview(),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );

    // easy_localization loads its JSON asynchronously.
    await tester.pumpAndSettle(const Duration(seconds: 1));

    // Overflow during layout surfaces as a thrown exception, so a clean take
    // means the composition fits at 390 dp in both themes.
    expect(tester.takeException(), isNull);

    // Both columns render, hence two of everything.
    expect(find.text('Your weight'), findsNWidgets(2));
    expect(find.text("Today's summary"), findsNWidgets(2));
    expect(find.text('Recent meals'), findsNWidgets(2));
    expect(find.text('67'), findsNWidgets(2));
    expect(find.text('15%'), findsNWidgets(2));
    // Not find.text('500') — the chart's y-axis prints that label too.
    expect(find.byType(CalorieGauge), findsNWidgets(2));
    expect(find.text('calories left'), findsNWidgets(2));
    // The weekly sections and the advice moved off the dashboard: weekly stats
    // live behind "Today's summary", and the tips section was removed.
    expect(find.text('Weekly calories'), findsNothing);
    expect(find.text('Improve your nutrition'), findsNothing);
    // Recent meals no longer carry a date — the detail screen does.
    expect(find.textContaining('Aug 18'), findsNothing);

    if (Platform.environment['DESIGN_PREVIEW'] == '1') {
      await expectLater(
        find.byType(Row).first,
        matchesGoldenFile('goldens/dashboard.png'),
      );
    }
  });
}

const _previewFamily = 'PreviewSans';

/// Loads a real typeface so the preview shows glyphs instead of the test
/// harness's filled boxes.
///
/// Best-effort and host-specific: if none of the candidates exist the test falls
/// back to the harness font, which is *wider*, so the layout assertions stay at
/// least as strict as they are locally.
Future<void> _loadPreviewFont() async {
  const candidates = [
    '/System/Library/Fonts/Supplemental/Arial.ttf',
    '/System/Library/Fonts/Supplemental/Verdana.ttf',
  ];
  for (final path in candidates) {
    final file = File(path);
    if (!file.existsSync()) continue;
    final bytes = await file.readAsBytes();
    final loader = FontLoader(_previewFamily)
      ..addFont(Future.value(ByteData.view(Uint8List.fromList(bytes).buffer)));
    await loader.load();
    return;
  }
}

class _DashboardPreview extends StatelessWidget {
  const _DashboardPreview();

  static final _items = [
    FoodItem(
      name: 'Grilled chicken salad',
      calories: 407,
      nutritionFacts: NutritionFacts(
        protein: 32,
        carbs: 23,
        fat: 20,
        mass: 100,
      ),
      timestamp: DateTime(2026, 8, 18, 13, 20),
    ),
    FoodItem(
      name: 'Overnight oats',
      calories: 289,
      nutritionFacts: NutritionFacts(
        protein: 11,
        carbs: 44,
        fat: 7,
        mass: 100,
      ),
      timestamp: DateTime(2026, 8, 18, 8, 5),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 16,
        title: const AppLogoWithText(),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 8),
            child: Icon(Icons.settings_outlined),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        child: const Icon(Icons.add_rounded, size: 32),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppDimens.gutter,
          AppDimens.gutter,
          AppDimens.gutter,
          96,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionHeader('your_weight'.tr(), trailing: const _SeeAllStub()),
            WeightCard(
              current: 67,
              start: 70,
              goal: 50,
              progress: 0.15,
              onEdit: () {},
            ),
            const SizedBox(height: AppDimens.sectionGap),
            SectionHeader('todays_summary'.tr(), trailing: const _SeeAllStub()),
            SoftCard(
              padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
              child: Column(
                children: [
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: CalorieGauge(consumed: 1500, target: 2000),
                  ),
                  const SizedBox(height: 18),
                  const MacroBars(
                    macros: [
                      MacroProgress(
                        macro: Macro.protein,
                        grams: 112,
                        target: 150,
                      ),
                      MacroProgress(macro: Macro.carbs, grams: 112, target: 250),
                      MacroProgress(macro: Macro.fat, grams: 112, target: 70),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppDimens.sectionGap),
            SectionHeader('recent_items'.tr(), trailing: const _SeeAllStub()),
            for (final item in _items) ...[
              FoodItemCard(item: item, showTimestamp: false, onTap: () {}),
              const SizedBox(height: 10),
            ],
          ],
        ),
      ),
    );
  }
}

/// Stands in for the dashboard's private "See all" link.
class _SeeAllStub extends StatelessWidget {
  const _SeeAllStub();

  @override
  Widget build(BuildContext context) {
    return Text(
      'see_all'.tr(),
      style: Theme.of(context).textTheme.labelMedium?.copyWith(
        color: Theme.of(context).colorScheme.primary,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}
