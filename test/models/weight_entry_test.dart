import 'package:flutter_test/flutter_test.dart';
import 'package:plate_track_ai/shared/models/weight_entry.dart';

import '../test_utils.dart';

void main() {
  final created = DateTime(2026, 8, 1, 14, 30);
  final now = DateTime(2026, 8, 25, 9);

  group('WeightEntry.dayOf', () {
    test('drops the time of day', () {
      expect(WeightEntry.dayOf(created), DateTime(2026, 8, 1));
    });
  });

  group('WeightHistory.seriesFor', () {
    test('with no recorded entries, draws start and current weight', () {
      final profile = TestDataFactory.createUserProfile(
        weight: 67,
        startWeight: 70,
        createdAt: created,
      );

      final series = WeightHistory.seriesFor(profile, const [], now: now);

      expect(series, [
        WeightEntry(date: DateTime(2026, 8, 1), kg: 70),
        WeightEntry(date: DateTime(2026, 8, 25), kg: 67),
      ]);
    });

    test('a legacy profile with no start weight gets a single point', () {
      final profile = TestDataFactory.createUserProfile(
        weight: 70,
        createdAt: created,
      );

      final series = WeightHistory.seriesFor(profile, const [], now: now);

      // Nothing is known about the past, so the only honest point is today's
      // weight — a flat line back to the creation day would invent a history
      // that was never recorded.
      expect(series, [WeightEntry(date: DateTime(2026, 8, 25), kg: 70)]);
    });

    test('returns recorded entries sorted oldest first', () {
      final profile = TestDataFactory.createUserProfile(
        weight: 68,
        startWeight: 70,
        createdAt: created,
      );
      final recorded = [
        WeightEntry(date: DateTime(2026, 8, 20), kg: 68),
        WeightEntry(date: DateTime(2026, 8, 1), kg: 70),
        WeightEntry(date: DateTime(2026, 8, 10), kg: 69),
      ];

      final series = WeightHistory.seriesFor(profile, recorded, now: now);

      expect(series.map((e) => e.kg), [70, 69, 68]);
    });

    test('appends today when the profile weight is newer than the history', () {
      final profile = TestDataFactory.createUserProfile(
        weight: 66,
        startWeight: 70,
        createdAt: created,
      );
      final recorded = [WeightEntry(date: DateTime(2026, 8, 1), kg: 70)];

      final series = WeightHistory.seriesFor(profile, recorded, now: now);

      expect(series.last, WeightEntry(date: DateTime(2026, 8, 25), kg: 66));
    });

    test('the profile weight wins over a stale entry for today', () {
      final profile = TestDataFactory.createUserProfile(
        weight: 66,
        startWeight: 70,
        createdAt: created,
      );
      final recorded = [
        WeightEntry(date: DateTime(2026, 8, 1), kg: 70),
        WeightEntry(date: DateTime(2026, 8, 25), kg: 67),
      ];

      final series = WeightHistory.seriesFor(profile, recorded, now: now);

      expect(series.length, 2);
      expect(series.last, WeightEntry(date: DateTime(2026, 8, 25), kg: 66));
    });

    test('prepends the start weight when the history begins later', () {
      final profile = TestDataFactory.createUserProfile(
        weight: 68,
        startWeight: 70,
        createdAt: created,
      );
      final recorded = [WeightEntry(date: DateTime(2026, 8, 20), kg: 68)];

      final series = WeightHistory.seriesFor(profile, recorded, now: now);

      expect(series.first, WeightEntry(date: DateTime(2026, 8, 1), kg: 70));
      expect(series.length, 2);
    });
  });
}
