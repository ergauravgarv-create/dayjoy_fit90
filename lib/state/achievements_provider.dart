import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/app_colors.dart';
import 'measurements_provider.dart';
import 'prefs_provider.dart';
import 'progress_photos_provider.dart';
import 'providers.dart';

/// Broad grouping for the badge shelf.
enum AchievementCategory { streak, weight, milestone, activity, logging }

extension AchievementCategoryX on AchievementCategory {
  String get label => switch (this) {
        AchievementCategory.streak => 'Consistency',
        AchievementCategory.weight => 'Weight loss',
        AchievementCategory.milestone => 'Milestones',
        AchievementCategory.activity => 'Activity',
        AchievementCategory.logging => 'Tracking',
      };
}

/// A live snapshot of everything the badge catalog measures against.
class AchievementStats {
  const AchievementStats({
    required this.streak,
    required this.currentDay,
    required this.weightLostKg,
    required this.goalPct,
    required this.totalPoints,
    required this.steps,
    required this.completionPct,
    required this.photoCount,
    required this.measurementCount,
  });

  final int streak;
  final int currentDay;
  final double weightLostKg;
  final double goalPct; // 0..100 toward target weight
  final int totalPoints;
  final int steps; // today
  final double completionPct; // 0..100 of today's tasks
  final int photoCount;
  final int measurementCount;
}

/// Definition of a single badge. [value] pulls the measured quantity from a
/// [AchievementStats]; progress is `value / target`, earned when it reaches 1.
class AchievementDef {
  const AchievementDef({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.category,
    required this.target,
    required this.unit,
    required this.value,
    this.decimals = 0,
  });

  final String id;
  final String title;
  final String description;
  final IconData icon;
  final AchievementCategory category;
  final num target;
  final String unit;
  final double Function(AchievementStats) value;
  final int decimals;

  double progress(AchievementStats s) =>
      target == 0 ? 0 : (value(s) / target).clamp(0.0, 1.0);

  /// Short "3 / 7 days" style status for a locked badge.
  String status(AchievementStats s) {
    final v = value(s);
    final vStr = v.toStringAsFixed(decimals);
    final tStr = target.toStringAsFixed(target is int ? 0 : decimals);
    return '$vStr / $tStr $unit';
  }
}

