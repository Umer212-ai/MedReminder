import 'package:flutter/material.dart';

class AppColors {
  // Primary colors - More vibrant
  static const Color primary = Color(0xFF6366F1);
  static const Color primaryDark = Color(0xFF4F46E5);
  static const Color primaryLight = Color(0xFF818CF8);
  
  // Secondary / Accent colors
  static const Color secondary = Color(0xFF10B981);
  static const Color accent = Color(0xFFF59E0B);
  static const Color purple = Color(0xFF8B5CF6);
  static const Color orange = Color(0xFFF97316);
  static const Color pink = Color(0xFFEC4899);

  // Light Theme Palette
  static const Color background = Color(0xFFF8FAFC);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color cardBackground = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF1E293B);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textLight = Color(0xFF94A3B8);

  // Dark Theme Palette - More Premium "Deep Midnight"
  static const Color backgroundDark = Color(0xFF0F172A); // Rich Navy Black
  static const Color surfaceDark = Color(0xFF1E293B);    // Slate Blue Grey
  static const Color cardBackgroundDark = Color(0xFF1E293B);
  static const Color textPrimaryDark = Color(0xFFF8FAFC);
  static const Color textSecondaryDark = Color(0xFFCBD5E1);
  static const Color textLightDark = Color(0xFF64748B);

  // Status colors
  static const Color success = Color(0xFF10B981);
  static const Color error = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF59E0B);
  static const Color info = Color(0xFF3B82F6);

  // Sophisticated Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, Color(0xFF4F46E5)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient emergencyGradient = LinearGradient(
    colors: [Color(0xFFEF4444), Color(0xFFB91C1C)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient healthGradient = LinearGradient(
    colors: [Color(0xFF10B981), Color(0xFF059669)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Dark mode mesh gradient (subtle)
  static const LinearGradient darkMeshGradient = LinearGradient(
    colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // Helper for dynamic colors
  static Color getBackgroundColor(BuildContext context) => 
      Theme.of(context).brightness == Brightness.dark ? backgroundDark : background;
      
  static Color getSurfaceColor(BuildContext context) => 
      Theme.of(context).brightness == Brightness.dark ? surfaceDark : surface;
      
  static Color getTextPrimary(BuildContext context) => 
      Theme.of(context).brightness == Brightness.dark ? textPrimaryDark : textPrimary;

  static Color getTextSecondary(BuildContext context) => 
      Theme.of(context).brightness == Brightness.dark ? textSecondaryDark : textSecondary;
}
