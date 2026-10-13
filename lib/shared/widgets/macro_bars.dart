import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'package:plate_track_ai/core/themes/app_colors.dart';
import 'package:plate_track_ai/core/themes/app_dimens.dart';

/// One macro's progress toward its daily target, in grams.
@immutable
class MacroProgress {
  const MacroProgress({
    required this.macro,
    required this.grams,
    required this.target,
  });

  final Macro macro;
  final double grams;

  /// Daily target in grams. Non-positive means "no target": the bar shows an
  /// empty track rather than a full one.
  final double target;

  double get fraction =>
      target > 0 ? (grams / target).clamp(0.0, 1.0).toDouble() : 0.0;
}

/// The macro strip under the calorie gauge: each macro's gram total over a
/// slim progress pill, separated by hairline rules.
///
/// The gram figure is printed above every bar, which is what lets the bars use
/// the vivid graphic hues — the colour is never the only carrier of the value.
class MacroBars extends StatelessWidget {
  const MacroBars({super.key, required this.macros});

  final List<MacroProgress> macros;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);

    final children = <Widget>[];
    for (var i = 0; i < macros.length; i++) {
      if (i > 0) {
        children.add(
          Container(width: 1, height: 30, color: palette.border),
        );
      }
      children.add(Expanded(child: _MacroBar(progress: macros[i])));
    }

    return Row(crossAxisAlignment: CrossAxisAlignment.center, children: children);
  }
}

class _MacroBar extends StatelessWidget {
  const _MacroBar({required this.progress});

  final MacroProgress progress;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final style = palette.styleOf(progress.macro);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${progress.grams.round()}${'g'.tr()}',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppDimens.radiusPill),
            child: Stack(
              children: [
                Container(
                  height: AppDimens.macroBarHeight,
                  color: palette.track,
                ),
                FractionallySizedBox(
                  widthFactor: progress.fraction,
                  child: Container(
                    height: AppDimens.macroBarHeight,
                    decoration: BoxDecoration(
                      color: style.graphic,
                      borderRadius: BorderRadius.circular(
                        AppDimens.radiusPill,
                      ),
                    ),
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
