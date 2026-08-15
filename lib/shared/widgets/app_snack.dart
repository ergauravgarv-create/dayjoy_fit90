import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

enum AppSnackType { success, error, info }

/// A branded, icon-led snackbar. The theme already makes snackbars floating &
/// rounded; this adds a leading icon and type color for clear, consistent
/// feedback. Use: `showAppSnack(context, 'Saved!', type: AppSnackType.success)`.
void showAppSnack(
  BuildContext context,
  String message, {
  AppSnackType type = AppSnackType.info,
}) {
  // Safe to call after an await: if the widget was unmounted meanwhile, do
  // nothing instead of throwing "State no longer has a context".
  if (!context.mounted) return;
  final (Color color, IconData icon) = switch (type) {
    AppSnackType.success => (AppColors.success, Icons.check_circle_rounded),
    AppSnackType.error => (AppColors.error, Icons.error_rounded),
    AppSnackType.info => (AppColors.info, Icons.info_rounded),
  };
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        backgroundColor: color,
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(message,
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
}
