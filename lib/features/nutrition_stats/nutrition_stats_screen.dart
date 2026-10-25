import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'package:plate_track_ai/core/services/local_data_observer.dart';
import 'package:plate_track_ai/core/services/food_storage_service.dart';
import 'package:plate_track_ai/core/services/user_profile_service.dart';
import 'package:plate_track_ai/core/themes/app_colors.dart';
import 'package:plate_track_ai/core/themes/app_dimens.dart';
import 'package:plate_track_ai/shared/models/food_item.dart';
import 'package:plate_track_ai/shared/widgets/soft_card.dart';
import 'package:plate_track_ai/shared/widgets/standard_app_bar.dart';

import 'nutrition_summary.dart';
import 'nutrition_macro_breakdown.dart';
import 'nutrition_trend_chart.dart';

class NutritionStatsScreen extends StatefulWidget {
  const NutritionStatsScreen({super.key});

  @override
  State<NutritionStatsScreen> createState() => _NutritionStatsScreenState();
}

class _NutritionStatsScreenState extends State<NutritionStatsScreen> {
  final _storage = FoodStorageService();
  final _profiles = UserProfileService();
  List<FoodItem> _items = const [];
  NutritionPeriod _period = NutritionPeriod.day;
  int _selectedIndex = 7;
  bool _isLoading = true;
  bool _loadFailed = false;
  Map<String, double>? _targets;

  late final LocalDataObserver _dataObserver;

  @override
  void initState() {
    super.initState();
    _dataObserver = LocalDataObserver(
      onChanged: _load,
      changes: [_storage.onDataChanged, _profiles.onDataChanged],
    );
    _load();
  }

  @override
  void dispose() {
    _dataObserver.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      await _profiles.initialize();
      final items = await _storage.getAllFoodItems();
      if (!mounted) return;
      setState(() {
        _items = items;
        _targets = _profiles.getNutritionTargets();
        _isLoading = false;
        _loadFailed = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _loadFailed = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final summary = NutritionSummary.fromItems(
      _items,
      period: _period,
      now: DateTime.now(),
    );
    return Scaffold(
      appBar: StandardAppBar(titleText: 'your_calories'.tr(), showLogo: false),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: AppDimens.pagePadding(context),
              children: [
                _buildPeriodSelector(),
                const SizedBox(height: 20),
                if (_loadFailed)
                  SoftCard(child: Text('stats_load_error'.tr()))
                else
                  _buildOverview(summary),
              ],
            ),
    );
  }

  Widget _buildPeriodSelector() {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final period in NutritionPeriod.values)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(switch (period) {
                  NutritionPeriod.day => 'stats_day'.tr(),
                  NutritionPeriod.week => 'stats_week'.tr(),
                  NutritionPeriod.month => 'stats_month'.tr(),
                }, maxLines: 1),
                selected: _period == period,
                showCheckmark: false,
                selectedColor: scheme.primary,
                labelStyle: theme.textTheme.labelLarge?.copyWith(
                  color: _period == period
                      ? scheme.onPrimary
                      : scheme.onSurface,
                ),
                onSelected: (_) => setState(() {
                  _period = period;
                  _selectedIndex = 7;
                }),
              ),
            ),
        ],
      ),
    );
  }

  String _bucketLabel(NutritionBucket bucket) {
    final locale = context.locale.toString();
    if (_period == NutritionPeriod.month) {
      return DateFormat('LLLL y', locale).format(bucket.start);
    }
    final format = DateFormat('d MMM y', locale);
    if (_period == NutritionPeriod.day) {
      return format.format(bucket.start);
    }
    final lastDay = DateTime(
      bucket.end.year,
      bucket.end.month,
      bucket.end.day - 1,
    );
    return '${format.format(bucket.start)} — ${format.format(lastDay)}';
  }

  Widget _buildOverview(NutritionSummary summary) {
    final theme = Theme.of(context);
    final palette = AppPalette.of(context);
    final bucket = summary.buckets[_selectedIndex];
    final dailyTarget = _targets?['calories'];
    final format = NumberFormat.decimalPattern(context.locale.toString());
    final unit = _period == NutritionPeriod.day
        ? 'kcal'.tr()
        : '${'kcal'.tr()}/${'day'.tr()}';
    return SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _bucketLabel(bucket),
            key: const ValueKey('stats-selected-date'),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: palette.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '${format.format(bucket.averageCalories.round())} $unit',
            key: const ValueKey('stats-total-calories'),
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: palette.caloriesInk,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            dailyTarget != null && dailyTarget > 0
                ? '${'goal'.tr()}: ${format.format(dailyTarget.round())} ${'kcal'.tr()}/${'day'.tr()}'
                : 'no_goal_set'.tr(),
            key: const ValueKey('stats-calorie-goal'),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: palette.textSecondary,
            ),
          ),
          const SizedBox(height: 32),
          NutritionTrendChart(
            key: ValueKey(_period),
            summary: summary,
            dailyTarget: dailyTarget,
            selectedIndex: _selectedIndex,
            onSelected: (index) => setState(() => _selectedIndex = index),
          ),
          if (!summary.hasData) ...[
            const SizedBox(height: 24),
            Text(
              'no_nutrition_data_period'.tr(),
              style: theme.textTheme.bodySmall?.copyWith(
                color: palette.textSecondary,
              ),
            ),
          ],
          const SizedBox(height: 24),
          Divider(color: palette.border, height: 1),
          const SizedBox(height: 24),
          NutritionMacroBreakdown(
            bucket: bucket,
            period: _period,
            targets: _targets,
          ),
        ],
      ),
    );
  }
}
