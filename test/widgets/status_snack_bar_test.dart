import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plate_track_ai/core/themes/app_theme.dart';
import 'package:plate_track_ai/shared/widgets/status_snack_bar.dart';

void main() {
  testWidgets('success without an icon wraps long text at large text scale', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    const message = 'Your food item was deleted successfully from your meals.';
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(2)),
          child: child!,
        ),
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => ScaffoldMessenger.of(
                context,
              ).showSnackBar(StatusSnackBar.success(context, message: message)),
              child: const Text('Show'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Show'));
    await tester.pumpAndSettle();
    expect(find.text(message), findsOneWidget);
    expect(find.byIcon(Icons.check_circle), findsOneWidget);
    final bar = tester.getRect(find.byType(SnackBar));
    final text = tester.getRect(find.text(message));
    expect(bar.contains(text.topLeft), isTrue);
    expect(bar.contains(text.bottomRight), isTrue);
    expect(tester.takeException(), isNull);
  });

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
            expect(background, entry.value.colorScheme.surface);
            expect(bar.behavior, SnackBarBehavior.floating);
            expect(
              (bar.shape! as RoundedRectangleBorder).borderRadius,
              BorderRadius.circular(20),
            );
            final icon = tester.widget<Icon>(find.byIcon(Icons.check_circle));
            final badge = tester.widget<Container>(
              find
                  .ancestor(
                    of: find.byIcon(Icons.check_circle),
                    matching: find.byType(Container),
                  )
                  .first,
            );
            final fill = (badge.decoration! as BoxDecoration).color!;
            expect(fill, const Color(0xFFB0DD4E));
            expect(_contrast(icon.color!, fill), greaterThanOrEqualTo(4.5));
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
