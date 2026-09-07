import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Colour palette mirrors the web frontend so the mobile app feels
/// like part of the same product, not a re-skin.
class AppColors {
  static const soilDark = Color(0xFF1F2A1D);
  static const leaf = Color(0xFF3C6E47);
  static const leafDark = Color(0xFF2A4D32);
  static const leafLight = Color(0xFFE7F0E6);
  static const harvest = Color(0xFFD9A441);
  static const harvestDark = Color(0xFFB9862F);
  static const clay = Color(0xFF8B5E3C);
  static const paper = Color(0xFFF6F7F2);
  static const paper2 = Color(0xFFEEF1E7);
  static const line = Color(0xFFD8DCCD);
  static const danger = Color(0xFFB3423A);
}

ThemeData buildAppTheme() {
  final base = ThemeData(useMaterial3: true, brightness: Brightness.light);

  return base.copyWith(
    scaffoldBackgroundColor: AppColors.paper,
    colorScheme: base.colorScheme.copyWith(
      primary: AppColors.leaf,
      secondary: AppColors.harvest,
      error: AppColors.danger,
      surface: Colors.white,
    ),
    textTheme: GoogleFonts.interTextTheme(base.textTheme).copyWith(
      headlineSmall: GoogleFonts.merriweather(
        fontWeight: FontWeight.w700,
        fontSize: 22,
        color: AppColors.soilDark,
      ),
      titleLarge: GoogleFonts.merriweather(
        fontWeight: FontWeight.w700,
        fontSize: 18,
        color: AppColors.soilDark,
      ),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.paper,
      foregroundColor: AppColors.soilDark,
      elevation: 0,
      centerTitle: false,
      surfaceTintColor: Colors.transparent,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.leaf,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
          side: const BorderSide(color: AppColors.leafDark, width: 2),
        ),
        textStyle: const TextStyle(fontWeight: FontWeight.w600),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.soilDark,
        side: const BorderSide(color: AppColors.soilDark, width: 2),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4),
        borderSide: const BorderSide(color: Color(0xFFB7BDA6)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4),
        borderSide: const BorderSide(color: Color(0xFFB7BDA6)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4),
        borderSide: const BorderSide(color: AppColors.leaf, width: 2),
      ),
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(4),
        side: const BorderSide(color: AppColors.soilDark, width: 1),
      ),
    ),
  );
}
