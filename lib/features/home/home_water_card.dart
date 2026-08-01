import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../shared/widgets/glass_card.dart';
import '../../state/water_provider.dart';

/// Home card for tracking daily water intake in glasses.
class HomeWaterCard extends ConsumerWidget {
  const HomeWaterCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final int glasses = ref.watch(waterProvider);
    const int goal = AppConstants.waterTaskGlasses;
    final double pct = (glasses / goal).clamp(0.0, 1.0);
    final int ml = glasses * kGlassMl;
    final String goalL = (goal * kGlassMl / 1000).toStringAsFixed(1);
    final bool done = glasses >= goal;
    final TextTheme text = Theme.of(context).textTheme;

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.water_drop_rounded,
                  color: AppColors.info, size: 20),
              const SizedBox(width: 6),
              Text('Water', style: text.titleMedium),
              const Spacer(),
              Text('$glasses / $goal glasses',
                  style: text.titleSmall?.copyWith(
                      color: done ? AppColors.success : AppColors.info,
                      fontWeight: FontWeight.w800)),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 12,
              backgroundColor: AppColors.info.withOpacity(0.12),
              valueColor: AlwaysStoppedAnimation(
                  done ? AppColors.success : AppColors.info),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: Text(
                  done
                      ? 'Goal reached! $ml ml today 🎉'
                      : '$ml ml today · goal $goalL L',
                  style: text.bodySmall,
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
              const SizedBox(width: 4),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.info,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 8),
                  visualDensity: VisualDensity.compact,
                ),
                onPressed: () => ref.read(waterProvider.notifier).add(),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Glass'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
