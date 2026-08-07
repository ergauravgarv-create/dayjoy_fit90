import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../shared/widgets/glass_card.dart';
import '../../state/providers.dart';
import '../../state/streak_provider.dart';

class StreakScreen extends ConsumerWidget {
  const StreakScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final TextTheme text = Theme.of(context).textTheme;
    final int current = ref.watch(streakProvider);
    final int longest = ref.watch(longestStreakProvider);
    final Set<String> active = ref.watch(activeDaysProvider);
    final freeze = ref.watch(freezeStateProvider);
    final String quote = ref.watch(dailyQuoteProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Streak & motivation')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.xxl),
        children: [
          // Streak header
          GlassCard(
            gradient: AppColors.goldGradient,
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Row(
              children: [
                const Icon(Icons.local_fire_department_rounded,
                    color: Colors.white, size: 52),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('$current-day streak',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 26,
                              fontWeight: FontWeight.w900)),
                      Text('Longest: $longest days · ${active.length} active days',
                          style:
                              TextStyle(color: Colors.white.withOpacity(0.95))),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Freeze tokens
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.ac_unit_rounded,
                        color: AppColors.info, size: 26),
                    const SizedBox(width: AppSpacing.sm),
                    Text('${freeze.tokens} freeze token${freeze.tokens == 1 ? '' : 's'}',
                        style: text.titleMedium),
                    const Spacer(),
                    FilledButton.tonal(
                      onPressed: freeze.tokens > 0
                          ? () {
                              final ok = ref
                                  .read(freezeStateProvider.notifier)
                                  .useFreeze();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(ok
                                      ? '❄️ Today is protected — your streak is safe!'
                                      : 'Already protected today.'),
                                  backgroundColor: AppColors.info,
                                ),
                              );
                            }
                          : null,
                      child: const Text('Use freeze'),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                    'A freeze protects one day if you can\'t complete your tasks, '
                    'so a single miss won\'t break your streak.',
                    style: text.bodySmall
                        ?.copyWith(color: AppColors.textSecondary)),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Heatmap
          Text('Your last 12 weeks', style: text.titleMedium),
          const SizedBox(height: AppSpacing.md),
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: _Heatmap(active: active, frozen: freeze.frozen),
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    _LegendDot(color: AppColors.surfaceMuted, label: 'Inactive'),
                    const SizedBox(width: AppSpacing.md),
                    _LegendDot(color: AppColors.success, label: 'Active'),
                    const SizedBox(width: AppSpacing.md),
                    _LegendDot(color: AppColors.info, label: 'Frozen'),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Daily motivation
          Text('Daily motivation', style: text.titleMedium),
          const SizedBox(height: AppSpacing.md),
          GlassCard(
            gradient: AppColors.mixGradient,
            child: Row(
              children: [
                const Icon(Icons.format_quote_rounded,
                    color: Colors.white, size: 32),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(quote,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          height: 1.3)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Heatmap extends StatelessWidget {
  const _Heatmap({required this.active, required this.frozen});
  final Set<String> active;
  final Set<String> frozen;

  static const int _weeks = 12;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    // Start ~12 weeks back, aligned to a Monday.
    DateTime start = today.subtract(const Duration(days: _weeks * 7 - 1));
    while (start.weekday != DateTime.monday) {
      start = start.subtract(const Duration(days: 1));
    }

    final columns = <Widget>[];
    DateTime cursor = start;
    while (!cursor.isAfter(today)) {
      final cells = <Widget>[];
      for (int d = 0; d < 7; d++) {
        final date = cursor.add(Duration(days: d));
        cells.add(_cell(date, today));
      }
      columns.add(Column(children: cells));
      cursor = cursor.add(const Duration(days: 7));
    }

    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: columns);
  }

  Widget _cell(DateTime date, DateTime today) {
    if (date.isAfter(today)) {
      return const Padding(
        padding: EdgeInsets.all(2),
        child: SizedBox(width: 14, height: 14),
      );
    }
    final key = streakDayKey(date);
    final bool isFrozen = frozen.contains(key);
    final bool isActive = active.contains(key);
    final bool isToday = date == today;

    final Color color = isFrozen
        ? AppColors.info
        : (isActive ? AppColors.success : AppColors.surfaceMuted);

    return Padding(
      padding: const EdgeInsets.all(2),
      child: Container(
        width: 14,
        height: 14,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(3),
          border: isToday
              ? Border.all(color: AppColors.primary, width: 1.5)
              : null,
        ),
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
              color: color, borderRadius: BorderRadius.circular(3)),
        ),
        const SizedBox(width: 4),
        Text(label,
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: AppColors.textSecondary)),
      ],
    );
  }
}
