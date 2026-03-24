import 'dart:math';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:plate_track_ai/core/services/food_storage_service.dart';
import 'package:plate_track_ai/core/services/barcode_cache_service.dart';
import 'package:plate_track_ai/shared/models/food_item.dart';
import 'package:plate_track_ai/features/barcode_scan/barcode_result_screen.dart';

class BarcodeScannerScreen extends StatefulWidget {
  const BarcodeScannerScreen({super.key});

  @override
  State<BarcodeScannerScreen> createState() => _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends State<BarcodeScannerScreen>
    with SingleTickerProviderStateMixin {
  final MobileScannerController _controller = MobileScannerController();
  bool _isProcessing = false;

  late AnimationController _scanLineController;
  late Animation<double> _scanLineAnimation;

  final _foodStorageService = FoodStorageService();
  final _barcodeCacheService = BarcodeCacheService();

  @override
  void initState() {
    super.initState();
    _scanLineController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _scanLineAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _scanLineController, curve: Curves.easeInOut),
    );

    _initServices();
  }

  Future<void> _initServices() async {
    await _foodStorageService.initialize();
    await _barcodeCacheService.initialize();
  }

  @override
  void dispose() {
    _controller.dispose();
    _scanLineController.dispose();
    super.dispose();
  }

  void _onBarcodeDetected(BarcodeCapture capture) {
    if (_isProcessing) return;
    final barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final rawValue = barcodes.first.rawValue;
    if (rawValue == null || rawValue.isEmpty) return;

    _isProcessing = true;
    _controller.stop();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BarcodeResultScreen(
          barcode: rawValue,
          onSave: _onFoodSaved,
        ),
      ),
    ).then((_) {
      if (mounted) {
        _isProcessing = false;
        _controller.start();
      }
    });
  }

  void _onFoodSaved(FoodItem foodItem) {
    _foodStorageService.saveFoodItem(foodItem);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text('barcode_scanner'.tr()),
        elevation: 0,
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _onBarcodeDetected,
          ),
          _buildScanOverlay(),
          _buildHintText(),
        ],
      ),
    );
  }

  Widget _buildScanOverlay() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = min(constraints.maxWidth, constraints.maxHeight) * 0.65;
        final left = (constraints.maxWidth - size) / 2;
        final top = (constraints.maxHeight - size) / 2 - 40;

        return Stack(
          children: [
            // Dark mask outside reticle
            CustomPaint(
              size: Size(constraints.maxWidth, constraints.maxHeight),
              painter: _ScanOverlayPainter(
                scanRect: Rect.fromLTWH(left, top, size, size),
              ),
            ),
            // Animated scan line
            Positioned(
              left: left + 2,
              top: top + 2,
              width: size - 4,
              height: size - 4,
              child: ClipRect(
                child: AnimatedBuilder(
                  animation: _scanLineAnimation,
                  builder: (context, child) {
                    return CustomPaint(
                      painter: _ScanLinePainter(
                        progress: _scanLineAnimation.value,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildHintText() {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 48),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Text(
            'barcode_scanner_hint'.tr(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
            ),
          ),
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
    final paint = Paint()..color = Colors.black.withValues(alpha: 0.55);

    // Draw dark regions around the scan rect
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, scanRect.top), paint);
    canvas.drawRect(
        Rect.fromLTWH(0, scanRect.bottom, size.width, size.height - scanRect.bottom), paint);
    canvas.drawRect(Rect.fromLTWH(0, scanRect.top, scanRect.left, scanRect.height), paint);
    canvas.drawRect(
        Rect.fromLTWH(scanRect.right, scanRect.top, size.width - scanRect.right, scanRect.height),
        paint);

    // Draw corner brackets
    final cornerPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    const cornerLength = 24.0;
    const radius = 8.0;

    // Top-left
    canvas.drawLine(
        Offset(scanRect.left + radius, scanRect.top),
        Offset(scanRect.left + cornerLength, scanRect.top),
        cornerPaint);
    canvas.drawLine(
        Offset(scanRect.left, scanRect.top + radius),
        Offset(scanRect.left, scanRect.top + cornerLength),
        cornerPaint);
    canvas.drawArc(
        Rect.fromLTWH(scanRect.left, scanRect.top, radius * 2, radius * 2),
        pi, pi / 2, false, cornerPaint);

    // Top-right
    canvas.drawLine(
        Offset(scanRect.right - cornerLength, scanRect.top),
        Offset(scanRect.right - radius, scanRect.top),
        cornerPaint);
    canvas.drawLine(
        Offset(scanRect.right, scanRect.top + radius),
        Offset(scanRect.right, scanRect.top + cornerLength),
        cornerPaint);
    canvas.drawArc(
        Rect.fromLTWH(scanRect.right - radius * 2, scanRect.top, radius * 2, radius * 2),
        -pi / 2, pi / 2, false, cornerPaint);

    // Bottom-left
    canvas.drawLine(
        Offset(scanRect.left + radius, scanRect.bottom),
        Offset(scanRect.left + cornerLength, scanRect.bottom),
        cornerPaint);
    canvas.drawLine(
        Offset(scanRect.left, scanRect.bottom - cornerLength),
        Offset(scanRect.left, scanRect.bottom - radius),
        cornerPaint);
    canvas.drawArc(
        Rect.fromLTWH(scanRect.left, scanRect.bottom - radius * 2, radius * 2, radius * 2),
        pi / 2, pi / 2, false, cornerPaint);

    // Bottom-right
    canvas.drawLine(
        Offset(scanRect.right - cornerLength, scanRect.bottom),
        Offset(scanRect.right - radius, scanRect.bottom),
        cornerPaint);
    canvas.drawLine(
        Offset(scanRect.right, scanRect.bottom - cornerLength),
        Offset(scanRect.right, scanRect.bottom - radius),
        cornerPaint);
    canvas.drawArc(
        Rect.fromLTWH(scanRect.right - radius * 2, scanRect.bottom - radius * 2, radius * 2,
            radius * 2),
        0, pi / 2, false, cornerPaint);
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
