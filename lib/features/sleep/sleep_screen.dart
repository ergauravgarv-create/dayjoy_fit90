import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../shared/widgets/bar_series_chart.dart';
import '../../shared/widgets/glass_card.dart';
import '../../shared/widgets/progress_ring.dart';
import '../../state/sleep_provider.dart';

class SleepScreen extends ConsumerStatefulWidget {
  const SleepScreen({super.key});

  @override
  ConsumerState<SleepScreen> createState() => _SleepScreenState();
}

class _SleepScreenState extends ConsumerState<SleepScreen> {
  TimeOfDay _bed = const TimeOfDay(hour: 22, minute: 30);
  TimeOfDay _wake = const TimeOfDay(hour: 6, minute: 30);
  int _quality = 4;

  static const LinearGradient _indigo = LinearGradient(
    colors: [AppColors.taskYoga, AppColors.info],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  int _min(TimeOfDay t) => t.hour * 60 + t.minute;

  int get _durationMin {
    int d = _min(_wake) - _min(_bed);
    if (d <= 0) d += 1440;
    return d;
  }

  String _hm(int minutes) => '${minutes ~/ 60}h ${minutes % 60}m';

  Future<void> _pick(bool bed) async {
    final picked = await showTimePicker(
        context: context, initialTime: bed ? _bed : _wake);
    if (picked != null) {
      setState(() => bed ? _bed = picked : _wake = picked);
    }
  }

  void _save() {
    final now = DateTime.now();
    final dayMillis = DateTime(now.year, now.month, now.day).millisecondsSinceEpoch;
    ref.read(sleepLogProvider.notifier).log(
          dateMillis: dayMillis,
          bedMinute: _min(_bed),
          wakeMinute: _min(_wake),
          quality: _quality,
        );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('😴 Logged ${_hm(_durationMin)} of sleep'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final log = ref.watch(sleepLogProvider);
    final int goal = ref.watch(sleepGoalProvider);
    final double avg = ref.watch(avgSleepHoursProvider);
    final List<double> week = ref.watch(weeklySleepHoursProvider);
    final TextTheme text = Theme.of(context).textTheme;

    final double lastNight = _durationMin / 60.0;
    final double pct = (lastNight / goal).clamp(0.0, 1.0).toDouble();

    final now = DateTime.now();
    final base = DateTime(now.year, now.month, now.day);
    const wd = ['', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final labels = [
      for (int i = 6; i >= 0; i--) wd[base.subtract(Duration(days: i)).weekday]
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Sleep')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.xxl),
        children: [
          // Ring + stats
          GlassCard(
            child: Row(
              children: [
                ProgressRing(
                  progress: pct,
                  size: 100,
                  strokeWidth: 11,
                  gradient: _indigo,
                  center: Text('${lastNight.toStringAsFixed(1)}h',
                      style: text.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w800)),
                ),
                const SizedBox(width: AppSpacing.lg),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${_hm(_durationMin)} last night',
                          style: text.titleMedium),
                      const SizedBox(height: 2),
                      Text('Goal ${goal}h · avg ${avg.toStringAsFixed(1)}h',
                          style: text.bodySmall
                              ?.copyWith(color: AppColors.textSecondary)),
                      const SizedBox(height: 2),
                      Text(
                          '${_bed.format(context)} → ${_wake.format(context)}',
                          style: text.bodySmall
                              ?.copyWith(color: AppColors.textSecondary)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Log form
          Text('Log last night', style: text.titleMedium),
          const SizedBox(height: AppSpacing.md),
          GlassCard(
            child: Column(
              children: [
                _TimeRow(
                    icon: Icons.bedtime_rounded,
                    label: 'Bedtime',
                    value: _bed.format(context),
                    onTap: () => _pick(true)),
                const Divider(height: AppSpacing.lg),
                _TimeRow(
                    icon: Icons.wb_sunny_rounded,
                    label: 'Wake up',
                    value: _wake.format(context),
                    onTap: () => _pick(false)),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Text('Quality', style: text.bodyMedium),
                    const Spacer(),
                    for (int i = 1; i <= 5; i++)
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        icon: Icon(
                          i <= _quality
                              ? Icons.star_rounded
                              : Icons.star_border_rounded,
                          color: AppColors.accent,
                        ),
                        onPressed: () => setState(() => _quality = i),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _save,
                    icon: const Icon(Icons.check_rounded),
                    label: Text('Save (${_hm(_durationMin)})'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Goal
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text('Sleep goal', style: text.titleMedium),
                    const Spacer(),
                    Text('${goal}h',
                        style: text.titleMedium
                            ?.copyWith(color: AppColors.taskYoga)),
                  ],
                ),
                Slider(
                  value: goal.toDouble(),
                  min: 5,
                  max: 12,
                  divisions: 7,
                  label: '${goal}h',
                  onChanged: (v) =>
                      ref.read(sleepGoalProvider.notifier).setGoal(v.toInt()),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          Text('This week', style: text.titleMedium),
          const SizedBox(height: AppSpacing.md),
          GlassCard(
            child: BarSeriesChart(values: week, labels: labels, gradient: _indigo),
          ),
          const SizedBox(height: AppSpacing.lg),

          if (log.isNotEmpty) ...[
            Text('History', style: text.titleMedium),
            const SizedBox(height: AppSpacing.md),
            GlassCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  for (final e in log.reversed.take(14))
                    _HistoryRow(
                        entry: e,
                        last: e == log.reversed.take(14).last),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _TimeRow extends StatelessWidget {
  const _TimeRow(
      {required this.icon,
      required this.label,
      required this.value,
      required this.onTap});
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return InkWell(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, color: AppColors.taskYoga),
          const SizedBox(width: AppSpacing.md),
          Text(label, style: text.bodyLarge),
          const Spacer(),
          Text(value,
              style: text.titleMedium?.copyWith(color: AppColors.taskYoga)),
          const Icon(Icons.edit_rounded, size: 16, color: AppColors.textSecondary),
        ],
      ),
    );
  }
}

class _HistoryRow extends StatelessWidget {
  const _HistoryRow({required this.entry, required this.last});
  final SleepEntry entry;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final date = DateTime.fromMillisecondsSinceEpoch(entry.dateMillis);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg, vertical: AppSpacing.md),
          child: Row(
            children: [
              const Icon(Icons.nightlight_round, color: AppColors.taskYoga, size: 20),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${entry.hours.toStringAsFixed(1)}h sleep',
                        style: text.titleSmall),
                    Text(DateFormat('EEE, d MMM').format(date),
                        style: text.bodySmall
                            ?.copyWith(color: AppColors.textSecondary)),
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (int i = 0; i < 5; i++)
                    Icon(
                        i < entry.quality
                            ? Icons.star_rounded
                            : Icons.star_border_rounded,
                        size: 13,
                        color: AppColors.accent),
                ],
              ),
            ],
          ),
        ),
        if (!last) const Divider(height: 1, indent: 16, endIndent: 16),
      ],
    );
  }
}