/// The full badge catalog. Titles/descriptions are kept in English (like the
/// medical terms) so new badges don't require translating every locale.
final List<AchievementDef> kAchievements = [
  // --- Consistency (streak) -------------------------------------------------
  AchievementDef(
      id: 'streak3',
      title: 'Getting Started',
      description: 'Keep a 3-day streak',
      icon: Icons.spa_rounded,
      category: AchievementCategory.streak,
      target: 3,
      unit: 'days',
      value: (s) => s.streak.toDouble()),
  AchievementDef(
      id: 'streak7',
      title: 'On Fire',
      description: '7 days in a row',
      icon: Icons.local_fire_department_rounded,
      category: AchievementCategory.streak,
      target: 7,
      unit: 'days',
      value: (s) => s.streak.toDouble()),
  AchievementDef(
      id: 'streak15',
      title: 'Committed',
      description: '15-day streak',
      icon: Icons.whatshot_rounded,
      category: AchievementCategory.streak,
      target: 15,
      unit: 'days',
      value: (s) => s.streak.toDouble()),
  AchievementDef(
      id: 'streak30',
      title: 'Unstoppable',
      description: '30-day streak',
      icon: Icons.bolt_rounded,
      category: AchievementCategory.streak,
      target: 30,
      unit: 'days',
      value: (s) => s.streak.toDouble()),
  AchievementDef(
      id: 'streak60',
      title: 'Iron Will',
      description: '60-day streak',
      icon: Icons.military_tech_rounded,
      category: AchievementCategory.streak,
      target: 60,
      unit: 'days',
      value: (s) => s.streak.toDouble()),
  AchievementDef(
      id: 'streak90',
      title: '90-Day Champion',
      description: 'Full 90-day streak',
      icon: Icons.workspace_premium_rounded,
      category: AchievementCategory.streak,
      target: 90,
      unit: 'days',
      value: (s) => s.streak.toDouble()),

  // --- Weight loss ----------------------------------------------------------
  AchievementDef(
      id: 'lose1',
      title: 'First Kilo',
      description: 'Lose your first 1 kg',
      icon: Icons.trending_down_rounded,
      category: AchievementCategory.weight,
      target: 1,
      unit: 'kg',
      decimals: 1,
      value: (s) => s.weightLostKg),
  AchievementDef(
      id: 'lose3',
      title: 'Trimming Down',
      description: 'Lose 3 kg',
      icon: Icons.trending_down_rounded,
      category: AchievementCategory.weight,
      target: 3,
      unit: 'kg',
      decimals: 1,
      value: (s) => s.weightLostKg),
  AchievementDef(
      id: 'lose5',
      title: 'Transformation Hero',
      description: 'Lose 5 kg',
      icon: Icons.auto_awesome_rounded,
      category: AchievementCategory.weight,
      target: 5,
      unit: 'kg',
      decimals: 1,
      value: (s) => s.weightLostKg),
  AchievementDef(
      id: 'lose10',
      title: 'Major Milestone',
      description: 'Lose 10 kg',
      icon: Icons.star_rounded,
      category: AchievementCategory.weight,
      target: 10,
      unit: 'kg',
      decimals: 1,
      value: (s) => s.weightLostKg),
  AchievementDef(
      id: 'halfwayGoal',
      title: 'Halfway There',
      description: 'Reach 50% of your goal',
      icon: Icons.flag_rounded,
      category: AchievementCategory.weight,
      target: 50,
      unit: '%',
      value: (s) => s.goalPct),
  AchievementDef(
      id: 'goalCrusher',
      title: 'Goal Crusher',
      description: 'Hit your target weight',
      icon: Icons.emoji_events_rounded,
      category: AchievementCategory.weight,
      target: 100,
      unit: '%',
      value: (s) => s.goalPct),

  // --- Milestones (days / points) ------------------------------------------
  AchievementDef(
      id: 'firstWeek',
      title: 'First Week Done',
      description: 'Complete day 7 of the challenge',
      icon: Icons.calendar_today_rounded,
      category: AchievementCategory.milestone,
      target: 7,
      unit: 'days',
      value: (s) => s.currentDay.toDouble()),
  AchievementDef(
      id: 'midChallenge',
      title: 'Over the Hump',
      description: 'Reach day 45',
      icon: Icons.hiking_rounded,
      category: AchievementCategory.milestone,
      target: 45,
      unit: 'days',
      value: (s) => s.currentDay.toDouble()),
  AchievementDef(
      id: 'finisher',
      title: 'Finisher',
      description: 'Reach day 90',
      icon: Icons.sports_score_rounded,
      category: AchievementCategory.milestone,
      target: 90,
      unit: 'days',
      value: (s) => s.currentDay.toDouble()),
  AchievementDef(
      id: 'points1000',
      title: 'Point Collector',
      description: 'Earn 1,000 points',
      icon: Icons.stars_rounded,
      category: AchievementCategory.milestone,
      target: 1000,
      unit: 'pts',
      value: (s) => s.totalPoints.toDouble()),
  AchievementDef(
      id: 'points5000',
      title: 'Point Master',
      description: 'Earn 5,000 points',
      icon: Icons.diamond_rounded,
      category: AchievementCategory.milestone,
      target: 5000,
      unit: 'pts',
      value: (s) => s.totalPoints.toDouble()),

  // --- Activity -------------------------------------------------------------
  AchievementDef(
      id: 'steps10k',
      title: '10K Steps',
      description: 'Walk 10,000 steps in a day',
      icon: Icons.directions_walk_rounded,
      category: AchievementCategory.activity,
      target: 10000,
      unit: 'steps',
      value: (s) => s.steps.toDouble()),
  AchievementDef(
      id: 'perfectDay',
      title: 'Perfect Day',
      description: 'Complete all of today\'s tasks',
      icon: Icons.check_circle_rounded,
      category: AchievementCategory.activity,
      target: 100,
      unit: '%',
      value: (s) => s.completionPct),

  // --- Tracking (logging) ---------------------------------------------------
  AchievementDef(
      id: 'firstPhoto',
      title: 'Say Cheese',
      description: 'Add your first progress photo',
      icon: Icons.photo_camera_rounded,
      category: AchievementCategory.logging,
      target: 1,
      unit: 'photos',
      value: (s) => s.photoCount.toDouble()),
  AchievementDef(
      id: 'photos5',
      title: 'Progress Pics',
      description: 'Add 5 progress photos',
      icon: Icons.collections_rounded,
      category: AchievementCategory.logging,
      target: 5,
      unit: 'photos',
      value: (s) => s.photoCount.toDouble()),
  AchievementDef(
      id: 'firstWeighIn',
      title: 'First Check-in',
      description: 'Log your first measurement',
      icon: Icons.monitor_weight_rounded,
      category: AchievementCategory.logging,
      target: 1,
      unit: 'logs',
      value: (s) => s.measurementCount.toDouble()),
  AchievementDef(
      id: 'weighIns5',
      title: 'Consistent Tracker',
      description: 'Log 5 measurements',
      icon: Icons.insights_rounded,
      category: AchievementCategory.logging,
      target: 5,
      unit: 'logs',
      value: (s) => s.measurementCount.toDouble()),
];

