import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:hive_test/hive_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:plate_track_ai/core/services/user_profile_service.dart';
import 'package:plate_track_ai/core/services/weight_history_service.dart';
import 'package:plate_track_ai/shared/models/user_profile.dart';
import 'package:plate_track_ai/shared/models/user_profile_adapters.dart';
import 'package:plate_track_ai/shared/models/weight_entry.dart';

void main() {
  group('UserProfileService records weigh-ins', () {
    late UserProfileService profiles;
    late WeightHistoryService history;

    setUpAll(() async {
      await setUpTestHive();
      if (!Hive.isAdapterRegistered(2)) {
        Hive.registerAdapter(UserProfileAdapter());
      }
      if (!Hive.isAdapterRegistered(3)) {
        Hive.registerAdapter(GenderAdapter());
      }
      if (!Hive.isAdapterRegistered(4)) {
        Hive.registerAdapter(ActivityLevelAdapter());
      }
    });

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      profiles = UserProfileService();
      history = WeightHistoryService();
      await profiles.initialize();
      await history.initialize();
      await history.clearAllData();
    });

    tearDown(() async {
      if (profiles.hasUserProfile) await profiles.deleteProfile();
    });

    tearDownAll(() async {
      await Hive.close();
    });

    Future<UserProfile> create({double weight = 70}) => profiles.createProfile(
      age: 30,
      weight: weight,
      height: 175,
      gender: Gender.male,
      activityLevel: ActivityLevel.moderatelyActive,
    );

    test('creating a profile records the opening weight on its creation day', () async {
      final profile = await create(weight: 72);

      final entries = await history.entries();

      expect(entries, [
        WeightEntry(date: WeightEntry.dayOf(profile.createdAt), kg: 72),
      ]);
    });

    test('updating the weight records a weigh-in for today', () async {
      await create(weight: 72);

      await profiles.updateProfile(weight: 71.5);

      final entries = await history.entries();
      // Both happen today, so the later weight replaces the opening one.
      expect(entries.single.kg, 71.5);
      expect(entries.single.date, WeightEntry.dayOf(DateTime.now()));
    });

    test('an update that leaves the weight alone records nothing', () async {
      await create(weight: 72);

      await profiles.updateProfile(goalWeight: 65);

      final entries = await history.entries();
      expect(entries.single.kg, 72);
    });
  });
}
