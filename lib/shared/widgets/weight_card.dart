import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'package:plate_track_ai/core/themes/app_colors.dart';
import 'package:plate_track_ai/core/themes/app_dimens.dart';
import 'package:plate_track_ai/shared/widgets/progress_ring.dart';
import 'package:plate_track_ai/shared/widgets/soft_card.dart';

/// The weight panel: where the user started, where they are, where they are
/// going, and how far along that is.
///
/// The card has two states. With a goal set it shows the start → current → goal
/// triplet and a progress ring. Without one it shows the current weight alone
/// plus an invitation to set a target, because a ring with nothing to measure
/// would be a permanently empty circle.
class WeightCard extends StatelessWidget {
  const WeightCard({
    super.key,
    required this.current,
    this.start,
    this.goal,
    this.progress,
    this.onTap,
  });

  /// Current weight in kg.
  final double current;

  /// Baseline the goal is measured from, in kg.
  final double? start;

  /// Target weight in kg, or null when no goal is set.
  final double? goal;

  /// Travelled fraction from [start] to [goal], 0..1, or null if unmeasurable.
  final double? progress;

  /// Fired when the card body is tapped.
  final VoidCallback? onTap;

  /// Trims a trailing `.0` so 67.0 kg reads as "67" but 67.5 keeps its half.
  static String format(double kg) {
    final rounded = (kg * 10).round() / 10;
    return rounded % 1 == 0
        ? rounded.toStringAsFixed(0)
        : rounded.toStringAsFixed(1);
  }

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      onTap: onTap,
      child: Row(
        children: [
          Expanded(
            child: goal == null
                ? _NoGoal(current: current)
                : _GoalTriplet(current: current, start: start, goal: goal!),
          ),
          if (progress != null) ...[
            const SizedBox(width: 12),
            ProgressRing(
              progress: progress!,
              child: Text(
                '${(progress! * 100).round()}%',
                style: Theme.of(
                  context,
                ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _GoalTriplet extends StatelessWidget {
  const _GoalTriplet({
    required this.current,
    required this.start,
    required this.goal,
  });

  final double current;
  final double? start;
  final double goal;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final theme = Theme.of(context);

    final flankStyle = theme.textTheme.headlineSmall?.copyWith(
      color: palette.textTertiary,
      fontWeight: FontWeight.w400,
      height: 1.0,
    );
    final footStyle = theme.textTheme.bodySmall?.copyWith(
      color: palette.textTertiary,
    );

    // A Table, not a Row of Columns: the three figures have to sit on one shared
    // text baseline while their captions line up on a second row underneath.
    // Nesting a Column per figure aligns the column *boxes* instead, which lets
    // the two small numbers float above the large one.
    return Table(
      defaultColumnWidth: const IntrinsicColumnWidth(),
      defaultVerticalAlignment: TableCellVerticalAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        TableRow(
          children: [
            _cell(Text(WeightCard.format(start ?? current), style: flankStyle)),
            _cell(
              Text(
                WeightCard.format(current),
                style: theme.textTheme.displayMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: -1.5,
                  height: 1.0,
                ),
              ),
            ),
            _cell(Text(WeightCard.format(goal), style: flankStyle)),
          ],
        ),
        TableRow(
          children: [
            _cell(Text('start'.tr(), style: footStyle), top: 8),
            // The rule is not text and so cannot be baseline-aligned; it is
            // centred in its cell instead.
            TableCell(
              verticalAlignment: TableCellVerticalAlignment.middle,
              child: Padding(
                padding: const EdgeInsets.only(top: 10, left: 6, right: 6),
                child: Center(
                  child: Container(
                    height: 5,
                    decoration: BoxDecoration(
                      color: AppColors.secondShade,
                      borderRadius: BorderRadius.circular(AppDimens.radiusPill),
                    ),
                  ),
                ),
              ),
            ),
            _cell(Text('goal_lower'.tr(), style: footStyle), top: 8),
          ],
        ),
      ],
    );
  }

  /// Centres a cell's content and keeps the columns from touching.
  static Widget _cell(Widget child, {double top = 0}) => Padding(
    padding: EdgeInsets.only(top: top, left: 6, right: 6),
    child: Center(child: child),
  );
}

class _NoGoal extends StatelessWidget {
  const _NoGoal({required this.current});

  final double current;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              WeightCard.format(current),
              style: theme.textTheme.displaySmall?.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: -1.5,
                height: 1.0,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              'kg'.tr(),
              style: theme.textTheme.titleMedium?.copyWith(
                color: palette.textTertiary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          'goal_weight_hint'.tr(),
          style: theme.textTheme.bodySmall?.copyWith(
            color: palette.textTertiary,
          ),
        ),
      ],
    );
  }
}
