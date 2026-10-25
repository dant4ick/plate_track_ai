import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plate_track_ai/shared/widgets/soft_card.dart';

void main() {
  testWidgets('falls back to the active surface when card colour is unset', (
    tester,
  ) async {
    final theme = ThemeData.dark().copyWith(cardTheme: const CardThemeData());
    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        home: const Scaffold(body: SoftCard(child: Text('Content'))),
      ),
    );
    final panel = tester.widget<DecoratedBox>(
      find
          .descendant(
            of: find.byType(SoftCard),
            matching: find.byType(DecoratedBox),
          )
          .first,
    );
    expect(
      (panel.decoration as BoxDecoration).color,
      theme.colorScheme.surface,
    );
  });
}
