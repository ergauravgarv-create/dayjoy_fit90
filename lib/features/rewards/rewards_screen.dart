import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../shared/widgets/glass_card.dart';
import '../../state/points_ledger_provider.dart';
import '../../state/providers.dart';
import '../badges/badges_gallery_screen.dart';

enum _MilestoneKind { points, streak }

class _Milestone {
  const _Milestone({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.kind,
    required this.threshold,
  });
  final String title;
  final String subtitle;
  final IconData icon;
  final _MilestoneKind kind;
  final int threshold;
}

/// Points & streak milestones. These recognise effort only — they carry no
/// cash, voucher or discount. What the top performers receive after the 90-day
/// challenge is decided by the Dayjoy management.
const List<_Milestone> _milestones = [
  _Milestone(
    title: 'Bronze — 500 points',
    subtitle: 'You\'re building a solid habit',
    icon: Icons.military_tech_rounded,
    kind: _MilestoneKind.points,
    threshold: 500,
  ),
  _Milestone(
    title: 'Week Warrior',
    subtitle: 'Hold a 7-day streak',
    icon: Icons.local_fire_department_rounded,
    kind: _MilestoneKind.streak,
    threshold: 7,
  ),
  _Milestone(
    title: 'Silver — 1,000 points',
    subtitle: 'Consistency is paying off',
    icon: Icons.military_tech_rounded,
    kind: _MilestoneKind.points,
    threshold: 1000,
  ),
  _Milestone(
    title: 'Gold — 2,000 points',
    subtitle: 'You\'re among the committed',
    icon: Icons.workspace_premium_rounded,
    kind: _MilestoneKind.points,
    threshold: 2000,
  ),
  _Milestone(
    title: 'Month Master',
    subtitle: 'Reach a 30-day streak',
    icon: Icons.emoji_events_rounded,
    kind: _MilestoneKind.streak,
    threshold: 30,
  ),
  _Milestone(
    title: 'Diamond — 5,000 points',
    subtitle: 'Top-tier dedication',
    icon: Icons.diamond_rounded,
    kind: _MilestoneKind.points,
    threshold: 5000,
  ),
];

class RewardsScreen extends ConsumerWidget {
  const RewardsScreen({super.key});

  int _progressValue(_Milestone m, int points, int streak) =>
      m.kind == _MilestoneKind.points ? points : streak;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final participant = ref.watch(participantProvider);
    final int points = participant?.totalPoints ?? 0;
    final int streak = ref.watch(streakProvider);
    final List<LedgerEntry> ledger = ref.watch(combinedLedgerProvider);
    final TextTheme text = Theme.of(context).textTheme;

    final int achieved = _milestones
        .where((m) => _progressValue(m, points, streak) >= m.threshold)
        .length;

    final locked = _milestones
        .where((m) => _progressValue(m, points, streak) < m.threshold)
        .toList()
      ..sort((a, b) =>
          (a.threshold - _progressValue(a, points, streak)) -
          (b.threshold - _progressValue(b, points, streak)));
    final _Milestone? next = locked.isNotEmpty ? locked.first : null;

