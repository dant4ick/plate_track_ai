import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plate_track_ai/core/themes/app_theme.dart';
import 'package:plate_track_ai/shared/widgets/see_all_link.dart';

import '../color_test_utils.dart';

void main() {
  for (final entry in {
    'light': AppTheme.lightTheme,
    'dark': AppTheme.darkTheme,
    'pick-me': AppTheme.pickMeTheme,
  }.entries) {
    final theme = entry.value;
    test('${entry.key}: active control text and icons stay readable', () {
      for (final background in [
        theme.scaffoldBackgroundColor,
        theme.colorScheme.surface,
      ]) {
        for (final foreground in [
          theme.appBarTheme.iconTheme!.color!,
          theme.appBarTheme.actionsIconTheme!.color!,
          theme.tabBarTheme.labelColor!,
          theme.tabBarTheme.unselectedLabelColor!,
          theme.textButtonTheme.style!.foregroundColor!.resolve({})!,
          theme.outlinedButtonTheme.style!.foregroundColor!.resolve({})!,
        ]) {
          expect(contrastOn(foreground, background), greaterThanOrEqualTo(4.5));
        }
        for (final state in [
          <WidgetState>{},
          {WidgetState.selected},
          {WidgetState.selected, WidgetState.pressed},
          {WidgetState.selected, WidgetState.hovered},
          {WidgetState.selected, WidgetState.focused},
        ]) {
          expect(
            contrastOn(theme.radioTheme.fillColor!.resolve(state)!, background),
            greaterThanOrEqualTo(3),
          );
        }
      }
    });

    test('${entry.key}: switch thumb stays distinct in every active state', () {
      for (final selected in [false, true]) {
        for (final interaction in [
          <WidgetState>{},
          {WidgetState.pressed},
          {WidgetState.hovered},
          {WidgetState.focused},
        ]) {
          final states = {...interaction, if (selected) WidgetState.selected};
          final thumb = theme.switchTheme.thumbColor!.resolve(states)!;
          final track = theme.switchTheme.trackColor!.resolve(states)!;
          final outline = theme.switchTheme.trackOutlineColor!.resolve(states)!;
          expect(
            contrastOn(thumb, track),
            greaterThanOrEqualTo(3),
            reason: '$states',
          );
          expect(
            contrastOn(outline, theme.colorScheme.surface),
            greaterThanOrEqualTo(3),
            reason: '$states',
          );
        }
      }
    });

    testWidgets('${entry.key}: See all uses readable text and chevron', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: theme,
          home: Scaffold(body: SeeAllLink(onTap: () {})),
        ),
      );
      final text = tester.widget<Text>(
        find.descendant(
          of: find.byType(SeeAllLink),
          matching: find.byType(Text),
        ),
      );
      final icon = tester.widget<Icon>(
        find.byIcon(Icons.chevron_right_rounded),
      );
      expect(
        contrastOn(text.style!.color!, theme.scaffoldBackgroundColor),
        greaterThanOrEqualTo(4.5),
      );
      expect(
        contrastOn(icon.color!, theme.scaffoldBackgroundColor),
        greaterThanOrEqualTo(3),
      );
    });
  }
}
