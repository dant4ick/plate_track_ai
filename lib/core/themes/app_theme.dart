import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';
import 'app_dimens.dart';

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
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
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
      shadowColor: AppColors.shadowSubtle,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimens.radiusCard),
      ),
    ),
    dividerColor: AppColors.borderLight,
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        foregroundColor: AppColors.onAccent,
        backgroundColor: _primaryLight,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimens.radiusControl),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: _primaryLight,
      foregroundColor: AppColors.onAccent,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimens.radiusSquircle),
      ),
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
        borderRadius: BorderRadius.circular(AppDimens.radiusControl),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppDimens.radiusControl),
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
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
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
      shadowColor: AppColors.shadowStrong,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimens.radiusCard),
      ),
    ),
    dividerColor: AppColors.borderDark,
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        foregroundColor: AppColors.onAccent,
        backgroundColor: _primaryDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimens.radiusControl),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: _primaryDark,
      foregroundColor: AppColors.onAccent,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimens.radiusSquircle),
      ),
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
        borderRadius: BorderRadius.circular(AppDimens.radiusControl),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppDimens.radiusControl),
        borderSide: const BorderSide(color: _primaryDark, width: 2),
      ),
    ),
  );

  // "Pick me" theme — a third brand identity, light in brightness but pink in
  // hue. `ThemeMode` only spans light/dark/system, so this one cannot ride on
  // the OS setting: pass it to `MaterialApp.theme` directly from a stored user
  // preference.
  //
  // One deviation from the pattern the other two follow, taken from the design
  // frame rather than inferred: the FAB and app-bar icons stay lime, not pink.
  static final ThemeData pickMeTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: AppColors.scaffoldPick,
    extensions: const [AppFlavorTag(AppFlavor.pickMe)],
    colorScheme: const ColorScheme.light(
      primary: AppColors.pick,
      onPrimary: AppColors.onAccent,
      secondary: AppColors.secondShade,
      // Dark ink, not white: this secondary is the lime shade, and white on it
      // is 1.70:1. Matches what the dark theme already does with its lime.
      onSecondary: AppColors.textPrimaryLight,
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
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      iconTheme: const IconThemeData(color: AppColors.secondShade),
      titleTextStyle: GoogleFonts.poppins(
        // The bar is transparent, so the title sits on the pale pink scaffold:
        // white would vanish there. Ink, like the other two themes use.
        color: AppColors.textPrimaryLight,
        fontSize: 20.0,
        fontWeight: FontWeight.w500,
      ),
    ),
    cardTheme: CardThemeData(
      color: AppColors.surfaceLight,
      elevation: 2,
      shadowColor: AppColors.shadowSubtle,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimens.radiusCard),
      ),
    ),
    dividerColor: AppColors.borderLight,
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        foregroundColor: AppColors.onAccent,
        backgroundColor: AppColors.pick,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimens.radiusControl),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: AppColors.secondShade,
      foregroundColor: AppColors.onAccent,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimens.radiusSquircle),
      ),
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
        borderRadius: BorderRadius.circular(AppDimens.radiusControl),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppDimens.radiusControl),
        borderSide: const BorderSide(color: AppColors.pick, width: 2),
      ),
    ),
  );
}
