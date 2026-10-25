import 'package:flutter/material.dart';

import 'package:plate_track_ai/core/themes/app_colors.dart';
import 'package:plate_track_ai/core/themes/app_dimens.dart';

/// The card surface of the design: a flat panel, generous rounding, and one
/// wide soft shadow instead of a Material elevation ramp.
///
/// [Card] is still fine for incidental surfaces — its theme is tuned to match.
/// Reach for [SoftCard] when the content needs custom padding or has to sit
/// flush against the gauge/ring painters, which assume no Material inset.
class SoftCard extends StatelessWidget {
  const SoftCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppDimens.cardPadding),
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final radius = AppDimens.cardBorderRadius;

    return DecoratedBox(
      decoration: BoxDecoration(
        color:
            Theme.of(context).cardTheme.color ??
            Theme.of(context).colorScheme.surface,
        borderRadius: radius,
        boxShadow: AppDimens.cardShadow(palette),
      ),
      // The ink splash has to be clipped to the card's own radius, so the
      // Material sits inside the DecoratedBox rather than wrapping it.
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

/// The label that sits above a card — "Your weight", "Your calories".
class SectionHeader extends StatelessWidget {
  const SectionHeader(this.label, {super.key, this.trailing});

  final String label;

  /// Optional action rendered at the trailing edge of the header row.
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final text = Text(
      label,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w600,
        letterSpacing: -0.2,
      ),
    );

    return Padding(
      padding: const EdgeInsets.only(
        left: 4,
        right: 4,
        bottom: AppDimens.headerGap,
      ),
      child: trailing == null
          ? Align(alignment: Alignment.centerLeft, child: text)
          : Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [text, trailing!],
            ),
    );
  }
}
