import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plate_track_ai/features/food_recognition/food_camera_controls.dart';
import 'package:plate_track_ai/shared/widgets/camera_scan_overlay.dart';

import 'localized_pump.dart';

void main() {
  setUpAll(initLocalization);

  testWidgets('AI frame stays still and does not block camera gestures', (
    tester,
  ) async {
    var taps = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Stack(
            children: [
              Positioned.fill(child: GestureDetector(onTap: () => taps++)),
              const CameraScanOverlay(),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.binding.transientCallbackCount, 0);
    await tester.tapAt(tester.getCenter(find.byType(CameraScanOverlay)));
    expect(taps, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('barcode alone animates the line and stops on leaving', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: CameraScanOverlay(showScanLine: true)),
      ),
    );
    await tester.pump(const Duration(milliseconds: 250));
    expect(tester.binding.transientCallbackCount, greaterThan(0));
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    expect(tester.binding.transientCallbackCount, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'food hint clears translated actions and the navigation inset on narrow phones',
    (tester) async {
      var galleryTaps = 0;
      var photoTaps = 0;
      await pumpLocalized(
        tester,
        Builder(
          builder: (context) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              padding: const EdgeInsets.only(bottom: 24),
              textScaler: TextScaler.linear(1.5),
            ),
            child: Scaffold(
              body: Stack(
                children: [
                  const CameraScanOverlay(),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: FoodCameraControls(
                      isCapturing: false,
                      onGallery: () => galleryTaps++,
                      onTakePhoto: () => photoTaps++,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        size: const Size(320, 700),
      );
      for (final size in [const Size(320, 700), const Size(390, 844)]) {
        tester.view.physicalSize = size;
        await tester.pumpAndSettle();
        final gallery = find.widgetWithText(ElevatedButton, 'Choose photo');
        final photo = find.widgetWithText(ElevatedButton, 'Take photo');
        final hint = tester.getRect(find.text('Frame your food'));
        for (final button in [gallery, photo]) {
          final rect = tester.getRect(button);
          expect(rect.left, greaterThanOrEqualTo(0));
          expect(rect.right, lessThanOrEqualTo(size.width));
          expect(rect.top, greaterThan(hint.bottom));
          expect(rect.bottom, lessThanOrEqualTo(size.height - 24));
        }
        expect(tester.takeException(), isNull);
      }
      await tester.tap(find.text('Choose photo'));
      await tester.tap(find.text('Take photo'));
      expect(galleryTaps, 1);
      expect(photoTaps, 1);
    },
  );
}
