import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../shared/widgets/glass_card.dart';
import '../../shared/widgets/progress_ring.dart';
import '../../state/water_provider.dart';

/// Home card for tracking daily water intake in glasses.
class HomeWaterCard extends ConsumerWidget {
  const HomeWaterCard({super.key});

  static const LinearGradient _blue = LinearGradient(
    colors: [AppColors.info, AppColors.taskSteps],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final int glasses = ref.watch(waterProvider);
    const int goal = AppConstants.waterTaskGlasses;
    final double pct = (glasses / goal).clamp(0.0, 1.0);
    final int ml = glasses * kGlassMl;
    final String goalL = (goal * kGlassMl / 1000).toStringAsFixed(1);
    final TextTheme text = Theme.of(context).textTheme;

    return GlassCard(
      child: Row(
        children: [
          ProgressRing(
            progress: pct,
            size: 64,
            strokeWidth: 7,
            gradient: _blue,
            center: Text('$glasses/$goal',
                style: const TextStyle(
                    fontWeight: FontWeight.w800, fontSize: 13)),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.water_drop_rounded,
                        color: AppColors.info, size: 18),
                    const SizedBox(width: 4),
                    Text('Water', style: text.titleMedium),
                  ],
                ),
                const SizedBox(height: 2),
                Text('$ml ml today · goal $goalL L', style: text.bodySmall),
              ],
            ),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            onPressed: glasses > 0
                ? () => ref.read(waterProvider.notifier).remove()
                : null,
            icon: const Icon(Icons.remove_circle_outline_rounded),
            color: AppColors.textSecondary,
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.info,
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md, vertical: 10),
            ),
            onPressed: () => ref.read(waterProvider.notifier).add(),
            child: const Icon(Icons.add_rounded, size: 20),
          ),
        ],
      ),
    );
  }
}
