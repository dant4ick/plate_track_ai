import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plate_track_ai/core/themes/app_colors.dart';
import 'package:plate_track_ai/core/themes/app_theme.dart';
import 'package:plate_track_ai/shared/widgets/standard_app_bar.dart';

import '../color_test_utils.dart';

void main() {
  for (final entry in {
    'light': AppTheme.lightTheme,
    'dark': AppTheme.darkTheme,
    'pick-me': AppTheme.pickMeTheme,
  }.entries) {
    testWidgets(
      '${entry.key}: camera title, back and actions override app chrome',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: entry.value,
            home: Builder(
              builder: (context) => Scaffold(
                body: TextButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => Scaffold(
                        backgroundColor: AppColors.cameraBackdrop,
                        appBar: StandardAppBar(
                          titleText: 'Scanner',
                          showLogo: false,
                          backgroundColor: AppColors.cameraBackdrop,
                          foregroundColor: AppColors.cameraForeground,
                          actions: [
                            IconButton(
                              onPressed: () {},
                              icon: const Icon(Icons.flash_on),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  child: const Text('Open'),
                ),
              ),
            ),
          ),
        );
        await tester.tap(find.text('Open'));
        await tester.pumpAndSettle();
        final title = tester.widget<RichText>(
          find.descendant(
            of: find.text('Scanner'),
            matching: find.byType(RichText),
          ),
        );
        expect(
          contrastOn(title.text.style!.color!, AppColors.cameraBackdrop),
          greaterThanOrEqualTo(4.5),
        );
        for (final finder in [
          find.descendant(
            of: find.byType(BackButton),
            matching: find.byType(Icon),
          ),
          find.byIcon(Icons.flash_on),
        ]) {
          final icon = tester.widget<Icon>(finder);
          final effective =
              icon.color ?? IconTheme.of(tester.element(finder)).color!;
          expect(effective, AppColors.cameraForeground);
          expect(
            contrastOn(effective, AppColors.cameraBackdrop),
            greaterThanOrEqualTo(3),
          );
        }
        expect(tester.takeException(), isNull);
      },
    );
  }
}
