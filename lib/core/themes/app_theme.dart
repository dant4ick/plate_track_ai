import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

class AppTheme {
  AppTheme._();

  // The design frames give each brightness a different brand hue: the light
  // theme is driven by the lime `second` token, the dark theme by the indigo
  // `prime` token. Each is the other's secondary.
  static const _primaryLight = AppColors.secondShade;
  static const _primaryDark = AppColors.prime;
  static const _secondaryLight = AppColors.prime;
  static const _secondaryDark = AppColors.second;

  // Light theme
  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: AppColors.scaffoldLight,
    extensions: const [AppFlavorTag(AppFlavor.light)],
    colorScheme: const ColorScheme.light(
      primary: _primaryLight,
      onPrimary: AppColors.onAccent,
      secondary: _secondaryLight,
      onSecondary: AppColors.onAccent,
      tertiary: AppColors.tri,
      onTertiary: AppColors.onAccent,
      error: AppColors.dangerLight,
      onError: AppColors.onAccent,
      surface: AppColors.surfaceLight,
      onSurface: AppColors.textPrimaryLight,
      outline: AppColors.borderLight,
    ),
    textTheme: GoogleFonts.poppinsTextTheme(ThemeData.light().textTheme),
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.appBarLight,
      elevation: 0,
      iconTheme: const IconThemeData(color: _primaryLight),
      titleTextStyle: GoogleFonts.poppins(
        color: AppColors.textPrimaryLight,
        fontSize: 20.0,
        fontWeight: FontWeight.w500,
      ),
    ),
    cardTheme: CardThemeData(
      color: AppColors.surfaceLight,
      elevation: 2,
      shadowColor: AppColors.shadowSoft,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    dividerColor: AppColors.borderLight,
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        foregroundColor: AppColors.onAccent,
        backgroundColor: _primaryLight,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: _primaryLight,
      foregroundColor: AppColors.onAccent,
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: _primaryLight,
      linearTrackColor: AppColors.trackLight,
    ),
    snackBarTheme: const SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      actionTextColor: AppColors.onAccent,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.fieldLight,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _primaryLight, width: 2),
      ),
    ),
  );

  // Dark theme
  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.scaffoldDark,
    extensions: const [AppFlavorTag(AppFlavor.dark)],
    colorScheme: const ColorScheme.dark(
      primary: _primaryDark,
      onPrimary: AppColors.onAccent,
      secondary: _secondaryDark,
      onSecondary: AppColors.textPrimaryLight,
      tertiary: AppColors.tri,
      onTertiary: AppColors.onAccent,
      error: AppColors.dangerDark,
      onError: AppColors.onAccent,
      surface: AppColors.surfaceDark,
      onSurface: AppColors.textPrimaryDark,
      outline: AppColors.borderDark,
    ),
    textTheme: GoogleFonts.poppinsTextTheme(ThemeData.dark().textTheme),
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.appBarDark,
      elevation: 0,
      iconTheme: const IconThemeData(color: _primaryDark),
      titleTextStyle: GoogleFonts.poppins(
        color: AppColors.textPrimaryDark,
        fontSize: 20.0,
        fontWeight: FontWeight.w500,
      ),
    ),
    cardTheme: CardThemeData(
      color: AppColors.surfaceDark,
      elevation: 2,
      shadowColor: AppColors.shadowMedium,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    dividerColor: AppColors.borderDark,
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        foregroundColor: AppColors.onAccent,
        backgroundColor: _primaryDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: _primaryDark,
      foregroundColor: AppColors.onAccent,
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: _primaryDark,
      linearTrackColor: AppColors.trackDark,
    ),
    snackBarTheme: const SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      actionTextColor: AppColors.onAccent,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.fieldDark,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _primaryDark, width: 2),
      ),
    ),
  );

  // "Pick me" theme — a third brand identity, light in brightness but pink in
  // hue. `ThemeMode` only spans light/dark/system, so this one cannot ride on
  // the OS setting: pass it to `MaterialApp.theme` directly from a stored user
  // preference.
  //
  // Two deviations from the pattern the other two follow, both taken from the
  // design frame rather than inferred:
  //  * the app bar is tinted rather than flush with the scaffold;
  //  * the FAB and app-bar icons stay lime, not pink.
  static final ThemeData pickMeTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: AppColors.scaffoldPick,
    extensions: const [AppFlavorTag(AppFlavor.pickMe)],
    colorScheme: const ColorScheme.light(
      primary: AppColors.pick,
      onPrimary: AppColors.onAccent,
      secondary: AppColors.secondShade,
      onSecondary: AppColors.onAccent,
      tertiary: AppColors.tri,
      onTertiary: AppColors.onAccent,
      error: AppColors.dangerLight,
      onError: AppColors.onAccent,
      surface: AppColors.surfaceLight,
      onSurface: AppColors.textPrimaryLight,
      outline: AppColors.borderLight,
    ),
    textTheme: GoogleFonts.poppinsTextTheme(ThemeData.light().textTheme),
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.pickBar,
      elevation: 0,
      iconTheme: const IconThemeData(color: AppColors.secondShade),
      titleTextStyle: GoogleFonts.poppins(
        color: AppColors.onAccent,
        fontSize: 20.0,
        fontWeight: FontWeight.w500,
      ),
    ),
    cardTheme: CardThemeData(
      color: AppColors.surfaceLight,
      elevation: 2,
      shadowColor: AppColors.shadowSoft,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    dividerColor: AppColors.borderLight,
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        foregroundColor: AppColors.onAccent,
        backgroundColor: AppColors.pick,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: AppColors.secondShade,
      foregroundColor: AppColors.onAccent,
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: AppColors.pickCalories,
      linearTrackColor: AppColors.trackLight,
    ),
    snackBarTheme: const SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      actionTextColor: AppColors.onAccent,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.fieldLight,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.pick, width: 2),
      ),
    ),
  );
}
