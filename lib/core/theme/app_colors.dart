import 'package:flutter/material.dart';

/// Dayjoy Fit90 brand palette.
///
/// Premium wellness — Green + White. Keep every color reference in the app
/// pointing here so re-branding is a single-file change.
abstract final class AppColors {
  // Brand — green + Dayjoy orange
  static const Color primary = Color(0xFF0D8B6F); // deep wellness green
  static const Color secondary = Color(0xFF1FBF75); // vibrant green
  static const Color orange = Color(0xFFFA6E35); // Dayjoy brand orange
  static const Color orangeDark = Color(0xFFE85A22);
  static const Color accent = orange; // points, streaks, energy

  // Surfaces (light) — clean, professional white
  static const Color background = Color(0xFFF6F8FA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceMuted = Color(0xFFF0F3F4);

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

  // Orange "energy" gradient (kept named goldGradient for compatibility).
  static const LinearGradient goldGradient = LinearGradient(
    colors: [Color(0xFFFF9A5A), orange],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient orangeGradient = goldGradient;

  // Green → orange blend, for standout hero elements.
  static const LinearGradient mixGradient = LinearGradient(
    colors: [primary, orange],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const Color glassBorder = Color(0x33FFFFFF);
  static const Color shadow = Color(0x14000000);

  /// The right card/sheet surface for the current brightness. Use this instead
  /// of the raw `surface` constant anywhere a container must adapt to dark mode
  /// (e.g. `showModalBottomSheet(backgroundColor: AppColors.surfaceOf(context))`).
  static Color surfaceOf(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? surfaceDark : surface;
}
