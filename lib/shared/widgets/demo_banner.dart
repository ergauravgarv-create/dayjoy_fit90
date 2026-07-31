import 'package:flutter/material.dart';

import '../../core/env/app_config.dart';

/// A small, professional "Demo Data" indicator overlaid at the bottom of the
/// screen whenever the app is running on sample data (mock backend). It is
/// non-interactive (never blocks taps) and disappears automatically once the
/// app is switched to the live Firebase backend.
///
/// Wrap the app's content with this via `MaterialApp.builder`.
class DemoModeOverlay extends StatelessWidget {
  const DemoModeOverlay({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!AppConfig.isMock) return child;

    return Stack(
      children: [
        child,
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: IgnorePointer(
            child: SafeArea(
              minimum: const EdgeInsets.only(bottom: 6),
              child: Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0E1B16).withOpacity(0.82),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: const Color(0x33FFFFFF)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.science_outlined,
                          size: 13, color: Color(0xFFFFB800)),
                      SizedBox(width: 6),
                      Text(
                        'DEMO DATA · not real health information',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
