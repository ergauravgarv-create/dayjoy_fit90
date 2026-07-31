import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../data/models/leaderboard_entry.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../shared/widgets/glass_card.dart';
import '../../state/providers.dart';

class LeaderboardScreen extends ConsumerStatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  ConsumerState<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends ConsumerState<LeaderboardScreen> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final entries = ref.watch(leaderboardProvider);
    final TextTheme text = Theme.of(context).textTheme;
    final l = AppLocalizations.of(context);
    final tabs = [l.periodDaily, l.periodWeekly, l.periodMonthly, l.periodOverall];

    return Scaffold(
      appBar: AppBar(title: Text(l.leaderboardTitle)),
      body: Column(
        children: [
          // Period selector
          SizedBox(
            height: 44,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: AppSpacing.page,
              itemCount: tabs.length,
              separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
              itemBuilder: (context, i) => ChoiceChip(
                label: Text(tabs[i]),
                selected: _tab == i,
                labelStyle: TextStyle(
                  color: _tab == i ? Colors.white : AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
                onSelected: (_) => setState(() => _tab = i),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Podium (top 3)
          if (entries.length >= 3)
            Padding(
              padding: AppSpacing.page,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(child: _Podium(entry: entries[1], height: 90)),
                  Expanded(child: _Podium(entry: entries[0], height: 120)),
                  Expanded(child: _Podium(entry: entries[2], height: 74)),
                ],
              ),
            ),
          const SizedBox(height: AppSpacing.lg),

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
                          width: 28,
                          child: Text('#${e.rank}',
                              style: text.titleMedium?.copyWith(
                                  color: e.rank <= 3
                                      ? AppColors.accent
                                      : AppColors.textSecondary)),
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
                        Text('${e.points}',
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
}

class _Podium extends StatelessWidget {
  const _Podium({required this.entry, required this.height});
  final LeaderboardEntry entry;
  final double height;

  @override
  Widget build(BuildContext context) {
    final bool gold = entry.rank == 1;
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
          child: Text('#${entry.rank}',
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w800)),
        ),
      ],
    );
  }
}
