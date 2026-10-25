import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:plate_track_ai/core/themes/app_theme.dart';
import 'package:plate_track_ai/shared/widgets/app_logo.dart';

/// LOGO_PREVIEW=1 flutter test test/design/logo_preview_test.dart
void main() {
  testWidgets('designer logos render with exact brand pairs at UI sizes', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1140, 560);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.runAsync(() async {
      await (FontLoader('Montserrat')..addFont(
            rootBundle.load('assets/fonts/Montserrat/Montserrat-Regular.ttf'),
          ))
          .load();
    });

    final page = GlobalKey();
    final marks = List.generate(3, (_) => GlobalKey());
    final variants = [
      ('Dark / Main icon', AppTheme.darkTheme, 0xFF4D55F5, 0xFFDAFF7C),
      ('Light', AppTheme.lightTheme, 0xFFB0DD4E, 0xFFFFFFFF),
      ('Pick me', AppTheme.pickMeTheme, 0xFFFF7AB5, 0xFFF9D9DA),
    ];
    await tester.pumpWidget(
      RepaintBoundary(
        key: page,
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: Row(
            children: [
              for (var index = 0; index < variants.length; index++)
                Expanded(
                  child: MaterialApp(
                    debugShowCheckedModeBanner: false,
                    theme: variants[index].$2,
                    home: Scaffold(
                      body: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              variants[index].$1,
                              style: const TextStyle(fontSize: 24),
                            ),
                            const SizedBox(height: 24),
                            RepaintBoundary(
                              key: marks[index],
                              child: const AppLogoMark(size: 224),
                            ),
                            const SizedBox(height: 32),
                            const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                AppLogoMark(size: 80),
                                SizedBox(width: 24),
                                AppLogoMark(size: 34),
                                SizedBox(width: 24),
                                AppLogoMark(size: 30),
                              ],
                            ),
                            const SizedBox(height: 16),
                            const Text('224 / 80 / 34 / 30 px'),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    for (var index = 0; index < variants.length; index++) {
      final boundary =
          marks[index].currentContext!.findRenderObject()
              as RenderRepaintBoundary;
      final image = await tester.runAsync(() async {
        final raster = await boundary.toImage();
        final png = await raster.toByteData(format: ui.ImageByteFormat.png);
        raster.dispose();
        return img.decodePng(png!.buffer.asUint8List())!;
      });
      int argbAt(int x, int y) {
        final pixel = image!.getPixel(x, y);
        return (pixel.a.toInt() << 24) |
            (pixel.r.toInt() << 16) |
            (pixel.g.toInt() << 8) |
            pixel.b.toInt();
      }

      expect(argbAt(112, 112), variants[index].$3);
      expect(argbAt(112, 35), variants[index].$4);
      expect(image!.getPixel(0, 0).a, 0);
    }

    if (Platform.environment['LOGO_PREVIEW'] == '1') {
      final boundary =
          page.currentContext!.findRenderObject() as RenderRepaintBoundary;
      await tester.runAsync(() async {
        final raster = await boundary.toImage(pixelRatio: 2);
        final png = await raster.toByteData(format: ui.ImageByteFormat.png);
        final file = File('build/previews/designer-logos.png');
        await file.parent.create(recursive: true);
        await file.writeAsBytes(png!.buffer.asUint8List());
        raster.dispose();
      });
    }
  });
}
