import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:plate_track_ai/core/services/food_storage_service.dart';
import 'package:plate_track_ai/core/services/barcode_cache_service.dart';
import 'package:plate_track_ai/shared/models/food_item.dart';
import 'package:plate_track_ai/features/barcode_scan/barcode_result_screen.dart';
import 'package:plate_track_ai/core/themes/app_colors.dart';
import 'package:plate_track_ai/shared/widgets/standard_app_bar.dart';
import 'package:plate_track_ai/shared/widgets/camera_scan_overlay.dart';

class BarcodeScannerScreen extends StatefulWidget {
  const BarcodeScannerScreen({super.key});

  @override
  State<BarcodeScannerScreen> createState() => _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends State<BarcodeScannerScreen> {
  final MobileScannerController _controller = MobileScannerController();
  bool _isProcessing = false;

  final _foodStorageService = FoodStorageService();
  final _barcodeCacheService = BarcodeCacheService();

  @override
  void initState() {
    super.initState();
    _initServices();
  }

  Future<void> _initServices() async {
    await _foodStorageService.initialize();
    await _barcodeCacheService.initialize();
  }

  @override
  void dispose() {
    _controller.dispose();
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
        builder: (_) =>
            BarcodeResultScreen(barcode: rawValue, onSave: _onFoodSaved),
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
      backgroundColor: AppColors.cameraBackdrop,
      appBar: StandardAppBar(
        backgroundColor: AppColors.cameraBackdrop,
        foregroundColor: AppColors.cameraForeground,
        titleText: 'barcode_scanner'.tr(),
        showLogo: false,
      ),
      body: Stack(
        children: [
          MobileScanner(controller: _controller, onDetect: _onBarcodeDetected),
          const CameraScanOverlay(showScanLine: true),
          CameraScanHint(text: 'barcode_scanner_hint'.tr()),
        ],
      ),
    );
  }
}
