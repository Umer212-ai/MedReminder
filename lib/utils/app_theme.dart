import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return _buildTheme(Brightness.light);
  }

  static ThemeData get darkTheme {
    return _buildTheme(Brightness.dark);
  }

  static ThemeData _buildTheme(Brightness brightness) {
    bool isDark = brightness == Brightness.dark;
    Color background = isDark ? AppColors.backgroundDark : AppColors.background;
    Color surface = isDark ? AppColors.surfaceDark : AppColors.surface;
    Color textPrimary = isDark ? AppColors.textPrimaryDark : AppColors.textPrimary;
    Color textSecondary = isDark ? AppColors.textSecondaryDark : AppColors.textSecondary;
    Color textLight = isDark ? AppColors.textLightDark : AppColors.textLight;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: brightness,
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        surface: surface,
        error: AppColors.error,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: textPrimary,
        onError: Colors.white,
      ),
      scaffoldBackgroundColor: background,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: textPrimary,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.poppins(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: textPrimary,
        ),
        iconTheme: IconThemeData(color: textPrimary),
      ),
      cardTheme: CardThemeData(
        color: isDark ? AppColors.cardBackgroundDark : AppColors.cardBackground,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: textLight.withValues(alpha: 0.1), width: 1),
        ),
        clipBehavior: Clip.antiAlias,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: textLight.withValues(alpha: 0.1)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: textLight.withValues(alpha: 0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        hintStyle: GoogleFonts.poppins(
          color: textLight,
          fontSize: 14,
        ),
      ),
      textTheme: TextTheme(
        displayLarge: GoogleFonts.poppins(fontSize: 32, fontWeight: FontWeight.bold, color: textPrimary),
        headlineLarge: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold, color: textPrimary),
        headlineMedium: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: textPrimary),
        titleLarge: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: textPrimary),
        titleMedium: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: textPrimary),
        bodyLarge: GoogleFonts.poppins(fontSize: 16, color: textPrimary, height: 1.5),
        bodyMedium: GoogleFonts.poppins(fontSize: 14, color: textSecondary, height: 1.5),
        labelLarge: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold, color: textPrimary),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: surface,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: textLight,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
    );
  }
}
