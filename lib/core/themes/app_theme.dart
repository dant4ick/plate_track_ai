import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const _primaryColorLight = Color(0xFF4CAF50);
  static const _primaryColorDark = Color(0xFF388E3C);
  static const _secondaryColorLight = Color(0xFF2196F3);
  static const _secondaryColorDark = Color(0xFF1976D2);
  static const _errorColor = Color(0xFFE57373);
  static const _successColor = Color(0xFF81C784);
  static const _warningColor = Color(0xFFFFD54F);
  static const _infoColor = Color(0xFF64B5F6);
  static const _surfaceLight = Color(0xFFFAFAFA);
  static const _surfaceDark = Color(0xFF121212);
  static const _backgroundLight = Color(0xFFFFFFFF);
  static const _backgroundDark = Color(0xFF1F1F1F);

  // Light theme
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: ColorScheme.light(
      primary: _primaryColorLight,
      secondary: _secondaryColorLight,
      error: _errorColor,
      surface: _surfaceLight,
      background: _backgroundLight,
    ),
    textTheme: GoogleFonts.poppinsTextTheme(ThemeData.light().textTheme),
    appBarTheme: AppBarTheme(
      backgroundColor: _surfaceLight,
      elevation: 0,
      iconTheme: const IconThemeData(color: _primaryColorLight),
      titleTextStyle: GoogleFonts.poppins(
        color: Colors.black87,
        fontSize: 20.0,
        fontWeight: FontWeight.w500,
      ),
    ),
    cardTheme: CardTheme(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: _primaryColorLight,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: _primaryColorLight,
      foregroundColor: Colors.white,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.grey[100],
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _primaryColorLight, width: 2),
      ),
    ),
  );

  // Dark theme
  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.dark(
      primary: _primaryColorDark,
      secondary: _secondaryColorDark,
      error: _errorColor,
      surface: _surfaceDark,
      background: _backgroundDark,
    ),
    textTheme: GoogleFonts.poppinsTextTheme(ThemeData.dark().textTheme),
    appBarTheme: AppBarTheme(
      backgroundColor: _surfaceDark,
      elevation: 0,
      iconTheme: const IconThemeData(color: _primaryColorDark),
      titleTextStyle: GoogleFonts.poppins(
        color: Colors.white,
        fontSize: 20.0,
        fontWeight: FontWeight.w500,
      ),
    ),
    cardTheme: CardTheme(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: _primaryColorDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: _primaryColorDark,
      foregroundColor: Colors.white,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.grey[900],
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _primaryColorDark, width: 2),
      ),
    ),
  );
}