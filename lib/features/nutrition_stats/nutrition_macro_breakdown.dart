import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'package:plate_track_ai/core/themes/app_colors.dart';
import 'package:plate_track_ai/core/themes/app_dimens.dart';
import 'package:plate_track_ai/shared/widgets/macro_bars.dart';
import 'nutrition_summary.dart';

/// Daily grams compared with daily profile targets, using the same logged days
/// and selected calendar interval as the calorie bars.
class NutritionMacroBreakdown extends StatelessWidget {
  const NutritionMacroBreakdown({
    super.key,
    required this.bucket,
    required this.period,
    this.targets,
  });

  final NutritionBucket bucket;
  final NutritionPeriod period;
  final Map<String, double>? targets;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = AppPalette.of(context);
    final hasTargets = targets != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'stats_macros'.tr(),
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          (hasTargets
                  ? period == NutritionPeriod.day
                        ? 'stats_macros_daily'
                        : 'stats_macros_average'
                  : period == NutritionPeriod.day
                  ? 'stats_macros_daily_no_goal'
                  : 'stats_macros_average_no_goal')
              .tr(),
          style: theme.textTheme.bodySmall?.copyWith(
            color: palette.textSecondary,
          ),
        ),
        const SizedBox(height: 20),
        for (final macro in [
          (Macro.protein, 'protein', bucket.averageProtein),
          (Macro.fat, 'fat', bucket.averageFat),
          (Macro.carbs, 'carbs', bucket.averageCarbs),
        ])
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: _MacroIntakeRow(
              name: macro.$2,
              progress: MacroProgress(
                macro: macro.$1,
                grams: macro.$3,
                target: targets?[macro.$2] ?? 0,
              ),
            ),
          ),
      ],
    );
  }
}

class _MacroIntakeRow extends StatelessWidget {
  const _MacroIntakeRow({required this.name, required this.progress});

  final String name;
  final MacroProgress progress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = AppPalette.of(context);
    final format = NumberFormat.decimalPattern(context.locale.toString());
    final amount = format.format(progress.grams.round());
    final value = progress.target > 0
        ? '$amount / ${format.format(progress.target.round())} ${'g'.tr()}'
        : '$amount ${'g'.tr()}';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          spacing: 12,
          runSpacing: 4,
          children: [
            Text(name.tr(), style: theme.textTheme.bodyMedium),
            Text(
              value,
              key: ValueKey('stats-macro-$name'),
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        if (progress.target > 0) ...[
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: progress.fraction,
            color: palette.styleOf(progress.macro).graphic,
            backgroundColor: palette.track,
            minHeight: AppDimens.macroBarHeight,
            borderRadius: BorderRadius.circular(AppDimens.radiusPill),
          ),
        ],
      ],
    );
  }
}
