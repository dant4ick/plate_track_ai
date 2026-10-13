import 'dart:typed_data';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:hive_test/hive_test.dart';
import 'package:plate_track_ai/core/services/user_profile_service.dart';
import 'package:plate_track_ai/core/services/weight_history_service.dart';
import 'package:plate_track_ai/features/weight/weight_history_screen.dart';
import 'package:plate_track_ai/shared/models/user_profile.dart';
import 'package:plate_track_ai/shared/models/user_profile_adapters.dart';
import 'package:plate_track_ai/shared/widgets/weight_card.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../widgets/localized_pump.dart';

void main() {
  // Storage is seeded here, outside the widget test's fake-async zone, and the
  // boxes are opened in memory so nothing the screen does waits on file I/O.
  setUpAll(() async {
    await initLocalization();
    SharedPreferences.setMockInitialValues({});
    await setUpTestHive();
    if (!Hive.isAdapterRegistered(2)) Hive.registerAdapter(UserProfileAdapter());
    if (!Hive.isAdapterRegistered(3)) Hive.registerAdapter(GenderAdapter());
    if (!Hive.isAdapterRegistered(4)) {
      Hive.registerAdapter(ActivityLevelAdapter());
    }
    await Hive.openBox<UserProfile>('userProfile', bytes: Uint8List(0));
    await Hive.openBox('weight_history', bytes: Uint8List(0));

    final profiles = UserProfileService();
    await profiles.initialize();

    await profiles.createProfile(
      age: 30,
      weight: 72,
      height: 175,
      gender: Gender.female,
      activityLevel: ActivityLevel.lightlyActive,
      goalWeight: 65,
    );
    // An earlier weigh-in so the chart has a real line to draw.
    await WeightHistoryService().record(
      74,
      at: DateTime.now().subtract(const Duration(days: 10)),
    );
    await profiles.updateProfile(weight: 71);
  });

  tearDownAll(() async {
    await Hive.close();
  });

  testWidgets('shows the card, the chart and the weigh-ins', (tester) async {
    await pumpLocalized(tester, const WeightHistoryScreen());

    expect(tester.takeException(), isNull);
    // App bar title and the chart's section header.
    expect(find.text('Weight history'), findsNWidgets(2));
    expect(find.byType(WeightCard), findsOneWidget);
    expect(find.byType(WeightChart), findsOneWidget);
    final chart = tester.widget<LineChart>(find.byType(LineChart));
    expect(chart.data.extraLinesData.horizontalLines.single.y, 65);
    expect(chart.data.lineBarsData.single.spots, hasLength(2));
    // The list: today's 71 with its change from the 74 ten days earlier.
    expect(find.text('71 kg'), findsOneWidget);
    expect(find.text('74 kg'), findsOneWidget);
    expect(find.text('−3'), findsOneWidget);
  });
}