/// Colour accent for each category chip / section.
Color achievementColor(AchievementCategory c) => switch (c) {
      AchievementCategory.streak => AppColors.orange,
      AchievementCategory.weight => AppColors.primary,
      AchievementCategory.milestone => AppColors.taskYoga,
      AchievementCategory.activity => AppColors.taskSteps,
      AchievementCategory.logging => AppColors.info,
    };

/// Live stats snapshot assembled from the rest of the app state.
final achievementStatsProvider = Provider<AchievementStats>((ref) {
  final p = ref.watch(participantProvider);
  return AchievementStats(
    streak: p?.streak ?? 0,
    currentDay: p?.currentDay ?? 1,
    weightLostKg: p?.weightLostKg ?? 0,
    goalPct: (p?.goalProgress ?? 0) * 100,
    totalPoints: p?.totalPoints ?? 0,
    steps: ref.watch(stepsProvider),
    completionPct: ref.watch(completionProvider) * 100,
    photoCount: ref.watch(progressPhotosProvider).length,
    measurementCount: ref.watch(measurementsProvider).length,
  );
});

/// Persisted set of earned badge ids → the moment they unlocked. Once earned a
/// badge stays earned even if the streak later resets.
final earnedBadgesProvider =
    NotifierProvider<EarnedBadgesController, Map<String, DateTime>>(
        EarnedBadgesController.new);

class EarnedBadgesController extends Notifier<Map<String, DateTime>> {
  static const String _key = 'earned_badges';

  @override
  Map<String, DateTime> build() {
    final raw = ref.watch(sharedPreferencesProvider).getString(_key);
    if (raw == null || raw.isEmpty) return const {};
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return map.map((k, v) => MapEntry(
          k, DateTime.fromMillisecondsSinceEpoch((v as num).toInt())));
    } catch (_) {
      return const {};
    }
  }

  /// Persist any [ids] not already earned. Returns the ids newly added (so the
  /// UI can celebrate them). Does not remove previously earned badges.
  List<String> award(Iterable<String> ids) {
    final added = <String>[];
    final next = Map<String, DateTime>.from(state);
    final now = DateTime.now();
    for (final id in ids) {
      if (!next.containsKey(id)) {
        next[id] = now;
        added.add(id);
      }
    }
    if (added.isEmpty) return const [];
    state = next;
    ref.read(sharedPreferencesProvider).setString(
        _key,
        jsonEncode(
            next.map((k, v) => MapEntry(k, v.millisecondsSinceEpoch))));
    return added;
  }
}

/// A badge plus its live progress and earned state.
class AchievementView {
  const AchievementView(
      {required this.def, required this.progress, required this.earned});
  final AchievementDef def;
  final double progress;
  final bool earned;
}

/// The catalog resolved against live stats + the persisted earned set.
final achievementsProvider = Provider<List<AchievementView>>((ref) {
  final stats = ref.watch(achievementStatsProvider);
  final earned = ref.watch(earnedBadgesProvider);
  return [
    for (final d in kAchievements)
      AchievementView(
        def: d,
        progress: d.progress(stats),
        earned: earned.containsKey(d.id) || d.progress(stats) >= 1.0,
      ),
  ];
});

/// Convenience: how many badges are earned right now.
final earnedCountProvider = Provider<int>(
    (ref) => ref.watch(achievementsProvider).where((a) => a.earned).length);
