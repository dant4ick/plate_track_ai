import 'package:equatable/equatable.dart';

import 'package:plate_track_ai/shared/models/user_profile.dart';

/// One weigh-in: a calendar day and the kilograms recorded for it.
///
/// The history keeps one value per day — weighing twice in a day replaces the
/// morning's figure rather than drawing two points a few hours apart.
class WeightEntry extends Equatable {
  WeightEntry({required DateTime date, required this.kg}) : date = dayOf(date);

  /// Midnight at the start of the day the weight was recorded.
  final DateTime date;

  final double kg;

  /// Strips the time of day so two timestamps on the same day compare equal.
  static DateTime dayOf(DateTime at) => DateTime(at.year, at.month, at.day);

  @override
  List<Object?> get props => [date, kg];

  @override
  String toString() => 'WeightEntry(${date.toIso8601String()}, $kg kg)';
}

/// Builds the series the weight chart draws.
class WeightHistory {
  WeightHistory._();

  /// Merges what was recorded with what the profile knows.
  ///
  /// Profiles created before the history existed have no entries at all, and a
  /// profile edited through a path that bypassed the history could hold a newer
  /// weight than the last entry. Both are covered here rather than by a data
  /// migration: the profile's start weight anchors the beginning of the series
  /// and its current weight always closes it.
  static List<WeightEntry> seriesFor(
    UserProfile profile,
    List<WeightEntry> recorded, {
    DateTime? now,
  }) {
    final byDay = <DateTime, double>{
      for (final entry in recorded) entry.date: entry.kg,
    };

    final start = profile.startWeight;
    final createdDay = WeightEntry.dayOf(profile.createdAt);
    if (start != null) {
      final earliest = byDay.keys.isEmpty
          ? null
          : byDay.keys.reduce((a, b) => a.isBefore(b) ? a : b);
      if (earliest == null || createdDay.isBefore(earliest)) {
        byDay[createdDay] = start;
      }
    }

    final today = WeightEntry.dayOf(now ?? DateTime.now());
    final latestDay = byDay.keys.isEmpty
        ? null
        : byDay.keys.reduce((a, b) => a.isAfter(b) ? a : b);
    // The profile is the source of truth for the present. It closes the series
    // whenever the history's last word differs from it — including an entry
    // written earlier today that a later edit has since superseded.
    if (latestDay == null || byDay[latestDay] != profile.weight) {
      final closingDay = latestDay != null && latestDay.isAfter(today)
          ? latestDay
          : today;
      byDay[closingDay] = profile.weight;
    }

    final days = byDay.keys.toList()..sort();
    return [for (final day in days) WeightEntry(date: day, kg: byDay[day]!)];
  }
}
