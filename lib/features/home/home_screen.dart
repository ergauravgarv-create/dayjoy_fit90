import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_constants.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../shared/widgets/glass_card.dart';
import '../../shared/widgets/progress_ring.dart';
import '../../shared/widgets/section_header.dart';
import '../../shared/widgets/stat_tile.dart';
import '../../shared/widgets/weight_line_chart.dart';
import '../../state/engagement_providers.dart';
import '../../state/meal_provider.dart';
import '../../state/providers.dart';
import '../explore/explore_screen.dart';
import '../health/bmi_report_screen.dart';
import '../health/connect_health_screen.dart';
import '../meals/meal_tracker_screen.dart';
import '../meals/my_diet_plan_screen.dart';
import '../notifications/notifications_screen.dart';
import 'home_banner_carousel.dart';

Color _bmiColor(String category) => switch (category) {
      'Underweight' => AppColors.info,
      'Normal' => AppColors.success,
      'Overweight' => AppColors.orange,
      'Obese' => AppColors.error,
      _ => AppColors.textSecondary,
    };

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final participant = ref.watch(participantProvider);
    final double completion = ref.watch(completionProvider);
    final int streak = ref.watch(streakProvider);
    final int steps = ref.watch(stepsProvider);
    final bool stepsConnected = ref.watch(stepsConnectedProvider);
    final int? sleepMin = ref.watch(sleepMinutesProvider);
    final int? activeCal = ref.watch(activeCaloriesProvider);
    final String quote = ref.watch(dailyQuoteProvider);
    final leaderboard = ref.watch(leaderboardProvider);
    final int unread = ref.watch(unreadCountProvider);
    final int mealKcal = MealTotals.of(ref.watch(mealLogProvider)).kcal;

    if (participant == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final int rank =
        leaderboard.indexWhere((e) => e.isCurrentUser).clamp(0, 999) + 1;
    final TextTheme text = Theme.of(context).textTheme;
    final l = AppLocalizations.of(context);

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async =>
              Future<void>.delayed(const Duration(milliseconds: 600)),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, 100),
            children: [
              // Greeting header
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l.homeGreeting, style: text.bodyMedium),
                        Text(participant.name.split(' ').first,
                            style: text.headlineSmall),
                      ],
                    ),
                  ),
                  _NotificationBell(
                    unread: unread,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                          builder: (_) => const NotificationsScreen()),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  _StreakPill(streak: streak),
                  const SizedBox(width: AppSpacing.sm),
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: AppColors.primary.withOpacity(0.15),
                    child: Text(
                      participant.name.characters.first,
                      style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),

              // Sliding promotional banners (editable — see kHomeBanners)
              const HomeBannerCarousel(),
              const SizedBox(height: AppSpacing.xl),

              // Hero progress card
              GlassCard(
                gradient: AppColors.brandGradient,
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Row(
                  children: [
                    ProgressRing(
                      progress: completion,
                      size: 120,
                      strokeWidth: 12,
                      gradient: const LinearGradient(
                          colors: [Colors.white, Color(0xFFEFFFF8)]),
                      center: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('${(completion * 100).round()}%',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 26,
                                  fontWeight: FontWeight.w800)),
                          Text(l.homeTodayLabel,
                              style: const TextStyle(color: Colors.white70)),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.lg),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                              l.homeDayOfTotal(participant.currentDay,
                                  AppConstants.challengeDurationDays),
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700)),
                          const SizedBox(height: 4),
                          Text(l.homeDaysToGo(participant.remainingDays),
                              style: const TextStyle(color: Colors.white70)),
                          const SizedBox(height: AppSpacing.md),
                          FilledButton(
                            style: FilledButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: AppColors.primary,
                              minimumSize: const Size.fromHeight(46),
                            ),
                            onPressed: () => context.go(Routes.checklist),
                            child: Text(l.homeStartChallenge),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Stat grid
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: AppSpacing.md,
                crossAxisSpacing: AppSpacing.md,
                childAspectRatio: 1.45,
                children: [
                  StatTile(
                    icon: Icons.monitor_weight_rounded,
                    value: '${participant.currentWeightKg} kg',
                    label: l.homeCurrentWeight,
                    color: AppColors.primary,
                  ),
                  StatTile(
                    icon: Icons.flag_rounded,
                    value: '${participant.targetWeightKg} kg',
                    label: l.homeTargetWeight,
                    color: AppColors.accent,
                  ),
                  StatTile(
                    icon: Icons.directions_walk_rounded,
                    value: stepsConnected ? '$steps' : 'Connect',
                    label: l.homeStepsToday,
                    color: AppColors.taskSteps,
                    onTap: stepsConnected
                        ? null
                        : () => Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => const ConnectHealthScreen(),
                              ),
                            ),
                  ),
                  StatTile(
                    icon: Icons.emoji_events_rounded,
                    value: '#$rank',
                    label: l.homeLeaderboardRank,
                    color: AppColors.taskYoga,
                  ),
                  StatTile(
                    icon: Icons.local_fire_department_rounded,
                    value: activeCal != null
                        ? '$activeCal'
                        : (stepsConnected ? '—' : 'Connect'),
                    label: 'Calories burned',
                    color: AppColors.orange,
                    onTap: stepsConnected
                        ? null
                        : () => Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => const ConnectHealthScreen(),
                              ),
                            ),
                  ),
                  StatTile(
                    icon: Icons.bedtime_rounded,
                    value: sleepMin != null
                        ? '${sleepMin ~/ 60}h ${sleepMin % 60}m'
                        : (stepsConnected ? '—' : 'Connect'),
                    label: 'Sleep last night',
                    color: AppColors.info,
                    onTap: stepsConnected
                        ? null
                        : () => Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => const ConnectHealthScreen(),
                              ),
                            ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),

              // BMI report card
              GlassCard(
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                      builder: (_) => const BmiReportScreen()),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: _bmiColor(participant.bmiCategory)
                          .withOpacity(0.15),
                      child: Icon(Icons.monitor_heart_rounded,
                          color: _bmiColor(participant.bmiCategory)),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Your BMI  ${participant.bmi.toStringAsFixed(1)}',
                              style: text.titleMedium),
                          Text(
                              '${participant.bmiCategory} · tap for your health report',
                              style: text.bodySmall),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // Meal tracker CTA
              GlassCard(
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                      builder: (_) => const MealTrackerScreen()),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: AppColors.orange.withOpacity(0.15),
                      child: const Icon(Icons.restaurant_rounded,
                          color: AppColors.orange),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Log your meals', style: text.titleMedium),
                          Text('$mealKcal / ${participant.dailyCalorieGoal} kcal today',
                              style: text.bodySmall),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // Diet plan CTA (doctor-approved)
              GlassCard(
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                      builder: (_) => const MyDietPlanScreen()),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: AppColors.primary.withOpacity(0.12),
                      child: const Icon(Icons.restaurant_menu_rounded,
                          color: AppColors.primary),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('My diet plan', style: text.titleMedium),
                          Text('Approved by your doctor · tap to view & log',
                              style: text.bodySmall),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // Explore all tools
              GlassCard(
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                      builder: (_) => const ExploreScreen()),
                ),
                gradient: AppColors.mixGradient,
                child: Row(
                  children: [
                    const CircleAvatar(
                      backgroundColor: Colors.white24,
                      child:
                          Icon(Icons.grid_view_rounded, color: Colors.white),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text('Explore all tools',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800)),
                          Text(
                              'Workouts, mindfulness, community, fasting & more',
                              style: TextStyle(
                                  color: Colors.white70, fontSize: 12)),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded,
                        color: Colors.white),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),

              // Weekly check-in CTA
              GlassCard(
                onTap: () => context.push(Routes.weeklyCheckin),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: AppColors.accent.withOpacity(0.15),
                      child: const Icon(Icons.event_note_rounded,
                          color: AppColors.accent),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(l.homeWeeklyCheckin, style: text.titleMedium),
                          Text(l.homeWeeklyCheckinSub, style: text.bodySmall),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),

              // Weight trend
              SectionHeader(title: l.homeWeightTrend),
              const SizedBox(height: AppSpacing.md),
              GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text('-${participant.weightLostKg.toStringAsFixed(1)} kg',
                            style: text.titleLarge
                                ?.copyWith(color: AppColors.success)),
                        const SizedBox(width: 6),
                        Text(l.homeLostSoFar, style: text.bodySmall),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    WeightLineChart(values: ref.watch(weightSeriesProvider)),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),

              // Daily quote
              GlassCard(
                gradient: AppColors.goldGradient,
                child: Row(
                  children: [
                    const Icon(Icons.format_quote_rounded,
                        color: Colors.white, size: 32),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Text(quote,
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              height: 1.4)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Upcoming consultation
              GlassCard(
                onTap: () {},
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: AppColors.info.withOpacity(0.15),
                      child: const Icon(Icons.medical_services_rounded,
                          color: AppColors.info),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(l.homeUpcomingConsult(AppConstants.doctorName),
                              style: text.titleMedium),
                          Text(l.homeConsultWhen, style: text.bodySmall),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NotificationBell extends StatelessWidget {
  const _NotificationBell({required this.unread, required this.onTap});
  final int unread;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          onPressed: onTap,
          icon: const Icon(Icons.notifications_none_rounded),
        ),
        if (unread > 0)
          Positioned(
            right: 6,
            top: 6,
            child: Container(
              padding: const EdgeInsets.all(4),
              constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
              decoration: const BoxDecoration(
                  color: AppColors.error, shape: BoxShape.circle),
              child: Text(
                unread > 9 ? '9+' : '$unread',
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w800),
              ),
            ),
          ),
      ],
    );
  }
}

class _StreakPill extends StatelessWidget {
  const _StreakPill({required this.streak});
  final int streak;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.accent.withOpacity(0.15),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        children: [
          const Icon(Icons.local_fire_department_rounded,
              color: AppColors.accent, size: 18),
          const SizedBox(width: 4),
          Text('$streak',
              style: const TextStyle(
                  color: AppColors.accent, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}
