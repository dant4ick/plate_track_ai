import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plate_track_ai/core/themes/app_theme.dart';
import 'package:plate_track_ai/features/recommendations/nutrition_advice.dart';
import 'package:plate_track_ai/shared/widgets/app_logo.dart';
import 'package:plate_track_ai/shared/widgets/common_widgets.dart';
import 'package:plate_track_ai/shared/widgets/soft_card.dart';
import 'package:plate_track_ai/shared/widgets/status_snack_bar.dart';
import 'package:plate_track_ai/shared/widgets/tip_card.dart';

/// Optional export: PALETTE_PREVIEW=1 flutter test test/design/color_roles_preview_test.dart
void main() {
  testWidgets('colour roles lay out in all three themes', (tester) async {
    tester.view.physicalSize = const Size(1170, 850);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final previousShadows = debugDisableShadows;
    debugDisableShadows = false;
    try {
      const family = 'PalettePreview';
      for (final path in [
        '/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf',
        '/System/Library/Fonts/Supplemental/Arial.ttf',
      ]) {
        if (!File(path).existsSync()) continue;
        final bytes = await tester.runAsync(() => File(path).readAsBytes());
        await (FontLoader(
          family,
        )..addFont(Future.value(ByteData.sublistView(bytes!)))).load();
        break;
      }

      final iconFile = File(
        '${Platform.resolvedExecutable.split('/artifacts/').first}'
        '/artifacts/material_fonts/MaterialIcons-Regular.otf',
      );
      if (iconFile.existsSync()) {
        final bytes = await tester.runAsync(iconFile.readAsBytes);
        await (FontLoader(
          'MaterialIcons',
        )..addFont(Future.value(ByteData.sublistView(bytes!)))).load();
      }

      final boundaryKey = GlobalKey();
      await tester.pumpWidget(
        RepaintBoundary(
          key: boundaryKey,
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: Row(
              children: [
                for (final entry in {
                  'Light': AppTheme.lightTheme,
                  'Dark': AppTheme.darkTheme,
                  'Pick me': AppTheme.pickMeTheme,
                }.entries)
                  Expanded(
                    child: MaterialApp(
                      debugShowCheckedModeBanner: false,
                      theme: entry.value.copyWith(
                        textTheme: entry.value.textTheme.apply(
                          fontFamily: family,
                        ),
                        appBarTheme: entry.value.appBarTheme.copyWith(
                          titleTextStyle: entry.value.appBarTheme.titleTextStyle
                              ?.copyWith(fontFamily: family),
                        ),
                      ),
                      home: Scaffold(
                        appBar: AppBar(
                          title: Text(entry.key),
                          leading: IconButton(
                            onPressed: () {},
                            icon: const Icon(Icons.arrow_back),
                          ),
                          actions: [
                            IconButton(
                              onPressed: () {},
                              icon: const Icon(Icons.settings_outlined),
                            ),
                          ],
                        ),
                        floatingActionButton: FloatingActionButton(
                          onPressed: () {},
                          child: const Icon(Icons.add),
                        ),
                        body: Builder(
                          builder: (context) => ListView(
                            padding: const EdgeInsets.all(20),
                            children: [
                              const Center(child: AppLogoMark(size: 56)),
                              const SizedBox(height: 24),
                              SoftCard(
                                child: Column(
                                  children: [
                                    Text(
                                      'Filled controls',
                                      style: Theme.of(
                                        context,
                                      ).textTheme.titleMedium,
                                    ),
                                    const SizedBox(height: 12),
                                    AppButton(
                                      text: 'Primary',
                                      onPressed: () {},
                                    ),
                                    const SizedBox(height: 12),
                                    AppButton(
                                      text: 'Secondary',
                                      isSecondary: true,
                                      onPressed: () {},
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 20),
                              RadioGroup<bool>(
                                groupValue: true,
                                onChanged: (_) {},
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceAround,
                                  children: [
                                    const Radio<bool>(value: true),
                                    const Radio<bool>(value: false),
                                    Switch(value: true, onChanged: (_) {}),
                                    Switch(value: false, onChanged: (_) {}),
                                  ],
                                ),
                              ),
                              TextButton(
                                onPressed: () {},
                                child: const Text('See all'),
                              ),
                              const SizedBox(height: 12),
                              const TipCard(
                                tip: NutritionTip(
                                  title: 'Nutrition advice',
                                  description:
                                      'The accent follows the active theme.',
                                  icon: Icons.auto_awesome,
                                  tone: TipTone.accent,
                                ),
                              ),
                              const SizedBox(height: 20),
                              StatusSnackBar.success(
                                context,
                                message: 'Saved successfully',
                                icon: Icons.check_circle,
                              ).withAnimation(const AlwaysStoppedAnimation(1)),
                              const SizedBox(height: 12),
                              StatusSnackBar.error(
                                context,
                                message: 'Could not save changes',
                              ).withAnimation(const AlwaysStoppedAnimation(1)),
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
      expect(find.text('Nutrition advice'), findsNWidgets(3));
      expect(find.text('Saved successfully'), findsNWidgets(3));

      if (Platform.environment['PALETTE_PREVIEW'] == '1') {
        final boundary =
            boundaryKey.currentContext!.findRenderObject()
                as RenderRepaintBoundary;
        await tester.runAsync(() async {
          final preview = await boundary.toImage();
          final bytes = await preview.toByteData(
            format: ui.ImageByteFormat.png,
          );
          final output = File('build/previews/color-roles.png');
          await output.parent.create(recursive: true);
          await output.writeAsBytes(bytes!.buffer.asUint8List());
          preview.dispose();
        });
      }
    } finally {
      debugDisableShadows = previousShadows;
    }
  });
}
