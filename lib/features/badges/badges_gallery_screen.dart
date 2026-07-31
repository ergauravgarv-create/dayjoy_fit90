import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../data/models/participant.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../shared/widgets/glass_card.dart';
import '../../state/engagement_providers.dart';
import '../../state/providers.dart';

class _BadgeDef {
  const _BadgeDef(this.id, this.icon, this.progressOf);
  final String id;
  final IconData icon;
  final double Function(Participant) progressOf;
}

double _clamp01(num v) => v.clamp(0.0, 1.0).toDouble();

final List<_BadgeDef> _catalog = [
  _BadgeDef('streak7', Icons.local_fire_department_rounded,
      (p) => _clamp01(p.streak / 7)),
  _BadgeDef('perfectWeek', Icons.verified_rounded,
      (p) => _clamp01(p.currentDay / 7)),
  _BadgeDef('streak15', Icons.whatshot_rounded, (p) => _clamp01(p.streak / 15)),
  _BadgeDef('transformationHero', Icons.auto_awesome_rounded,
      (p) => _clamp01(p.weightLostKg / 5)),
  _BadgeDef('streak30', Icons.bolt_rounded, (p) => _clamp01(p.streak / 30)),
  _BadgeDef('consistencyKing', Icons.emoji_events_rounded,
      (p) => _clamp01(p.streak / 30)),
  _BadgeDef('streak60', Icons.military_tech_rounded,
      (p) => _clamp01(p.streak / 60)),
  _BadgeDef('streak90', Icons.workspace_premium_rounded,
      (p) => _clamp01(p.streak / 90)),
];

String _badgeLabel(AppLocalizations l, String id) => switch (id) {
      'streak7' => l.badgeStreak7,
      'perfectWeek' => l.badgePerfectWeek,
      'streak15' => l.badgeStreak15,
      'transformationHero' => l.badgeTransformationHero,
      'streak30' => l.badgeStreak30,
      'consistencyKing' => l.badgeConsistencyKing,
      'streak60' => l.badgeStreak60,
      _ => l.badgeStreak90,
    };

String _badgeDesc(AppLocalizations l, String id) => switch (id) {
      'streak7' => l.badgeStreak7Desc,
      'perfectWeek' => l.badgePerfectWeekDesc,
      'streak15' => l.badgeStreak15Desc,
      'transformationHero' => l.badgeTransformationHeroDesc,
      'streak30' => l.badgeStreak30Desc,
      'consistencyKing' => l.badgeConsistencyKingDesc,
      'streak60' => l.badgeStreak60Desc,
      _ => l.badgeStreak90Desc,
    };

class BadgesGalleryScreen extends ConsumerWidget {
  const BadgesGalleryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final participant = ref.watch(participantProvider);
    final earnedAsync = ref.watch(badgesProvider);
    final earnedIds =
        earnedAsync.valueOrNull?.map((b) => b.id).toSet() ?? <String>{};
    final l = AppLocalizations.of(context);

    if (participant == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    bool isEarned(_BadgeDef d) =>
        earnedIds.contains(d.id) || d.progressOf(participant) >= 1.0;

    final earnedCount = _catalog.where(isEarned).length;
    final TextTheme text = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: Text(l.badgesTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.xxl),
        children: [
          const SizedBox(height: AppSpacing.md),
          GlassCard(
            gradient: AppColors.goldGradient,
            child: Row(
              children: [
                const Icon(Icons.emoji_events_rounded,
                    color: Colors.white, size: 40),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l.badgesUnlocked(earnedCount, _catalog.length),
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w800)),
                      Text(l.badgesKeepStreak,
                          style: TextStyle(
                              color: Colors.white.withOpacity(0.9))),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: AppSpacing.md,
            crossAxisSpacing: AppSpacing.md,
            childAspectRatio: 0.92,
            children: [
              for (final d in _catalog)
                _BadgeCard(
                  def: d,
                  earned: isEarned(d),
                  progress: d.progressOf(participant),
                  text: text,
                  l: l,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BadgeCard extends StatelessWidget {
  const _BadgeCard({
    required this.def,
    required this.earned,
    required this.progress,
    required this.text,
    required this.l,
  });

  final _BadgeDef def;
  final bool earned;
  final double progress;
  final TextTheme text;
  final AppLocalizations l;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 66,
            height: 66,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: earned ? AppColors.goldGradient : null,
              color: earned ? null : AppColors.surfaceMuted,
            ),
            child: Icon(
              earned ? def.icon : Icons.lock_rounded,
              color: earned ? Colors.white : AppColors.textSecondary,
              size: 30,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(_badgeLabel(l, def.id),
              style: text.titleSmall, textAlign: TextAlign.center),
          const SizedBox(height: 2),
          Text(_badgeDesc(l, def.id),
              style: text.bodySmall,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis),
          const SizedBox(height: AppSpacing.sm),
          if (earned)
            Text(l.badgeUnlocked,
                style: text.bodySmall?.copyWith(
                    color: AppColors.success, fontWeight: FontWeight.w700))
          else
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.pill),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 6,
                backgroundColor: AppColors.primary.withOpacity(0.10),
                valueColor: const AlwaysStoppedAnimation(AppColors.accent),
              ),
            ),
        ],
      ),
    );
  }
}
