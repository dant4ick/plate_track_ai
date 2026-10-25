import 'dart:math' as math;

import 'package:easy_localization/easy_localization.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import 'package:plate_track_ai/core/services/local_data_observer.dart';
import 'package:plate_track_ai/core/services/user_profile_service.dart';
import 'package:plate_track_ai/core/services/weight_history_service.dart';
import 'package:plate_track_ai/core/themes/app_colors.dart';
import 'package:plate_track_ai/core/themes/app_dimens.dart';
import 'package:plate_track_ai/features/dashboard/edit_weight.dart';
import 'package:plate_track_ai/shared/models/user_profile.dart';
import 'package:plate_track_ai/shared/models/weight_entry.dart';
import 'package:plate_track_ai/shared/widgets/soft_card.dart';
import 'package:plate_track_ai/shared/widgets/standard_app_bar.dart';
import 'package:plate_track_ai/shared/widgets/weight_card.dart';

/// Where the weight card leads: the same card, the weigh-ins drawn as a line
/// against the goal, and the list of entries behind the line.
class WeightHistoryScreen extends StatefulWidget {
  const WeightHistoryScreen({super.key});

  @override
  State<WeightHistoryScreen> createState() => _WeightHistoryScreenState();
}

class _WeightHistoryScreenState extends State<WeightHistoryScreen> {
  final UserProfileService _profileService = UserProfileService();
  final WeightHistoryService _historyService = WeightHistoryService();

  UserProfile? _profile;
  List<WeightEntry> _series = const [];
  bool _isLoading = true;

  late final LocalDataObserver _dataObserver;

  @override
  void initState() {
    super.initState();
    _dataObserver = LocalDataObserver(
      onChanged: _load,
      changes: [_profileService.onDataChanged],
    );
    _load();
  }

  @override
  void dispose() {
    _dataObserver.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    await _profileService.initialize();
    final profile = _profileService.currentProfile;
    final recorded = await _historyService.entries();

    if (!mounted) return;
    setState(() {
      _profile = profile;
      _series = profile == null
          ? const []
          : WeightHistory.seriesFor(profile, recorded);
      _isLoading = false;
    });
  }

  Future<void> _edit() async {
    final saved = await editWeightAndGoal(context, _profileService);
    if (saved) await _load();
  }

  @override
  Widget build(BuildContext context) {
    final profile = _profile;

    return Scaffold(
      appBar: StandardAppBar(titleText: 'weight_history'.tr(), showLogo: false),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : profile == null
          ? Center(child: Text('no_profile_found'.tr()))
          : SingleChildScrollView(
              padding: AppDimens.pagePadding(context),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SectionHeader('your_weight'.tr()),
                  WeightCard(
                    current: profile.weight,
                    start: profile.effectiveStartWeight,
                    goal: profile.goalWeight,
                    progress: profile.weightProgress,
                    onTap: _edit,
                  ),
                  const SizedBox(height: AppDimens.sectionGap),
                  SectionHeader('weight_history'.tr()),
                  WeightChart(series: _series, goal: profile.goalWeight),
                  const SizedBox(height: AppDimens.sectionGap),
                  _EntryList(series: _series),
                ],
              ),
            ),
    );
  }
}

/// The weigh-ins as a line over calendar time, with the goal as a dashed rule.
class WeightChart extends StatelessWidget {
  const WeightChart({
    super.key,
    required this.series,
    this.goal,
    this.height = 220,
  });

  /// Oldest first.
  final List<WeightEntry> series;
  final double? goal;
  final double height;

  /// Days from the first entry — the x axis is real time, so a gap of a month
  /// reads as a gap and not as one more tick.
  static double _x(WeightEntry entry, WeightEntry first) =>
      entry.date.difference(first.date).inDays.toDouble();

