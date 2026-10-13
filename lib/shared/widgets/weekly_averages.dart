import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'package:plate_track_ai/core/themes/app_colors.dart';
import 'package:plate_track_ai/core/themes/app_dimens.dart';
import 'package:plate_track_ai/shared/models/week_summary.dart';
import 'package:plate_track_ai/shared/widgets/soft_card.dart';

/// Average daily intake over the days of the week that were actually logged.
///
/// A 2×2 grid rather than a single row: four figures with units do not fit
/// legibly across a phone, and wrapping them keeps each one readable.
class WeeklyAverages extends StatelessWidget {
  const WeeklyAverages({super.key, required this.summary});

  final WeekSummary summary;

  @override
  Widget build(BuildContext context) {
    if (!summary.hasData) {
      return const _NoWeekData();
    }

    final perDay = '${'g'.tr()}/${'day'.tr()}';

    return SoftCard(
      child: Column(
        children: [
          Row(
            children: [
              _Cell(
                label: 'calories'.tr(),
                value: summary.averageCalories,
                unit: '${'kcal'.tr()}/${'day'.tr()}',
                icon: Icons.local_fire_department,
                macro: Macro.calories,
              ),
              _Cell(
                label: 'protein'.tr(),
                value: summary.averageProtein,
                unit: perDay,
                icon: Icons.fitness_center,
                macro: Macro.protein,
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              _Cell(
                label: 'carbs'.tr(),
                value: summary.averageCarbs,
                unit: perDay,
                icon: Icons.grain,
                macro: Macro.carbs,
              ),
              _Cell(
                label: 'fat'.tr(),
                value: summary.averageFat,
                unit: perDay,
                icon: Icons.opacity,
                macro: Macro.fat,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Cell extends StatelessWidget {
  const _Cell({
    required this.label,
    required this.value,
    required this.unit,
    required this.icon,
    required this.macro,
  });

  final String label;
  final double value;
  final String unit;
  final IconData icon;
  final Macro macro;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final style = palette.styleOf(macro);
    final theme = Theme.of(context);

    return Expanded(
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: style.fill,
              borderRadius: BorderRadius.circular(AppDimens.radiusControl),
            ),
            // Ink, not the graphic colour: the icon sits on the macro's own pale
            // fill, which the vivid hues do not clear 3:1 against.
            child: Icon(icon, color: style.ink, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  value.round().toString(),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    height: 1.1,
                  ),
                  maxLines: 1,
                ),
                Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: palette.textTertiary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  unit,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: palette.textTertiary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NoWeekData extends StatelessWidget {
  const _NoWeekData();

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);

    return SoftCard(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
      child: Column(
        children: [
          Icon(Icons.insights, size: 30, color: palette.placeholderIcon),
          const SizedBox(height: 12),
          Text(
            'no_nutrition_data_today'.tr(),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: palette.textTertiary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
