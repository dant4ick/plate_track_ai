import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:hive_test/hive_test.dart';
import 'package:plate_track_ai/shared/models/user_profile.dart';
import 'package:plate_track_ai/shared/models/user_profile_adapters.dart';

import '../test_utils.dart';

void main() {
  group('UserProfile weight goal', () {
    test('effectiveStartWeight falls back to current weight', () {
      final profile = TestDataFactory.createUserProfile(weight: 70);
      expect(profile.startWeight, isNull);
      expect(profile.effectiveStartWeight, 70);
    });

    test('weightProgress matches the design mockup figures', () {
      // 70 kg start, 67 now, 50 goal -> 3 of 20 kg travelled -> 15%.
      final profile = TestDataFactory.createUserProfile(
        weight: 67,
        startWeight: 70,
        goalWeight: 50,
      );
      expect(profile.weightProgress, closeTo(0.15, 1e-9));
    });

    test('weightProgress works when the goal is to gain', () {
      final profile = TestDataFactory.createUserProfile(
        weight: 62,
        startWeight: 60,
        goalWeight: 70,
      );
      expect(profile.weightProgress, closeTo(0.2, 1e-9));
    });

    test('weightProgress is null without a goal', () {
      expect(
        TestDataFactory.createUserProfile(weight: 70).weightProgress,
        isNull,
      );
    });

    test('weightProgress is null when the goal equals the start', () {
      final profile = TestDataFactory.createUserProfile(
        weight: 70,
        startWeight: 70,
        goalWeight: 70,
      );
      expect(profile.weightProgress, isNull);
    });

    test('weightProgress clamps past the goal and before the start', () {
      final overshot = TestDataFactory.createUserProfile(
        weight: 45,
        startWeight: 70,
        goalWeight: 50,
      );
      expect(overshot.weightProgress, 1.0);

      final backwards = TestDataFactory.createUserProfile(
        weight: 74,
        startWeight: 70,
        goalWeight: 50,
      );
      expect(backwards.weightProgress, 0.0);
    });
  });

  group('UserProfileAdapter', () {
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

    tearDownAll(() async {
      await tearDownTestHive();
    });

    Future<UserProfile> roundTrip(UserProfile profile) async {
      final box = await Hive.openBox<UserProfile>('round_trip');
      await box.put(profile.id, profile);
      await box.close();

      final reopened = await Hive.openBox<UserProfile>('round_trip');
      final restored = reopened.get(profile.id)!;
      await reopened.deleteFromDisk();
      return restored;
    }

    test('round-trips the goal fields through a real box', () async {
      final profile = TestDataFactory.createUserProfile(
        weight: 67,
        startWeight: 70,
        goalWeight: 50,
        // Hive stores timestamps to the millisecond, so a `DateTime.now()`
        // baseline would fail the whole-object comparison on its microseconds
        // for reasons that have nothing to do with the goal fields.
        createdAt: DateTime.fromMillisecondsSinceEpoch(1750000000000),
      );

      final restored = await roundTrip(profile);

      expect(restored.startWeight, 70);
      expect(restored.goalWeight, 50);
      expect(restored, profile);
    });

    test('round-trips a profile that has no goal', () async {
      final restored = await roundTrip(
        TestDataFactory.createUserProfile(weight: 70),
      );

      expect(restored.startWeight, isNull);
      expect(restored.goalWeight, isNull);
    });

    test('reads a record written before the goal fields existed', () {
      // Replays exactly what the pre-upgrade adapter emitted: a field count of
      // 8 and no entries for 8 or 9. The adapter must land on the "no goal set"
      // state rather than throwing on a missing key.
      final profile = TestDataFactory.createUserProfile(weight: 70);
      final reader = _ScriptedReader(
        fieldCount: 8,
        fields: <int, dynamic>{
          0: profile.id,
          1: profile.age,
          2: profile.weight,
          3: profile.height,
          4: profile.gender,
          5: profile.activityLevel,
          6: profile.createdAt,
          7: profile.updatedAt,
        },
      );

      final restored = UserProfileAdapter().read(reader);

      expect(restored.startWeight, isNull);
      expect(restored.goalWeight, isNull);
      expect(restored.effectiveStartWeight, 70);
      expect(restored.weightProgress, isNull);
    });
  });

  group('copyWith goal handling', () {
    final withGoal = TestDataFactory.createUserProfile(
      weight: 67,
      startWeight: 70,
      goalWeight: 50,
    );

    test('a null goalWeight leaves the existing goal alone', () {
      expect(withGoal.copyWith(weight: 66).goalWeight, 50);
    });

    test('a new goalWeight replaces the old one', () {
      expect(withGoal.copyWith(goalWeight: 55).goalWeight, 55);
    });

    test('clearGoalWeight removes the goal', () {
      final cleared = withGoal.copyWith(clearGoalWeight: true);

      expect(cleared.goalWeight, isNull);
      expect(cleared.weightProgress, isNull);
      // Everything else survives.
      expect(cleared.startWeight, 70);
      expect(cleared.weight, 67);
    });

    test('clearGoalWeight wins over a supplied goalWeight', () {
      expect(
        withGoal.copyWith(goalWeight: 55, clearGoalWeight: true).goalWeight,
        isNull,
      );
    });
  });

  group('toJson / fromJson', () {
    test('carries the goal fields', () {
      final profile = TestDataFactory.createUserProfile(
        weight: 67,
        startWeight: 70,
        goalWeight: 50,
      );

      final restored = UserProfile.fromJson(profile.toJson());

      expect(restored.startWeight, 70);
      expect(restored.goalWeight, 50);
    });

    test('tolerates JSON without the goal fields', () {
      final json = TestDataFactory.createUserProfile(weight: 70).toJson()
        ..remove('startWeight')
        ..remove('goalWeight');

      final restored = UserProfile.fromJson(json);

      expect(restored.startWeight, isNull);
      expect(restored.goalWeight, isNull);
    });
  });
}

/// Feeds [UserProfileAdapter.read] a scripted field stream.
///
/// The adapter only ever calls `readByte()` and `read()`, in that order, so the
/// rest of the very wide [BinaryReader] surface is left to `noSuchMethod`
/// instead of being stubbed out by hand.
class _ScriptedReader implements BinaryReader {
  _ScriptedReader({required this.fieldCount, required this.fields});

  final int fieldCount;
  final Map<int, dynamic> fields;

  bool _countRead = false;
  final List<int> _keyOrder = [];
  int _cursor = 0;

  @override
  int readByte() {
    if (!_countRead) {
      _countRead = true;
      _keyOrder.addAll(fields.keys);
      return fieldCount;
    }
    return _keyOrder[_cursor];
  }

  @override
  dynamic read([int? typeId]) => fields[_keyOrder[_cursor++]];

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnsupportedError(
        'UserProfileAdapter.read should not call '
        '${invocation.memberName}',
      );
}
