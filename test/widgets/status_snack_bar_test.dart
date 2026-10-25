import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plate_track_ai/core/themes/app_theme.dart';
import 'package:plate_track_ai/shared/widgets/status_snack_bar.dart';

void main() {
  for (final entry in {
    'light': AppTheme.lightTheme,
    'dark': AppTheme.darkTheme,
    'pick-me': AppTheme.pickMeTheme,
  }.entries) {
    for (final isError in [false, true]) {
      testWidgets(
        '${entry.key}: readable ${isError ? "error" : "success"} message',
        (tester) async {
          await tester.pumpWidget(
            MaterialApp(
              theme: entry.value,
              home: Scaffold(
                body: Builder(
                  builder: (context) {
                    return TextButton(
                      onPressed: () =>
                          ScaffoldMessenger.of(context).showSnackBar(
                            isError
                                ? StatusSnackBar.error(
                                    context,
                                    message: 'Saved status',
                                  )
                                : StatusSnackBar.success(
                                    context,
                                    message: 'Saved status',
                                    icon: Icons.check_circle,
                                  ),
                          ),
                      child: const Text('Show'),
                    );
                  },
                ),
              ),
            ),
          );
          await tester.tap(find.text('Show'));
          await tester.pumpAndSettle();

          final bar = tester.widget<SnackBar>(find.byType(SnackBar));
          final text = tester.widget<Text>(find.text('Saved status'));
          final background = bar.backgroundColor!;
          expect(
            _contrast(text.style!.color!, background),
            greaterThanOrEqualTo(4.5),
          );
          if (isError) {
            expect(background, entry.value.colorScheme.error);
          } else {
            final icon = tester.widget<Icon>(find.byIcon(Icons.check_circle));
            expect(
              _contrast(icon.color!, background),
              greaterThanOrEqualTo(4.5),
            );
          }
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
}

double _contrast(Color foreground, Color background) {
  final a = foreground.computeLuminance();
  final b = background.computeLuminance();
  return a > b ? (a + 0.05) / (b + 0.05) : (b + 0.05) / (a + 0.05);
}
