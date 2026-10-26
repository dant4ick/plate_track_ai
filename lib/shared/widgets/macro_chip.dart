import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'package:plate_track_ai/core/themes/app_colors.dart';
import 'package:plate_track_ai/core/themes/app_dimens.dart';

/// The neutral pill that labels a macro amount — "P: 32g".
///
/// Macro text uses its original colour, without theme-dependent shades.
class MacroChip extends StatelessWidget {
  const MacroChip({super.key, required this.macro, required this.grams});

  final Macro macro;
  final double grams;

  String get _shortLabelKey => switch (macro) {
    Macro.protein => 'protein_short',
    Macro.carbs => 'carbs_short',
    Macro.fat => 'fat_short',
    Macro.calories => 'kcal',
  };

  @override
  Widget build(BuildContext context) {
    final style = AppPalette.of(context).styleOf(macro);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: style.fill,
        borderRadius: BorderRadius.circular(AppDimens.radiusPill),
      ),
      child: Text(
        '${_shortLabelKey.tr()}: ${grams.round()}${'g'.tr()}',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: style.ink,
          fontWeight: FontWeight.w600,
          height: 1.1,
        ),
      ),
    );
  }
}
