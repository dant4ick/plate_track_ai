import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:hive_test/hive_test.dart';
import 'package:plate_track_ai/core/services/weight_history_service.dart';
import 'package:plate_track_ai/shared/models/weight_entry.dart';

void main() {
  group('WeightHistoryService', () {
    late WeightHistoryService service;

    setUpAll(() async {
      await setUpTestHive();
    });

    setUp(() async {
      service = WeightHistoryService();
      await service.initialize();
      await service.clearAllData();
    });

    tearDownAll(() async {
      await Hive.close();
    });

    test('is a singleton', () {
      expect(identical(WeightHistoryService(), WeightHistoryService()), isTrue);
    });

    test('starts empty', () async {
      expect(await service.entries(), isEmpty);
    });

    test('records one entry per day, latest value winning', () async {
      await service.record(70, at: DateTime(2026, 8, 20, 8));
      await service.record(69.5, at: DateTime(2026, 8, 20, 21));

      final entries = await service.entries();

      expect(entries, [WeightEntry(date: DateTime(2026, 8, 20), kg: 69.5)]);
    });

    test('returns entries oldest first regardless of insertion order', () async {
      await service.record(68, at: DateTime(2026, 8, 25));
      await service.record(70, at: DateTime(2026, 8, 1));
      await service.record(69, at: DateTime(2026, 8, 12));

      final entries = await service.entries();

      expect(entries.map((e) => e.kg), [70, 69, 68]);
    });

    test('clearAllData empties the history', () async {
      await service.record(70, at: DateTime(2026, 8, 1));
      await service.clearAllData();

      expect(await service.entries(), isEmpty);
    });
  });
}
