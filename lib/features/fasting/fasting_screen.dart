import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../shared/widgets/glass_card.dart';
import '../../state/fasting_provider.dart';

class FastingScreen extends ConsumerStatefulWidget {
  const FastingScreen({super.key});

  @override
  ConsumerState<FastingScreen> createState() => _FastingScreenState();
}

class _FastingScreenState extends ConsumerState<FastingScreen> {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    // Refresh the countdown once a second while the screen is open.
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  String _hms(int seconds) {
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    final s = seconds % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(fastingProvider);
    final int streak = ref.watch(fastingStreakProvider);
    final TextTheme text = Theme.of(context).textTheme;

    final int targetSecs = state.protocolHours * 3600;
    final int elapsed = state.isFasting
        ? ((DateTime.now().millisecondsSinceEpoch - state.activeStartMillis!) ~/
            1000)
        : 0;
    final double progress = state.isFasting
        ? (elapsed / targetSecs).clamp(0.0, 1.0).toDouble()
        : 0.0;
    final bool goalReached = state.isFasting && elapsed >= targetSecs;
    final int remaining = elapsed >= targetSecs ? 0 : (targetSecs - elapsed);

    final double longest = state.history.isEmpty
        ? 0
        : state.history.map((r) => r.durationHours).reduce((a, b) => a > b ? a : b);

    return Scaffold(
      appBar: AppBar(title: const Text('Intermittent Fasting')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.xxl),
        children: [
          // Protocol chips
          Text('Choose your protocol', style: text.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            children: [
              for (final p in kFastProtocols)
                ChoiceChip(
                  label: Text('${p.label}  ·  ${p.fastingHours}h'),
                  selected: state.protocolHours == p.fastingHours,
                  selectedColor: AppColors.primary,
                  labelStyle: TextStyle(
                    color: state.protocolHours == p.fastingHours
                        ? Colors.white
                        : AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                  onSelected: state.isFasting
                      ? null
                      : (_) => ref
                          .read(fastingProvider.notifier)
                          .setProtocol(p.fastingHours),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),

          // Countdown ring
          Center(
            child: SizedBox(
              width: 250,
              height: 250,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 250,
                    height: 250,
                    child: CircularProgressIndicator(
                      value: state.isFasting ? progress : 0,
                      strokeWidth: 14,
                      backgroundColor: AppColors.primary.withOpacity(0.10),
                      valueColor: AlwaysStoppedAnimation(
                          goalReached ? AppColors.success : AppColors.primary),
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        state.isFasting ? 'FASTING' : 'READY',
                        style: text.labelLarge?.copyWith(
                            color: goalReached
                                ? AppColors.success
                                : AppColors.primary,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        state.isFasting
                            ? _hms(elapsed)
                            : '${state.protocolHours}:${24 - state.protocolHours}',
                        style: text.displaySmall
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        !state.isFasting
                            ? 'Tap start when your last meal is done'
                            : (goalReached
                                ? '🎉 Goal reached! You can stop or keep going'
                                : '${_hms(remaining)} to your ${state.protocolHours}h goal'),
                        style: text.bodySmall
                            ?.copyWith(color: AppColors.textSecondary),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              style: state.isFasting
                  ? FilledButton.styleFrom(
                      backgroundColor:
                          goalReached ? AppColors.success : AppColors.error)
                  : null,
              onPressed: () {
                final now = DateTime.now().millisecondsSinceEpoch;
                if (state.isFasting) {
                  final rec = ref.read(fastingProvider.notifier).endFast(now);
                  HapticFeedback.mediumImpact();
                  if (rec != null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(rec.metGoal
                            ? '✅ Fast complete: ${rec.durationHours.toStringAsFixed(1)}h — goal met!'
                            : 'Fast ended: ${rec.durationHours.toStringAsFixed(1)}h logged'),
                        backgroundColor: rec.metGoal
                            ? AppColors.success
                            : AppColors.info,
                      ),
                    );
                  }
                } else {
                  ref.read(fastingProvider.notifier).startFast(now);
                  HapticFeedback.lightImpact();
                }
              },
              icon: Icon(state.isFasting
                  ? Icons.stop_rounded
                  : Icons.play_arrow_rounded),
              label: Text(state.isFasting ? 'End fast' : 'Start fasting'),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          // Stats
          Row(
            children: [
              _Stat(value: '$streak', label: 'day streak'),
              _Stat(value: '${state.history.length}', label: 'total fasts'),
              _Stat(
                  value: '${longest.toStringAsFixed(0)}h', label: 'longest'),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),

          Text('History', style: text.titleMedium),
          const SizedBox(height: AppSpacing.md),
          if (state.history.isEmpty)
            GlassCard(
              child: Text('Your completed fasts will appear here.',
                  style: text.bodySmall
                      ?.copyWith(color: AppColors.textSecondary)),
            )
          else
            GlassCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  for (final r in state.history.take(20))
                    _HistoryRow(record: r, last: r == state.history.take(20).last),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label});
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: GlassCard(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
          child: Column(
            children: [
              Text(value, style: text.titleLarge),
              Text(label,
                  style: text.bodySmall
                      ?.copyWith(color: AppColors.textSecondary)),
            ],
          ),
        ),
      ),
    );
  }
}

class _HistoryRow extends StatelessWidget {
  const _HistoryRow({required this.record, required this.last});
  final FastRecord record;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final date = DateTime.fromMillisecondsSinceEpoch(record.endMillis);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg, vertical: AppSpacing.md),
          child: Row(
            children: [
              Icon(record.metGoal ? Icons.check_circle_rounded : Icons.timelapse_rounded,
                  color: record.metGoal ? AppColors.success : AppColors.info,
                  size: 20),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${record.durationHours.toStringAsFixed(1)}h fast',
                        style: text.titleSmall),
                    Text(
                        '${DateFormat('d MMM, h:mm a').format(date)} · ${record.targetHours}h goal',
                        style: text.bodySmall
                            ?.copyWith(color: AppColors.textSecondary)),
                  ],
                ),
              ),
              if (record.metGoal)
                Text('Goal met',
                    style: text.bodySmall?.copyWith(
                        color: AppColors.success,
                        fontWeight: FontWeight.w700)),
            ],
          ),
        ),
        if (!last) const Divider(height: 1, indent: 16, endIndent: 16),
      ],
    );
  }
}