  @override
  Widget build(BuildContext context) {
    if (series.isEmpty) return const SizedBox.shrink();

    final palette = AppPalette.of(context);
    final theme = Theme.of(context);
    final first = series.first;

    final spots = [
      for (final entry in series) FlSpot(_x(entry, first), entry.kg),
    ];

    // A single weigh-in still needs a non-zero range to be drawn.
    final maxX = math.max(spots.last.x, 1.0);

    final values = [...series.map((e) => e.kg), ?goal];
    final lo = values.reduce(math.min);
    final hi = values.reduce(math.max);
    // A little headroom either side so the extremes do not sit on the frame.
    final minY = (lo - 2).floorToDouble();
    final maxY = (hi + 2).ceilToDouble();

    final labelStyle = theme.textTheme.bodySmall?.copyWith(
      color: palette.textSecondary,
    );
    final dateFormat = DateFormat('d MMM', context.locale.toString());

    return SoftCard(
      child: SizedBox(
        height: height,
        child: LineChart(
          LineChartData(
            minX: 0,
            maxX: maxX,
            minY: minY,
            maxY: maxY,
            lineBarsData: [
              LineChartBarData(
                spots: spots,
                isCurved: spots.length > 2,
                curveSmoothness: 0.2,
                preventCurveOverShooting: true,
                color: theme.colorScheme.primary,
                barWidth: 3,
                isStrokeCapRound: true,
                dotData: FlDotData(
                  show: true,
                  getDotPainter: (spot, percent, bar, index) =>
                      FlDotCirclePainter(
                        radius: 4,
                        color: theme.colorScheme.primary,
                        strokeWidth: 2,
                        strokeColor:
                            theme.cardTheme.color ?? theme.colorScheme.surface,
                      ),
                ),
                belowBarData: BarAreaData(
                  show: true,
                  color: theme.colorScheme.primary.withValues(alpha: 0.12),
                ),
              ),
            ],
            extraLinesData: goal == null
                ? null
                : ExtraLinesData(
                    horizontalLines: [
                      HorizontalLine(
                        y: goal!,
                        color: palette.textSecondary,
                        strokeWidth: 2,
                        dashArray: [6, 4],
                        label: HorizontalLineLabel(
                          show: true,
                          alignment: Alignment.topRight,
                          style: labelStyle?.copyWith(
                            color: theme.colorScheme.onSurface,
                            fontWeight: FontWeight.w600,
                          ),
                          labelResolver: (_) =>
                              '${'goal_lower'.tr()} ${WeightCard.format(goal!)}',
                        ),
                      ),
                    ],
                  ),
            titlesData: FlTitlesData(
              show: true,
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 28,
                  // Only the two ends are labelled: intermediate dates crowd a
                  // phone-width axis, and the tooltip names any point tapped.
                  getTitlesWidget: (value, meta) {
                    final isEnd = value == 0 || value == maxX;
                    if (!isEnd) return const SizedBox.shrink();
                    final entry = value == 0 ? series.first : series.last;
                    return SideTitleWidget(
                      meta: meta,
                      child: Text(
                        dateFormat.format(entry.date),
                        style: labelStyle,
                      ),
                    );
                  },
                ),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 36,
                  getTitlesWidget: (value, meta) {
                    if (value == minY || value == maxY) {
                      return const SizedBox.shrink();
                    }
                    return SideTitleWidget(
                      meta: meta,
                      child: Text(value.toInt().toString(), style: labelStyle),
                    );
                  },
                ),
              ),
              topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
            ),
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              getDrawingHorizontalLine: (value) =>
                  FlLine(color: palette.chartGrid, strokeWidth: 1),
            ),
            borderData: FlBorderData(show: false),
            lineTouchData: LineTouchData(
              touchTooltipData: LineTouchTooltipData(
                getTooltipColor: (_) => theme.colorScheme.inverseSurface,
                getTooltipItems: (touched) => [
                  for (final spot in touched)
                    LineTooltipItem(
                      '${WeightCard.format(spot.y)} ${'kg'.tr()}\n'
                      '${dateFormat.format(series[spot.spotIndex].date)}',
                      theme.textTheme.bodySmall!.copyWith(
                        color: theme.colorScheme.onInverseSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Every weigh-in, newest first, with the change from the one before it.
class _EntryList extends StatelessWidget {
  const _EntryList({required this.series});

  final List<WeightEntry> series;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final theme = Theme.of(context);
    final dateFormat = DateFormat('EEE, d MMM yyyy', context.locale.toString());

    return SoftCard(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        children: [
          for (var i = series.length - 1; i >= 0; i--) ...[
            if (i < series.length - 1)
              Divider(
                height: 1,
                color: palette.border,
                indent: 18,
                endIndent: 18,
              ),
            _EntryRow(
              entry: series[i],
              previous: i > 0 ? series[i - 1] : null,
              dateFormat: dateFormat,
              palette: palette,
              theme: theme,
            ),
          ],
        ],
      ),
    );
  }
}

class _EntryRow extends StatelessWidget {
  const _EntryRow({
    required this.entry,
    required this.previous,
    required this.dateFormat,
    required this.palette,
    required this.theme,
  });

  final WeightEntry entry;
  final WeightEntry? previous;
  final DateFormat dateFormat;
  final AppPalette palette;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final prev = previous;
    final delta = prev == null ? null : entry.kg - prev.kg;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              dateFormat.format(entry.date),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: palette.textSecondary,
              ),
            ),
          ),
          if (delta != null && delta != 0) ...[
            Text(
              '${delta > 0 ? '+' : '−'}${WeightCard.format(delta.abs())}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: palette.textSecondary,
              ),
            ),
            const SizedBox(width: 12),
          ],
          Text(
            '${WeightCard.format(entry.kg)} ${'kg'.tr()}',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