    return Scaffold(
      appBar: AppBar(title: const Text('Reward Points')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, 40),
        children: [
          GlassCard(
            gradient: AppColors.brandGradient,
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _HeaderStat(value: '$points', label: 'points'),
                    _divider(),
                    _HeaderStat(value: '$streak', label: 'day streak'),
                    _divider(),
                    _HeaderStat(
                        value: '$achieved/${_milestones.length}',
                        label: 'milestones'),
                  ],
                ),
                if (next != null) ...[
                  const SizedBox(height: AppSpacing.lg),
                  Builder(builder: (context) {
                    final int have = _progressValue(next, points, streak);
                    final int gap = next.threshold - have;
                    final String unit =
                        next.kind == _MilestoneKind.points ? 'points' : 'days';
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('$gap $unit to "${next.title}"',
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600)),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                          child: LinearProgressIndicator(
                            value: (have / next.threshold).clamp(0.0, 1.0),
                            minHeight: 8,
                            backgroundColor: Colors.white24,
                            valueColor:
                                const AlwaysStoppedAnimation(Colors.white),
                          ),
                        ),
                      ],
                    );
                  }),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          Text('Your milestones', style: text.titleMedium),
          const SizedBox(height: AppSpacing.md),
          for (final m in _milestones)
            _MilestoneTile(
              milestone: m,
              value: _progressValue(m, points, streak),
            ),

          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Text('Points history', style: text.titleMedium),
              const Spacer(),
              if (ledger.isNotEmpty)
                Text('+${ledger.fold(0, (s, e) => s + e.points)} earned in-app',
                    style: text.bodySmall
                        ?.copyWith(color: AppColors.textSecondary)),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          if (ledger.isEmpty)
            GlassCard(
              child: Text(
                'Complete your daily tasks and weekly challenges to start '
                'earning points — your history will appear here.',
                style: text.bodySmall
                    ?.copyWith(color: AppColors.textSecondary),
              ),
            )
          else
            GlassCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  for (final e in ledger.take(20))
                    _LedgerRow(
                        entry: e,
                        last: e == ledger.take(20).last),
                ],
              ),
            ),

          const SizedBox(height: AppSpacing.xl),
          GlassCard(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                  builder: (_) => const BadgesGalleryScreen()),
            ),
            child: Row(
              children: [
                const Icon(Icons.workspace_premium_outlined,
                    color: AppColors.accent),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text('View your badges', style: text.titleMedium),
                ),
                const Icon(Icons.chevron_right_rounded),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Points recognise your effort and daily consistency. Rewards for the '
            'top performers after the 90-day challenge are decided by the Dayjoy '
            'management.',
            style: text.bodySmall?.copyWith(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _divider() => Container(width: 1, height: 34, color: Colors.white24);
}

class _HeaderStat extends StatelessWidget {
  const _HeaderStat({required this.value, required this.label});
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(value,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w800)),
          const SizedBox(height: 2),
          Text(label,
              style: const TextStyle(color: Colors.white70, fontSize: 12)),
        ],
      ),
    );
  }
}

class _LedgerRow extends StatelessWidget {
  const _LedgerRow({required this.entry, required this.last});
  final LedgerEntry entry;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final bool isChallenge = entry.source.startsWith('Challenge');
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg, vertical: AppSpacing.md),
          child: Row(
            children: [
              Icon(
                  isChallenge
                      ? Icons.flag_rounded
                      : Icons.check_circle_rounded,
                  color: isChallenge ? AppColors.accent : AppColors.success,
                  size: 20),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(entry.source,
                        style: text.titleSmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    Text(DateFormat('d MMM, h:mm a').format(entry.date),
                        style: text.bodySmall
                            ?.copyWith(color: AppColors.textSecondary)),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text('+${entry.points}',
                  style: text.titleMedium
                      ?.copyWith(color: AppColors.primary)),
            ],
          ),
        ),
        if (!last)
          const Divider(height: 1, indent: 16, endIndent: 16),
      ],
    );
  }
}

class _MilestoneTile extends StatelessWidget {
  const _MilestoneTile({required this.milestone, required this.value});
  final _Milestone milestone;
  final int value;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final bool achieved = value >= milestone.threshold;
    final double progress = (value / milestone.threshold).clamp(0.0, 1.0);
    final Color tint = achieved ? AppColors.success : AppColors.primary;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: GlassCard(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: tint.withOpacity(0.14),
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Icon(milestone.icon, color: tint),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(milestone.title, style: text.titleSmall),
                  Text(milestone.subtitle, style: text.bodySmall),
                  if (!achieved) ...[
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 6,
                        backgroundColor: AppColors.primary.withOpacity(0.10),
                        valueColor:
                            const AlwaysStoppedAnimation(AppColors.primary),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                        '$value / ${milestone.threshold} '
                        '${milestone.kind == _MilestoneKind.points ? 'pts' : 'days'}',
                        style: text.bodySmall
                            ?.copyWith(color: AppColors.textSecondary)),
                  ],
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            if (achieved)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.check_rounded,
                        size: 14, color: AppColors.success),
                    const SizedBox(width: 3),
                    Text('Achieved',
                        style: text.bodySmall?.copyWith(
                            color: AppColors.success,
                            fontWeight: FontWeight.w700)),
                  ],
                ),
              )
            else
              const Icon(Icons.lock_outline_rounded,
                  color: AppColors.textSecondary, size: 20),
          ],
        ),
      ),
    );
  }
}
