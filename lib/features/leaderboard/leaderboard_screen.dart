import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../data/models/leaderboard_entry.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../shared/widgets/glass_card.dart';
import '../../state/providers.dart';
import '../onboarding/transformation_intro_screen.dart';
import '../rewards/rewards_screen.dart';

class LeaderboardScreen extends ConsumerStatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  ConsumerState<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends ConsumerState<LeaderboardScreen> {
  int _scope = 0; // 0 = All India, 1 = My City, 2 = Get inspired
  int _period = 0; // 0 = All-time, 1 = This week

  int _pts(LeaderboardEntry e) => _period == 1 ? e.weeklyPoints : e.points;

  /// Rank-movement indicator (▲/▼ vs last week, or a dash for no change).
  Widget _movement(int previousRank, int rank) {
    if (previousRank == 0) return const SizedBox(height: 14);
    final int delta = previousRank - rank; // positive = climbed
    if (delta == 0) {
      return const Icon(Icons.remove_rounded,
          size: 12, color: AppColors.textSecondary);
    }
    final bool up = delta > 0;
    final Color c = up ? AppColors.success : AppColors.error;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(up ? Icons.arrow_drop_up_rounded : Icons.arrow_drop_down_rounded,
            size: 16, color: c),
        Text('${delta.abs()}',
            style: TextStyle(
                fontSize: 10, fontWeight: FontWeight.w700, color: c)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final allEntries = ref.watch(leaderboardProvider);
    final String? myCity = ref.watch(participantProvider)?.city;
    final TextTheme text = Theme.of(context).textTheme;
    final l = AppLocalizations.of(context);

    // Rank everyone by the selected period, then optionally filter by city.
    final List<LeaderboardEntry> ranked = [...allEntries]
      ..sort((a, b) => _pts(b).compareTo(_pts(a)));
    final List<LeaderboardEntry> entries = (_scope == 1 && myCity != null)
        ? ranked.where((e) => e.city == myCity).toList()
        : ranked;

    // Current user's standing across everyone (for the percentile banner).
    final int userIdx = ranked.indexWhere((e) => e.isCurrentUser);
    final int? topPct = userIdx >= 0 && ranked.isNotEmpty
        ? (((userIdx + 1) / ranked.length) * 100).ceil()
        : null;

    return Scaffold(
      appBar: AppBar(
        title: Text(l.leaderboardTitle),
        actions: [
          IconButton(
            tooltip: 'Reward points',
            icon: const Icon(Icons.stars_rounded),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const RewardsScreen()),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: AppSpacing.md),

          // Scope: All India / My City / Get inspired
          Padding(
            padding: AppSpacing.page,
            child: Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                _ScopeChip(
                  label: 'All India',
                  selected: _scope == 0,
                  onTap: () => setState(() => _scope = 0),
                ),
                if (myCity != null)
                  _ScopeChip(
                    label: myCity,
                    icon: Icons.location_on_rounded,
                    selected: _scope == 1,
                    onTap: () => setState(() => _scope = 1),
                  ),
                _ScopeChip(
                  label: 'Get inspired',
                  icon: Icons.auto_awesome_rounded,
                  selected: _scope == 2,
                  onTap: () => setState(() => _scope = 2),
                ),
              ],
            ),
          ),

          // All-time / This week toggle (ranking scopes only)
          if (_scope != 2) ...[
            const SizedBox(height: AppSpacing.md),
            Padding(
              padding: AppSpacing.page,
              child: SegmentedButton<int>(
                segments: const [
                  ButtonSegment(
                      value: 0,
                      label: Text('All-time'),
                      icon: Icon(Icons.emoji_events_rounded, size: 16)),
                  ButtonSegment(
                      value: 1,
                      label: Text('This week'),
                      icon: Icon(Icons.date_range_rounded, size: 16)),
                ],
                selected: {_period},
                onSelectionChanged: (s) =>
                    setState(() => _period = s.first),
              ),
            ),
            if (topPct != null) ...[
              const SizedBox(height: AppSpacing.md),
              Padding(
                padding: AppSpacing.page,
                child: GlassCard(
                  gradient: AppColors.goldGradient,
                  child: Row(
                    children: [
                      const Icon(Icons.trending_up_rounded,
                          color: Colors.white, size: 30),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Text(
                          'You\'re in the top $topPct% ${_period == 1 ? 'this week' : 'overall'}',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w800),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
          const SizedBox(height: AppSpacing.md),

          if (_scope != 2 && entries.isEmpty)
            Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Text('No one here yet in $myCity.',
                  style: text.bodyMedium),
            ),

          // Podium (top 3) — ranking scopes only
          if (_scope != 2 && entries.length >= 3)
            Padding(
              padding: AppSpacing.page,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                      child: _Podium(entry: entries[1], rank: 2, height: 90)),
                  Expanded(
                      child: _Podium(entry: entries[0], rank: 1, height: 120)),
                  Expanded(
                      child: _Podium(entry: entries[2], rank: 3, height: 74)),
                ],
              ),
            ),
          const SizedBox(height: AppSpacing.lg),

          if (_scope == 2)
            Expanded(child: _inspiredList(context))
          else
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg, 0, AppSpacing.lg, 100),
                itemCount: entries.length,
                itemBuilder: (context, i) {
                final LeaderboardEntry e = entries[i];
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: GlassCard(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg, vertical: AppSpacing.md),
                    gradient: e.isCurrentUser
                        ? LinearGradient(colors: [
                            AppColors.primary.withOpacity(0.12),
                            AppColors.secondary.withOpacity(0.12),
                          ])
                        : null,
                    child: Row(
                      children: [
                        SizedBox(
                          width: 34,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('#${i + 1}',
                                  style: text.titleMedium?.copyWith(
                                      color: i < 3
                                          ? AppColors.accent
                                          : AppColors.textSecondary)),
                              _movement(e.previousRank, i + 1),
                            ],
                          ),
                        ),
                        CircleAvatar(
                          radius: 20,
                          backgroundColor:
                              AppColors.primary.withOpacity(0.15),
                          child: Text(e.name.characters.first,
                              style: const TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w700)),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(e.name, style: text.titleSmall),
                              Row(
                                children: [
                                  const Icon(
                                      Icons.local_fire_department_rounded,
                                      size: 13,
                                      color: AppColors.accent),
                                  Text(' ${e.streak} · ${e.city}',
                                      style: text.bodySmall),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Text('${_pts(e)}',
                            style: text.titleMedium
                                ?.copyWith(color: AppColors.primary)),
                        Text(' ${l.ptsSuffix}', style: text.bodySmall),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// "Get inspired": the same transformation-story banners shown at signup.
  Widget _inspiredList(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return ListView(
      padding:
          const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, 100),
      children: [
        Text('Real transformations from our members',
            style: text.titleMedium),
        const SizedBox(height: AppSpacing.md),
        for (final path in kTransformationIntroBanners)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: ClipRRect(
              borderRadius: AppRadius.card,
              child: Image.asset(
                path,
                fit: BoxFit.fitWidth,
                width: double.infinity,
                errorBuilder: (_, __, ___) => Container(
                  height: 160,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceMuted,
                    borderRadius: AppRadius.card,
                  ),
                  alignment: Alignment.center,
                  child: Text('Transformation story', style: text.bodyMedium),
                ),
              ),
            ),
          ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Pictures are for inspiration only and may not reflect individual '
          'results.',
          style: text.bodySmall?.copyWith(color: AppColors.textSecondary),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _ScopeChip extends StatelessWidget {
  const _ScopeChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary
              : AppColors.primary.withOpacity(0.10),
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon,
                  size: 15,
                  color: selected ? Colors.white : AppColors.primary),
              const SizedBox(width: 4),
            ],
            Text(label,
                style: TextStyle(
                    color: selected ? Colors.white : AppColors.primary,
                    fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}

class _Podium extends StatelessWidget {
  const _Podium(
      {required this.entry, required this.rank, required this.height});
  final LeaderboardEntry entry;
  final int rank;
  final double height;

  @override
  Widget build(BuildContext context) {
    final bool gold = rank == 1;
    return Column(
      children: [
        CircleAvatar(
          radius: gold ? 30 : 24,
          backgroundColor: AppColors.primary.withOpacity(0.15),
          child: Text(entry.name.characters.first,
              style: const TextStyle(
                  color: AppColors.primary, fontWeight: FontWeight.w800)),
        ),
        const SizedBox(height: 6),
        Text(entry.name.split(' ').first,
            style: Theme.of(context).textTheme.bodySmall,
            overflow: TextOverflow.ellipsis),
        const SizedBox(height: 6),
        Container(
          height: height,
          margin: const EdgeInsets.symmetric(horizontal: 6),
          decoration: BoxDecoration(
            gradient: gold
                ? AppColors.goldGradient
                : LinearGradient(colors: [
                    AppColors.primary.withOpacity(0.6),
                    AppColors.secondary.withOpacity(0.6),
                  ]),
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(12)),
          ),
          alignment: Alignment.topCenter,
          padding: const EdgeInsets.only(top: 8),
          child: Text('#$rank',
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w800)),
        ),
      ],
    );
  }
}
