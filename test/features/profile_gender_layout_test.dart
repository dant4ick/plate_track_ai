import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:hive_test/hive_test.dart';
import 'package:plate_track_ai/core/services/user_profile_service.dart';
import 'package:plate_track_ai/core/themes/app_theme.dart';
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
    await setUpTestHive();
    Hive.registerAdapter(UserProfileAdapter());
    Hive.registerAdapter(GenderAdapter());
    Hive.registerAdapter(ActivityLevelAdapter());
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
  });
  tearDownAll(Hive.close);

  testWidgets(
    'Russian gender labels stay whole and remain selectable on phones',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        EasyLocalization(
          supportedLocales: const [Locale('en'), Locale('ru')],
          path: 'assets/translations',
          startLocale: const Locale('ru'),
          fallbackLocale: const Locale('en'),
          saveLocale: false,
          child: Builder(
            builder: (context) => MaterialApp(
              theme: AppTheme.lightTheme,
              localizationsDelegates: context.localizationDelegates,
              supportedLocales: context.supportedLocales,
              locale: context.locale,
              home: const UserSetupScreen(isEditing: true),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      for (final width in [320.0, 360.0, 390.0, 430.0]) {
        tester.view.physicalSize = Size(width, 844);
        await tester.pumpAndSettle();
        for (final label in ['Мужчина', 'Женщина']) {
          final rich = find.descendant(
            of: find.text(label),
            matching: find.byType(RichText),
          );
          final text = tester.widget<RichText>(rich);
          final painter = TextPainter(
            text: text.text,
            textDirection:
                text.textDirection ?? Directionality.of(tester.element(rich)),
            textScaler: text.textScaler,
            locale: text.locale,
          )..layout(maxWidth: tester.getSize(rich).width);
          expect(
            painter.computeLineMetrics(),
            hasLength(1),
            reason: '$label at $width dp',
          );
          painter.dispose();
        }
        expect(tester.takeException(), isNull);
      }
      await tester.ensureVisible(find.text('Женщина'));
      await tester.tap(find.text('Женщина'));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<RadioGroup<Gender>>(find.byType(RadioGroup<Gender>))
            .groupValue,
        Gender.female,
      );
      expect(tester.takeException(), isNull);
    },
  );
}
