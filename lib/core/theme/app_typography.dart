import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Premium typography. Display/headline uses a rounded geometric face
/// (Plus Jakarta Sans) for an Apple-clean wellness feel; body uses Inter for
/// legibility. Swap the font families here to re-brand type globally.
abstract final class AppTypography {
  static TextTheme textTheme(Brightness brightness) {
    final Color primary = brightness == Brightness.dark
        ? AppColors.textPrimaryDark
        : AppColors.textPrimary;
    final Color secondary = brightness == Brightness.dark
        ? AppColors.textSecondaryDark
        : AppColors.textSecondary;

    final TextTheme display = GoogleFonts.plusJakartaSansTextTheme();
    final TextTheme body = GoogleFonts.interTextTheme();

    return TextTheme(
      displayLarge: display.displayLarge?.copyWith(
        fontWeight: FontWeight.w800,
        color: primary,
        letterSpacing: -0.5,
      ),
      displaySmall: display.displaySmall?.copyWith(
        fontWeight: FontWeight.w800,
        color: primary,
        letterSpacing: -0.5,
      ),
      headlineMedium: display.headlineMedium?.copyWith(
        fontWeight: FontWeight.w700,
        color: primary,
      ),
      headlineSmall: display.headlineSmall?.copyWith(
        fontWeight: FontWeight.w700,
        color: primary,
      ),
      titleLarge: display.titleLarge?.copyWith(
        fontWeight: FontWeight.w700,
        color: primary,
      ),
      titleMedium: body.titleMedium?.copyWith(
        fontWeight: FontWeight.w600,
        color: primary,
      ),
      titleSmall: body.titleSmall?.copyWith(
        fontWeight: FontWeight.w600,
        color: secondary,
      ),
      bodyLarge: body.bodyLarge?.copyWith(color: primary, height: 1.45),
      bodyMedium: body.bodyMedium?.copyWith(color: secondary, height: 1.45),
      bodySmall: body.bodySmall?.copyWith(color: secondary, height: 1.4),
      labelLarge: body.labelLarge?.copyWith(
        fontWeight: FontWeight.w700,
        color: primary,
        letterSpacing: 0.2,
      ),
    );
  }
}
