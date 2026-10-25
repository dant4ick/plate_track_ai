import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plate_track_ai/core/themes/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Boots easy_localization once for the test process. Call from `setUpAll`.
Future<void> initLocalization() async {
  TestWidgetsFlutterBinding.ensureInitialized();
  // easy_localization persists the chosen locale through shared_preferences,
  // which has no platform implementation under `flutter test`.
  SharedPreferences.setMockInitialValues({});
  await EasyLocalization.ensureInitialized();
}

/// Pumps [home] under the real translations and app theme at phone size.
///
/// EasyLocalization initialises once per process, so a file that needs several
/// screens should pump once and navigate, or split into several files.
Future<void> pumpLocalized(
  WidgetTester tester,
  Widget home, {
  ThemeData? theme,
  Size size = const Size(390, 844),
}) async {
  tester.view.physicalSize = size;
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
          theme: theme ?? AppTheme.lightTheme,
          localizationsDelegates: context.localizationDelegates,
          supportedLocales: context.supportedLocales,
          locale: context.locale,
          home: home,
        ),
      ),
    ),
  );
  // The translation JSON loads asynchronously.
  await tester.pumpAndSettle(const Duration(seconds: 1));
}
