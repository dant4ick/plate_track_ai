import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plate_track_ai/core/themes/app_theme.dart';

import '../color_test_utils.dart';

void main() {
  for (final entry in {
    'light': AppTheme.lightTheme,
    'dark': AppTheme.darkTheme,
    'pick-me': AppTheme.pickMeTheme,
  }.entries) {
    testWidgets(
      '${entry.key}: focused/error labels and error text stay readable',
      (tester) async {
        final form = GlobalKey<FormState>();
        final theme = entry.value;
        await tester.pumpWidget(
          MaterialApp(
            theme: theme,
            home: Scaffold(
              body: Form(
                key: form,
                child: TextFormField(
                  initialValue: '70',
                  decoration: const InputDecoration(labelText: 'Weight'),
                  validator: (_) => 'Invalid weight',
                ),
              ),
            ),
          ),
        );
        await tester.tap(find.byType(TextFormField));
        await tester.pumpAndSettle();

        void checkText(String value, Color background) {
          final rich = tester
              .widgetList<RichText>(find.byType(RichText))
              .where((w) => w.text.toPlainText() == value)
              .toList();
          expect(rich, isNotEmpty, reason: value);
          for (final paragraph in rich) {
            expect(
              contrastOn(paragraph.text.style!.color!, background),
              greaterThanOrEqualTo(4.5),
              reason: value,
            );
          }
        }

        final fill = theme.inputDecorationTheme.fillColor!;
        checkText('Weight', fill);
        form.currentState!.validate();
        await tester.pumpAndSettle();
        checkText('Weight', fill);
        checkText('Invalid weight', theme.scaffoldBackgroundColor);
        final decorator = tester.widget<InputDecorator>(
          find.byType(InputDecorator),
        );
        expect(
          decorator.decoration.focusedErrorBorder!.borderSide.color,
          theme.colorScheme.error,
        );
        expect(tester.takeException(), isNull);
      },
    );
  }
}
