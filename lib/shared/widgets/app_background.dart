import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// A calming, wellness-inspired backdrop rendered behind every screen: a soft
/// vertical gradient plus a few gentle radial "glows" (green + gold) that give
/// a spa-like, uplifting feel. Fully code-drawn (no image assets), subtle
/// enough to keep all text readable, and adapts to light/dark mode.
///
/// Wired in globally via `MaterialApp.builder`, with transparent Scaffolds so
/// it shows through on every page.
class AppBackground extends StatelessWidget {
  const AppBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final bool dark = Theme.of(context).brightness == Brightness.dark;

    final List<Color> base = dark
        ? const [Color(0xFF0B1512), Color(0xFF0E1B16), Color(0xFF0B1512)]
        : const [Color(0xFFF4FBF8), Color(0xFFEFF7F2), Color(0xFFF7FAF9)];

    return Stack(
      children: [
        // Base gradient
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: base,
              ),
            ),
          ),
        ),

        // Green glow, top-right (energy / freshness)
        Positioned(
          top: -140,
          right: -110,
          child: _Glow(
            color: AppColors.primary,
            opacity: dark ? 0.22 : 0.16,
            size: 360,
          ),
        ),

        // Gold glow, bottom-left (warmth / motivation)
        Positioned(
          bottom: -160,
          left: -120,
          child: _Glow(
            color: AppColors.accent,
            opacity: dark ? 0.12 : 0.10,
            size: 320,
          ),
        ),

        // Soft secondary-green glow, mid-left (balance)
        Positioned(
          top: 280,
          left: -140,
          child: _Glow(
            color: AppColors.secondary,
            opacity: dark ? 0.10 : 0.08,
            size: 280,
          ),
        ),

        // App content on top
        Positioned.fill(child: child),
      ],
    );
  }
}

class _Glow extends StatelessWidget {
  const _Glow({
    required this.color,
    required this.opacity,
    required this.size,
  });

  final Color color;
  final double opacity;
  final double size;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [color.withOpacity(opacity), color.withOpacity(0)],
          ),
        ),
      ),
    );
  }
}
