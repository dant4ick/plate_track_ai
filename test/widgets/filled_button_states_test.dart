import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plate_track_ai/core/themes/app_theme.dart';
import 'package:plate_track_ai/shared/widgets/common_widgets.dart';
import 'package:plate_track_ai/shared/widgets/delete_food.dart';

import '../color_test_utils.dart';
import '../test_utils.dart';

void checkButton(ButtonStyle style) {
  for (final states in [
    <WidgetState>{},
    {WidgetState.hovered},
    {WidgetState.focused},
    {WidgetState.pressed},
  ]) {
    final background = style.backgroundColor!.resolve(states)!;
    final foreground = style.foregroundColor!.resolve(states)!;
    final overlay = style.overlayColor?.resolve(states);
    final painted = overlay == null
        ? background
        : Color.alphaBlend(overlay, background);
    expect(
      contrastOn(foreground, painted),
      greaterThanOrEqualTo(4.5),
      reason: '$states: $foreground on $painted',
    );
    if (states.isNotEmpty) expect(overlay?.a, greaterThan(0));
  }
}

void main() {
  final item = TestDataFactory.createFoodItem();
  for (final entry in {
    'light': AppTheme.lightTheme,
    'dark': AppTheme.darkTheme,
    'pick-me': AppTheme.pickMeTheme,
  }.entries) {
    testWidgets(
      '${entry.key}: filled and destructive buttons keep contrast with state layers',
      (tester) async {
        final theme = entry.value;
        checkButton(theme.elevatedButtonTheme.style!);
        await tester.pumpWidget(
          MaterialApp(
            theme: theme,
            home: Scaffold(
              body: Column(
                children: [
                  AppButton(text: 'Primary', onPressed: () {}),
                  AppButton(
                    text: 'Secondary',
                    isSecondary: true,
                    onPressed: () {},
                  ),
                  Builder(
                    builder: (context) => TextButton(
                      onPressed: () => showDeleteConfirmationDialog(
                        context: context,
                        item: item,
                        onDeleteConfirmed: () async {},
                        confirmationTextKey: 'Confirm',
                        undoWarningTextKey: 'Cannot undo',
                        successMessageKey: 'Deleted',
                        deleteButtonTextKey: 'Delete',
                      ),
                      child: const Text('Open deletion'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
        for (final button in tester.widgetList<ElevatedButton>(
          find.byType(ElevatedButton),
        )) {
          checkButton(theme.elevatedButtonTheme.style!.merge(button.style));
        }
        await tester.tap(find.text('Open deletion'));
        await tester.pumpAndSettle();
        final button = tester.widget<ElevatedButton>(
          find.descendant(
            of: find.byType(AlertDialog),
            matching: find.byType(ElevatedButton),
          ),
        );
        checkButton(theme.elevatedButtonTheme.style!.merge(button.style));
        expect(tester.takeException(), isNull);
      },
    );
  }
}
