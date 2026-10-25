import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_theme.dart';

/// The theme the app renders, including the option to follow the OS.
///
/// [ThemePreference.pickMe] cannot ride on `ThemeMode`, which only spans
/// light/dark/system — it is selected by handing `MaterialApp.theme` a
/// different [ThemeData] outright.
enum ThemePreference { system, light, dark, pickMe }

/// Which theme is currently showing.
///
/// A plain [ValueNotifier]; persistence is attached by [initThemePreference]
/// at startup rather than baked in here, so widget tests can drive the value
/// directly without mocking storage.
final ValueNotifier<ThemePreference> themePreference = ValueNotifier(
  ThemePreference.system,
);

const _themePreferenceKey = 'theme_preference';

bool _persistenceAttached = false;

/// Restores the stored theme choice and starts persisting future changes.
///
/// Called once from `main()` before `runApp`. Idempotent: a second call
/// re-reads storage but never attaches a second listener. The stored value is
/// the enum's name, so an unrecognised value (say, from a downgrade after a
/// theme was removed) falls back to following the OS rather than throwing.
Future<void> initThemePreference() async {
  final prefs = await SharedPreferences.getInstance();
  final stored = prefs.getString(_themePreferenceKey);

  themePreference.value = ThemePreference.values.asNameMap()[stored] ??
      ThemePreference.system;

  if (_persistenceAttached) return;
  _persistenceAttached = true;
  themePreference.addListener(() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themePreferenceKey, themePreference.value.name);
  });
}

/// Maps a preference onto the pair of values `MaterialApp` needs.
///
/// An explicit choice is expressed by handing [theme] the right [ThemeData]
/// *and* pinning [mode] so `MaterialApp` cannot fall through to `darkTheme`
/// on a device set to dark.
extension ThemePreferenceThemes on ThemePreference {
  ThemeData get theme => switch (this) {
    ThemePreference.pickMe => AppTheme.pickMeTheme,
    ThemePreference.dark => AppTheme.darkTheme,
    ThemePreference.light || ThemePreference.system => AppTheme.lightTheme,
  };

  ThemeMode get mode => switch (this) {
    ThemePreference.system => ThemeMode.system,
    ThemePreference.dark => ThemeMode.dark,
    // Pick-me is light in brightness, so it is selected via `theme`, not mode.
    ThemePreference.light || ThemePreference.pickMe => ThemeMode.light,
  };
}
