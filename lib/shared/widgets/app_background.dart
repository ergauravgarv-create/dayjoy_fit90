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
    // Clean, professional near-white base with subtle green + orange accents.
    return Stack(
      children: [
        const Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFFFFFFF), Color(0xFFF6F8FA), Color(0xFFFFFFFF)],
              ),
            ),
          ),
        ),

        // Faint green glow, top-right
        const Positioned(
          top: -150,
          right: -120,
          child: _Glow(color: AppColors.primary, opacity: 0.07, size: 340),
        ),

        // Faint orange glow, bottom-left
        const Positioned(
          bottom: -170,
          left: -130,
          child: _Glow(color: AppColors.orange, opacity: 0.06, size: 300),
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
