import 'package:flutter/material.dart';

import 'package:plate_track_ai/core/themes/app_colors.dart';
import 'package:plate_track_ai/core/themes/app_dimens.dart';
import 'package:plate_track_ai/features/recommendations/nutrition_advice.dart';
import 'package:plate_track_ai/shared/widgets/soft_card.dart';

/// Renders one [NutritionTip]: a tinted icon tile, the headline, and the reason.
class TipCard extends StatelessWidget {
  const TipCard({super.key, required this.tip});

  final NutritionTip tip;

  /// Resolves a tip's [TipTone] against the active theme.
  ///
  /// Returns the *ink* shade in every case: the icon sits on a pale wash of its
  /// own colour, and the vivid macro hues do not clear 3:1 against that.
  static Color _accent(AppPalette palette, TipTone tone) => switch (tone) {
    TipTone.protein => palette.proteinInk,
    TipTone.carbs => palette.carbsInk,
    TipTone.fat => palette.fatInk,
    TipTone.warning => palette.warningText,
    TipTone.danger => palette.danger,
    TipTone.success => palette.success,
    TipTone.info => palette.info,
    TipTone.accent => palette.accentInk,
  };

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final theme = Theme.of(context);
    final accent = _accent(palette, tip.tone);

    return SoftCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: palette.fillOf(accent),
              borderRadius: BorderRadius.circular(AppDimens.radiusControl),
            ),
            child: Icon(tip.icon, color: accent, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tip.title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  tip.description,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: palette.textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
