import 'dart:math';

import 'package:flutter/material.dart';
import 'package:plate_track_ai/core/themes/app_colors.dart';

/// Shared camera framing. Only barcode scanning uses the moving scan line.
class CameraScanOverlay extends StatelessWidget {
  const CameraScanOverlay({super.key, this.showScanLine = false});

  final bool showScanLine;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final size = min(constraints.maxWidth, constraints.maxHeight) * 0.65;
          final left = (constraints.maxWidth - size) / 2;
          final top = max(0.0, (constraints.maxHeight - size) / 2 - 40);

          return Stack(
            children: [
              CustomPaint(
                size: Size(constraints.maxWidth, constraints.maxHeight),
                painter: _ScanOverlayPainter(
                  scanRect: Rect.fromLTWH(left, top, size, size),
                ),
              ),
              if (showScanLine)
                Positioned(
                  left: left + 2,
                  top: top + 2,
                  width: size - 4,
                  height: size - 4,
                  child: const ClipRect(child: _AnimatedScanLine()),
                ),
            ],
          );
        },
      ),
    );
  }
}

/// A camera-readable hint, placed above the navigation inset and any controls.
class CameraScanHint extends StatelessWidget {
  const CameraScanHint({
    super.key,
    required this.text,
    this.bottomSpacing = 48,
    this.includeBottomInset = true,
  });

  final String text;
  final double bottomSpacing;
  final bool includeBottomInset;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          16,
          0,
          16,
          bottomSpacing +
              (includeBottomInset ? MediaQuery.paddingOf(context).bottom : 0),
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.cameraPanel,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.cameraForeground,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }
}

class _AnimatedScanLine extends StatefulWidget {
  const _AnimatedScanLine();

  @override
  State<_AnimatedScanLine> createState() => _AnimatedScanLineState();
}

class _AnimatedScanLineState extends State<_AnimatedScanLine>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 2),
  )..repeat(reverse: true);
  late final Animation<double> _animation = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeInOut,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) => CustomPaint(
        painter: _ScanLinePainter(
          progress: _animation.value,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}

class _ScanOverlayPainter extends CustomPainter {
  final Rect scanRect;

  const _ScanOverlayPainter({required this.scanRect});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = AppColors.cameraMask;

    // Draw dark regions around the scan rect
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, scanRect.top), paint);
    canvas.drawRect(
      Rect.fromLTWH(
        0,
        scanRect.bottom,
        size.width,
        size.height - scanRect.bottom,
      ),
      paint,
    );
    canvas.drawRect(
      Rect.fromLTWH(0, scanRect.top, scanRect.left, scanRect.height),
      paint,
    );
    canvas.drawRect(
      Rect.fromLTWH(
        scanRect.right,
        scanRect.top,
        size.width - scanRect.right,
        scanRect.height,
      ),
      paint,
    );

    // Draw corner brackets
    final cornerPaint = Paint()
      ..color = AppColors.cameraForeground
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    const cornerLength = 24.0;
    const radius = 8.0;

    // Top-left
    canvas.drawLine(
      Offset(scanRect.left + radius, scanRect.top),
      Offset(scanRect.left + cornerLength, scanRect.top),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(scanRect.left, scanRect.top + radius),
      Offset(scanRect.left, scanRect.top + cornerLength),
      cornerPaint,
    );
    canvas.drawArc(
      Rect.fromLTWH(scanRect.left, scanRect.top, radius * 2, radius * 2),
      pi,
      pi / 2,
      false,
      cornerPaint,
    );

    // Top-right
    canvas.drawLine(
      Offset(scanRect.right - cornerLength, scanRect.top),
      Offset(scanRect.right - radius, scanRect.top),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(scanRect.right, scanRect.top + radius),
      Offset(scanRect.right, scanRect.top + cornerLength),
      cornerPaint,
    );
    canvas.drawArc(
      Rect.fromLTWH(
        scanRect.right - radius * 2,
        scanRect.top,
        radius * 2,
        radius * 2,
      ),
      -pi / 2,
      pi / 2,
      false,
      cornerPaint,
    );

    // Bottom-left
    canvas.drawLine(
      Offset(scanRect.left + radius, scanRect.bottom),
      Offset(scanRect.left + cornerLength, scanRect.bottom),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(scanRect.left, scanRect.bottom - cornerLength),
      Offset(scanRect.left, scanRect.bottom - radius),
      cornerPaint,
    );
    canvas.drawArc(
      Rect.fromLTWH(
        scanRect.left,
        scanRect.bottom - radius * 2,
        radius * 2,
        radius * 2,
      ),
      pi / 2,
      pi / 2,
      false,
      cornerPaint,
    );

    // Bottom-right
    canvas.drawLine(
      Offset(scanRect.right - cornerLength, scanRect.bottom),
      Offset(scanRect.right - radius, scanRect.bottom),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(scanRect.right, scanRect.bottom - cornerLength),
      Offset(scanRect.right, scanRect.bottom - radius),
      cornerPaint,
    );
    canvas.drawArc(
      Rect.fromLTWH(
        scanRect.right - radius * 2,
        scanRect.bottom - radius * 2,
        radius * 2,
        radius * 2,
      ),
      0,
      pi / 2,
      false,
      cornerPaint,
    );
  }

  @override
  bool shouldRepaint(_ScanOverlayPainter oldDelegate) =>
      oldDelegate.scanRect != scanRect;
}

class _ScanLinePainter extends CustomPainter {
  final double progress;
  final Color color;

  const _ScanLinePainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final y = progress * size.height;
    final paint = Paint()
      ..shader = LinearGradient(
        colors: [
          color.withValues(alpha: 0),
          color.withValues(alpha: 0.8),
          color.withValues(alpha: 0),
        ],
      ).createShader(Rect.fromLTWH(0, y - 1, size.width, 3))
      ..strokeWidth = 2;

    canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
  }

  @override
  bool shouldRepaint(_ScanLinePainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.color != color;
}
