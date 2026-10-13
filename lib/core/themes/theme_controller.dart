import 'package:flutter/material.dart';

import 'app_theme.dart';

/// The theme the app renders, including the option to follow the OS.
///
/// [ThemePreference.pickMe] cannot ride on `ThemeMode`, which only spans
/// light/dark/system — it is selected by handing `MaterialApp.theme` a
/// different [ThemeData] outright.
enum ThemePreference { system, light, dark, pickMe }

/// Which theme is currently showing.
///
/// Deliberately minimal: a plain [ValueNotifier] with no persistence, so the
/// choice resets on restart. It exists so the three design themes can be
/// eyeballed on a device without building a settings screen first. When theme
/// choice becomes a real user-facing feature, back this with a stored
/// preference (Hive is already set up) and drive it from the profile screen.
final ValueNotifier<ThemePreference> themePreference = ValueNotifier(
  ThemePreference.system,
);

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
