import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:plate_track_ai/core/themes/app_colors.dart';
import 'package:plate_track_ai/core/themes/app_dimens.dart';

/// A circular progress ring with a label in the middle.
///
/// The sweep starts at twelve o'clock and runs clockwise. The mockup draws the
/// filled segment starting from six o'clock instead, which reads as roughly
/// two-thirds complete at a glance when the real value is 15%; twelve-o'clock
/// is the convention users already know, so the ring keeps that and matches the
/// mockup on everything else.
class ProgressRing extends StatelessWidget {
  const ProgressRing({
    super.key,
    required this.progress,
    this.diameter = 72,
    this.stroke = AppDimens.ringStroke,
    this.color,
    this.child,
  });

  /// 0..1. Values outside the range are clamped.
  final double progress;

  final double diameter;
  final double stroke;

  /// Defaults to the theme's primary.
  final Color? color;

  /// Rendered centred inside the ring — normally the percentage.
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);

    return SizedBox(
      width: diameter,
      height: diameter,
      child: CustomPaint(
        painter: _RingPainter(
          progress: progress.clamp(0.0, 1.0).toDouble(),
          stroke: stroke,
          fill: color ?? Theme.of(context).colorScheme.primary,
          track: palette.track,
        ),
        child: child == null ? null : Center(child: child),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  const _RingPainter({
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
    final radius = math.max((size.shortestSide - stroke) / 2, 0.0);
    if (radius <= 0) return;

    final rect = Rect.fromCircle(
      center: Offset(size.width / 2, size.height / 2),
      radius: radius,
    );

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(rect.center, radius, paint..color = track);

    if (progress > 0) {
      canvas.drawArc(
        rect,
        -math.pi / 2,
        2 * math.pi * progress,
        false,
        paint..color = fill,
      );
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress ||
      old.fill != fill ||
      old.track != track ||
      old.stroke != stroke;
}
