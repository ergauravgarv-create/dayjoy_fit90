import 'package:flutter/material.dart';

/// Dayjoy Fit90 brand palette.
///
/// Premium wellness — Green + White. Keep every color reference in the app
/// pointing here so re-branding is a single-file change.
abstract final class AppColors {
  // Brand
  static const Color primary = Color(0xFF0D8B6F); // deep wellness green
  static const Color secondary = Color(0xFF1FBF75); // vibrant green
  static const Color accent = Color(0xFFFFB800); // gold — points, streaks

  // Surfaces (light)
  static const Color background = Color(0xFFF7FAF9);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceMuted = Color(0xFFEFF5F2);

  // Surfaces (dark)
  static const Color backgroundDark = Color(0xFF0B1512);
  static const Color surfaceDark = Color(0xFF14211C);
  static const Color surfaceMutedDark = Color(0xFF1C2C26);

  // Text
  static const Color textPrimary = Color(0xFF0E1B16);
  static const Color textSecondary = Color(0xFF5B6B65);
  static const Color textPrimaryDark = Color(0xFFF2F7F5);
  static const Color textSecondaryDark = Color(0xFFA6B5AF);

  // Semantic
  static const Color success = Color(0xFF1FBF75);
  static const Color warning = Color(0xFFFFB800);
  static const Color error = Color(0xFFE5484D);
  static const Color info = Color(0xFF3B82F6);

  // Task accent colors (5 daily tasks)
  static const Color taskYoga = Color(0xFF7C5CFC);
  static const Color taskMorningNutrition = Color(0xFFFF8A5B);
  static const Color taskFitness = Color(0xFF0D8B6F);
  static const Color taskSteps = Color(0xFF2E9BFF);
  static const Color taskNightNutrition = Color(0xFF5B6BFF);

  // Gradients
  static const LinearGradient brandGradient = LinearGradient(
    colors: [primary, secondary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient goldGradient = LinearGradient(
    colors: [Color(0xFFFFD24C), accent],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const Color glassBorder = Color(0x33FFFFFF);
  static const Color shadow = Color(0x140D8B6F);
}
