import 'dart:math' as math;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'package:plate_track_ai/core/themes/app_colors.dart';
import 'package:plate_track_ai/core/themes/app_dimens.dart';

/// The half-donut at the top of the daily summary: a 180° track, filled
/// clockwise in proportion to calories eaten, with the remaining allowance
/// printed in the well.
///
/// Going over the target does not overflow the arc — it fills completely and
/// keeps the theme primary. The caption flips from "left" to "over",
/// so the number under the arc is always a positive quantity with its own unit.
class CalorieGauge extends StatelessWidget {
  const CalorieGauge({super.key, required this.consumed, required this.target});

  /// Calories eaten today.
  final double consumed;

  /// Daily allowance. A non-positive target means "no goal set": the arc renders
  /// as an empty track rather than dividing by zero.
  final double target;

  bool get _hasTarget => target > 0;

  double get _progress =>
      _hasTarget ? (consumed / target).clamp(0.0, 1.0).toDouble() : 0.0;

  /// Positive when under the target, negative when over it.
  double get _remaining => target - consumed;

  bool get _isOver => _hasTarget && _remaining < 0;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final theme = Theme.of(context);
    final fill = palette.calories;

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        const stroke = AppDimens.gaugeStroke;
        final radius = math.max((width - stroke) / 2, 0.0);
        // The flat side of the arc is the bottom edge, so the box only needs
        // half a circle plus the stroke that straddles the centre line.
        final height = radius + stroke;

        return SizedBox(
          height: height,
          width: width,
          child: Stack(
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: _GaugePainter(
                    progress: _progress,
                    stroke: stroke,
                    fill: fill,
                    track: palette.track,
                  ),
                ),
              ),
              Positioned.fill(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      _hasTarget
                          ? _remaining.abs().round().toString()
                          : consumed.round().toString(),
                      style: theme.textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        letterSpacing: -1,
                        height: 1.0,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _hasTarget
                          ? (_isOver
                                ? 'calories_over'.tr()
                                : 'calories_left'.tr())
                          : 'calories_consumed'.tr(),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: palette.textSecondary,
                      ),
                    ),
                    SizedBox(height: stroke * 0.5),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _GaugePainter extends CustomPainter {
  const _GaugePainter({
    required this.progress,
    required this.stroke,
    required this.fill,
    required this.track,
  });

  final double progress;
  final double stroke;
  final Color fill;
  final Color track;

  @override
  void paint(Canvas canvas, Size size) {
    final radius = math.max((size.width - stroke) / 2, 0.0);
    if (radius <= 0) return;

    // Centre sits on the bottom edge of the box, half a stroke up, so the arc's
    // outer edge is flush with the box on all three sides.
    final center = Offset(size.width / 2, size.height - stroke / 2);
    final rect = Rect.fromCircle(center: center, radius: radius);

    final base = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;

    // 180° starting at due west, sweeping clockwise over the top.
    canvas.drawArc(rect, math.pi, math.pi, false, base..color = track);

    if (progress > 0) {
      canvas.drawArc(
        rect,
        math.pi,
        math.pi * progress,
        false,
        base..color = fill,
      );
    }
  }

  @override
  bool shouldRepaint(_GaugePainter old) =>
      old.progress != progress ||
      old.fill != fill ||
      old.track != track ||
      old.stroke != stroke;
}
