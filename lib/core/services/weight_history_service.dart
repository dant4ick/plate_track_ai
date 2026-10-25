import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:plate_track_ai/shared/models/weight_entry.dart';

/// Persists the user's weigh-ins, one per calendar day.
///
/// Entries live in a plain box keyed by ISO date (`2026-08-25`) with the
/// kilograms as the value, so the store needs no type adapter and a day's
/// weight can be overwritten by simply putting it again.
class WeightHistoryService {
  static const String _boxName = 'weight_history';
  static final WeightHistoryService _instance = WeightHistoryService._internal();

  factory WeightHistoryService() => _instance;

  WeightHistoryService._internal();

  Box<dynamic>? _box;

  Future<void> initialize() async {
    if (_box != null && _box!.isOpen) return;
    try {
      _box = await Hive.openBox(_boxName);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('WeightHistoryService: box unreadable, recreating: $e');
      }
      await Hive.deleteBoxFromDisk(_boxName);
      _box = await Hive.openBox(_boxName);
    }
  }

  static String _keyFor(DateTime day) {
    final d = WeightEntry.dayOf(day);
    return '${d.year.toString().padLeft(4, '0')}-'
        '${d.month.toString().padLeft(2, '0')}-'
        '${d.day.toString().padLeft(2, '0')}';
  }

  /// Records [kg] for the day of [at] (today by default), replacing any earlier
  /// value for that day.
  Future<void> record(double kg, {DateTime? at}) async {
    await initialize();
    await _box!.put(_keyFor(at ?? DateTime.now()), kg);
  }

  /// Every recorded weigh-in, oldest first.
  Future<List<WeightEntry>> entries() async {
    await initialize();
    final result = <WeightEntry>[];

    for (final key in _box!.keys) {
      final value = _box!.get(key);
      final date = key is String ? DateTime.tryParse(key) : null;
      if (date == null || value is! num) {
        if (kDebugMode) {
          debugPrint('WeightHistoryService: skipping malformed entry $key');
        }
        continue;
      }
      result.add(WeightEntry(date: date, kg: value.toDouble()));
    }

    result.sort((a, b) => a.date.compareTo(b.date));
    return result;
  }

  Future<void> clearAllData() async {
    await initialize();
    await _box!.clear();
  }
}
