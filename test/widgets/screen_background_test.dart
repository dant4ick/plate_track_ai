import 'dart:io';
import 'dart:ui' as ui;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:hive_test/hive_test.dart';
import 'package:plate_track_ai/shared/models/user_profile.dart';
import 'package:plate_track_ai/shared/models/user_profile_adapters.dart';
import 'package:plate_track_ai/core/themes/app_theme.dart';
import 'package:plate_track_ai/features/user_setup/user_setup_screen.dart';
import 'package:plate_track_ai/shared/widgets/app_scaffold.dart';
import 'package:plate_track_ai/shared/widgets/bottom_action_bar.dart';

import 'localized_pump.dart';

void main() {
  setUpAll(() async {
    await initLocalization();
    await setUpTestHive();
    Hive.registerAdapter(UserProfileAdapter());
    Hive.registerAdapter(GenderAdapter());
    Hive.registerAdapter(ActivityLevelAdapter());
    await Hive.openBox<UserProfile>('userProfile', bytes: Uint8List(0));
    await Hive.openBox('weight_history', bytes: Uint8List(0));
    for (final face in ['Regular', 'SemiBold']) {
      await (FontLoader(AppTheme.fontFamily)..addFont(
            rootBundle.load('assets/fonts/Montserrat/Montserrat-$face.ttf'),
          ))
          .load();
    }
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
  });

  tearDownAll(Hive.close);

  testWidgets('pinned actions do not hide the dark gradient endpoint', (
    tester,
  ) async {
    for (final theme in [
      AppTheme.lightTheme,
      AppTheme.darkTheme,
      AppTheme.pickMeTheme,
    ]) {
      await tester.pumpWidget(
        MaterialApp(
          theme: theme,
          home: const AppScaffold(
            bottomNavigationBar: BottomActionBar(children: [Text('Save')]),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final container = tester.widget<Container>(
        find
            .descendant(
              of: find.byType(BottomActionBar),
              matching: find.byType(Container),
            )
            .first,
      );
      final fill = (container.decoration! as BoxDecoration).color;
      expect(
        fill,
        theme == AppTheme.darkTheme
            ? Colors.transparent
            : theme.scaffoldBackgroundColor,
      );
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('ordinary screen has full-height dark gradient only', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1170, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final boundaryKey = GlobalKey();
    await tester.pumpWidget(
      EasyLocalization(
        supportedLocales: const [Locale('en')],
        path: 'assets/translations',
        startLocale: const Locale('en'),
        fallbackLocale: const Locale('en'),
        child: Builder(
          builder: (context) => RepaintBoundary(
            key: boundaryKey,
            child: Row(
              textDirection: ui.TextDirection.ltr,
              children: [
                for (final theme in [
                  AppTheme.lightTheme,
                  AppTheme.darkTheme,
                  AppTheme.pickMeTheme,
                ])
                  Expanded(
                    child: MaterialApp(
                      debugShowCheckedModeBanner: false,
                      theme: theme,
                      localizationsDelegates: context.localizationDelegates,
                      supportedLocales: context.supportedLocales,
                      locale: context.locale,
                      home: const UserSetupScreen(),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    final gradients = find.byWidgetPredicate(
      (widget) =>
          widget is DecoratedBox &&
          widget.decoration is BoxDecoration &&
          (widget.decoration as BoxDecoration).gradient != null,
    );
    expect(
      gradients,
      findsOneWidget,
      reason:
          'Only dark screens paint a page gradient, including behind the app bar.',
    );
    final box = tester.widget<DecoratedBox>(gradients);
    final gradient =
        (box.decoration as BoxDecoration).gradient! as LinearGradient;
    expect(gradient.begin, Alignment.topCenter);
    expect(gradient.end, Alignment.bottomCenter);
    expect(gradient.colors, const [Color(0xFF1A191F), Color(0xFF120E2A)]);
    expect(tester.getSize(gradients), const Size(390, 844));
    final scaffolds = tester
        .widgetList<Scaffold>(find.byType(Scaffold))
        .toList();
    expect(
      scaffolds[0].backgroundColor ??
          AppTheme.lightTheme.scaffoldBackgroundColor,
      const Color(0xFFFFFFFF),
    );
    expect(scaffolds[1].backgroundColor, Colors.transparent);
    expect(
      scaffolds[2].backgroundColor ??
          AppTheme.pickMeTheme.scaffoldBackgroundColor,
      const Color(0xFFFFF6F9),
    );
    expect(AppTheme.darkTheme.colorScheme.surface, const Color(0xFF262A35));
    expect(AppTheme.darkTheme.cardTheme.color, const Color(0xFF262A35));

    // Inspect real painted pixels, not only the decoration configuration.
    // Edge samples avoid the scrolling cards and app-bar text.
    await tester.runAsync(() async {
      final boundary =
          boundaryKey.currentContext!.findRenderObject()!
              as RenderRepaintBoundary;
      final image = await boundary.toImage();
      final rgba = (await image.toByteData(
        format: ui.ImageByteFormat.rawRgba,
      ))!;
      List<int> pixel(int x, int y) => List.generate(
        4,
        (channel) => rgba.getUint8((y * image.width + x) * 4 + channel),
      );
      expect(pixel(390, 0), [0x1A, 0x19, 0x1F, 0xFF]);
      expect(pixel(390, 843), [0x12, 0x0E, 0x2A, 0xFF]);
      expect(pixel(0, 843), [0xFF, 0xFF, 0xFF, 0xFF]);
      expect(pixel(780, 843), [0xFF, 0xF6, 0xF9, 0xFF]);
      const output = String.fromEnvironment('GRADIENT_PREVIEW_PATH');
      if (output.isNotEmpty) {
        final data = await image.toByteData(format: ui.ImageByteFormat.png);
        final file = File(output);
        await file.parent.create(recursive: true);
        await file.writeAsBytes(data!.buffer.asUint8List());
      }
      image.dispose();
    });
  });
}
