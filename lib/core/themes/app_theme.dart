import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_dimens.dart';

class AppTheme {
  AppTheme._();

  /// Bundled Latin and Cyrillic font, shared by every theme and locale.
  static const fontFamily = 'Montserrat';

  /// Keep feedback on filled controls while preserving text contrast after
  /// compositing the state layer over indigo and destructive backgrounds.
  static ButtonStyle filledButtonStyle({
    required Color foregroundColor,
    required Color backgroundColor,
    EdgeInsetsGeometry? padding,
    OutlinedBorder? shape,
  }) =>
      ElevatedButton.styleFrom(
        foregroundColor: foregroundColor,
        backgroundColor: backgroundColor,
        padding: padding,
        shape: shape,
      ).copyWith(
        overlayColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) return null;
          if (states.contains(WidgetState.pressed) ||
              states.contains(WidgetState.focused) ||
              states.contains(WidgetState.hovered)) {
            return foregroundColor.withValues(alpha: 0.08);
          }
          return null;
        }),
      );

  // The design frames give each brightness a different brand hue: the light
  // theme is driven by the lime `second` token, the dark theme by the indigo
  // `prime` token. Each is the other's secondary.
  static const _primaryLight = AppColors.secondShade;
  static const _primaryDark = AppColors.prime;
  static const _secondaryLight = AppColors.prime;
  static const _secondaryDark = AppColors.second;

  // Light theme
  static final ThemeData lightTheme = _readableControls(
    ThemeData(
      useMaterial3: true,
      fontFamily: fontFamily,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.scaffoldLight,
      extensions: const [AppFlavorTag(AppFlavor.light)],
      colorScheme: const ColorScheme.light(
        primary: _primaryLight,
        onPrimary: AppColors.onAccentDark,
        secondary: _secondaryLight,
        onSecondary: AppColors.onAccent,
        tertiary: AppColors.tri,
        onTertiary: AppColors.onAccentDark,
        error: AppColors.dangerLight,
        onError: AppColors.onAccentDark,
        surface: AppColors.surfaceLight,
        onSurface: AppColors.textPrimaryLight,
        outline: AppColors.textSecondaryLight,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: const TextStyle(
          fontFamily: fontFamily,
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
        style: filledButtonStyle(
          foregroundColor: AppColors.onAccentDark,
          backgroundColor: _primaryLight,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimens.radiusControl),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: _primaryLight,
        foregroundColor: AppColors.onAccentDark,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimens.radiusSquircle),
        ),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.triShade,
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
          borderSide: const BorderSide(
            color: AppColors.textPrimaryLight,
            width: 2,
          ),
        ),
      ),
    ),
  );

  // Dark theme
  static final ThemeData darkTheme = _readableControls(
    ThemeData(
      useMaterial3: true,
      fontFamily: fontFamily,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.scaffoldDark,
      extensions: const [AppFlavorTag(AppFlavor.dark)],
      colorScheme: const ColorScheme.dark(
        primary: _primaryDark,
        onPrimary: AppColors.onAccent,
        secondary: _secondaryDark,
        onSecondary: AppColors.onAccentDark,
        tertiary: AppColors.tri,
        onTertiary: AppColors.onAccentDark,
        error: AppColors.dangerDark,
        onError: AppColors.onAccentDark,
        surface: AppColors.surfaceDark,
        onSurface: AppColors.textPrimaryDark,
        outline: AppColors.textSecondaryDark,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: const TextStyle(
          fontFamily: fontFamily,
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
        style: filledButtonStyle(
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
        color: AppColors.tri,
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
          borderSide: const BorderSide(
            color: AppColors.textPrimaryDark,
            width: 2,
          ),
        ),
      ),
    ),
  );

  // "Pick me" theme — a third brand identity, light in brightness but pink in
  // hue. `ThemeMode` only spans light/dark/system, so this one cannot ride on
  // the OS setting: pass it to `MaterialApp.theme` directly from a stored user
  // preference.
  //
  // One deviation from the pattern the other two follow, taken from the design
  // frame rather than inferred: the FAB stays lime. Navigation uses readable ink.
  static final ThemeData pickMeTheme = _readableControls(
    ThemeData(
      useMaterial3: true,
      fontFamily: fontFamily,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.scaffoldPick,
      extensions: const [AppFlavorTag(AppFlavor.pickMe)],
      colorScheme: const ColorScheme.light(
        primary: AppColors.pick,
        onPrimary: AppColors.onAccentDark,
        secondary: AppColors.secondShade,
        // Dark ink, not white: this secondary is the lime shade, and white on it
        // is 1.70:1. Matches what the dark theme already does with its lime.
        onSecondary: AppColors.onAccentDark,
        tertiary: AppColors.tri,
        onTertiary: AppColors.onAccentDark,
        error: AppColors.dangerLight,
        onError: AppColors.onAccentDark,
        surface: AppColors.surfaceLight,
        onSurface: AppColors.textPrimaryLight,
        outline: AppColors.textSecondaryLight,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: const TextStyle(
          fontFamily: fontFamily,
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
        style: filledButtonStyle(
          foregroundColor: AppColors.onAccentDark,
          backgroundColor: AppColors.pick,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimens.radiusControl),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.secondShade,
        foregroundColor: AppColors.onAccentDark,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimens.radiusSquircle),
        ),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.triShade,
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
          borderSide: const BorderSide(
            color: AppColors.textPrimaryLight,
            width: 2,
          ),
        ),
      ),
    ),
  );

  /// Filled accents keep the brand palette; text and interactive outlines use
  /// readable ink. Set state colours explicitly instead of M3 container fallbacks.
  static ThemeData _readableControls(ThemeData theme) {
    final scheme = theme.colorScheme;
    final muted = theme.brightness == Brightness.dark
        ? AppColors.textSecondaryDark
        : AppColors.textSecondaryLight;
    return theme.copyWith(
      // Derive default text colours from the active scheme.
      textTheme: theme.textTheme.apply(
        bodyColor: scheme.onSurface,
        displayColor: scheme.onSurface,
      ),
      inputDecorationTheme: theme.inputDecorationTheme.copyWith(
        labelStyle: WidgetStateTextStyle.resolveWith(
          (states) => TextStyle(
            color: states.contains(WidgetState.disabled)
                ? scheme.onSurface.withValues(alpha: 0.38)
                : scheme.onSurface,
          ),
        ),
        floatingLabelStyle: WidgetStateTextStyle.resolveWith(
          (states) => TextStyle(
            color: states.contains(WidgetState.disabled)
                ? scheme.onSurface.withValues(alpha: 0.38)
                : scheme.onSurface,
          ),
        ),
        errorStyle: theme.textTheme.bodySmall?.copyWith(
          color: scheme.onSurface,
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimens.radiusControl),
          borderSide: BorderSide(color: scheme.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimens.radiusControl),
          borderSide: BorderSide(color: scheme.error, width: 2),
        ),
      ),
      appBarTheme: theme.appBarTheme.copyWith(
        iconTheme: IconThemeData(color: scheme.onSurface),
        actionsIconTheme: IconThemeData(color: scheme.onSurface),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: scheme.onSurface),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: scheme.onSurface,
          side: BorderSide(color: muted),
        ),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: scheme.onSurface,
        unselectedLabelColor: muted,
        indicatorColor: scheme.onSurface,
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) return null;
          return states.contains(WidgetState.selected)
              ? scheme.onSurface
              : muted;
        }),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) return null;
          return states.contains(WidgetState.selected)
              ? scheme.onPrimary
              : muted;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) return null;
          return states.contains(WidgetState.selected)
              ? scheme.primary
              : theme.inputDecorationTheme.fillColor ?? scheme.surface;
        }),
        trackOutlineColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) return null;
          return muted;
        }),
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: scheme.onSurface,
        selectionHandleColor: scheme.onSurface,
        selectionColor: scheme.primary.withValues(alpha: 0.3),
      ),
    );
  }
}
