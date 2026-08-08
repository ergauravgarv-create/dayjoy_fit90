import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../appointments/book_consult_chooser_screen.dart';
import '../appointments/my_appointments_screen.dart';
import '../badges/badges_gallery_screen.dart';
import '../referral/referral_screen.dart';
import '../subscription/subscription_screen.dart';
import '../checkin/weekly_checkin_screen.dart';
import '../coach_chat/coach_chat_screen.dart';
import '../community/community_screen.dart';
import '../fasting/fasting_screen.dart';
import '../health/bmi_report_screen.dart';
import '../health/connect_health_screen.dart';
import '../meals/food_diary_screen.dart';
import '../meals/meal_tracker_screen.dart';
import '../meals/my_diet_plan_screen.dart';
import '../mindfulness/mindfulness_screen.dart';
import '../onboarding/goal_plan_screen.dart';
import '../progress/progress_photos_screen.dart';
import '../reminders/reminders_screen.dart';
import '../rewards/rewards_screen.dart';
import '../sleep/sleep_screen.dart';
import '../streak/streak_screen.dart';
import '../supplements/skin_analysis_screen.dart';
import '../supplements/supplement_consult_screen.dart';
import '../water/water_screen.dart';
import '../workouts/video_library_screen.dart';
import '../workouts/workout_library_screen.dart';

/// One tool in the Explore hub.
class ExploreItem {
  const ExploreItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.keywords,
    required this.builder,
    this.premium = true,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final String keywords; // extra search terms
  final Widget Function() builder;

  /// Whether an active subscription is required. Free tools (BMI, referral,
  /// buying a plan) set this false; everything else is premium.
  final bool premium;

  bool matches(String q) {
    if (q.isEmpty) return true;
    final s = '$title $subtitle $keywords'.toLowerCase();
    return s.contains(q.toLowerCase());
  }
}

/// Every tool in the app, grouped by section. Home shows a few; Explore shows
/// all of these.
final Map<String, List<ExploreItem>> exploreSections = {
  'Track': [
    ExploreItem(
      title: 'Meal tracker',
      subtitle: 'Log meals & calories',
      icon: Icons.restaurant_rounded,
      color: AppColors.orange,
      keywords: 'food diary nutrition protein',
      builder: () => const MealTrackerScreen(),
    ),
    ExploreItem(
      title: 'My diet plan',
      subtitle: 'Doctor-approved plan',
      icon: Icons.restaurant_menu_rounded,
      color: AppColors.primary,
      keywords: 'diet chart food',
      builder: () => const MyDietPlanScreen(),
    ),
    ExploreItem(
      title: 'Food diary',
      subtitle: 'Meals & photos timeline',
      icon: Icons.menu_book_rounded,
      color: AppColors.orange,
      keywords: 'food diary meals photos timeline history',
      builder: () => const FoodDiaryScreen(),
    ),
    ExploreItem(
      title: 'Water tracker',
      subtitle: 'Hydration & cups',
      icon: Icons.water_drop_rounded,
      color: AppColors.info,
      keywords: 'water hydration drink cups goal',
      builder: () => const WaterScreen(),
    ),
    ExploreItem(
      title: 'Fasting tracker',
      subtitle: '16:8, 18:6, OMAD',
      icon: Icons.timer_rounded,
      color: AppColors.taskYoga,
      keywords: 'intermittent fasting countdown',
      builder: () => const FastingScreen(),
    ),
    ExploreItem(
      title: 'Sleep tracker',
      subtitle: 'Log & rate your sleep',
      icon: Icons.bedtime_rounded,
      color: AppColors.taskYoga,
      keywords: 'sleep bedtime rest quality',
      builder: () => const SleepScreen(),
    ),
    ExploreItem(
      title: 'BMI report',
      subtitle: 'Your health report',
      icon: Icons.monitor_heart_rounded,
      color: AppColors.info,
      keywords: 'bmi weight health',
      builder: () => const BmiReportScreen(),
      premium: false,
    ),
    ExploreItem(
      title: 'Progress photos',
      subtitle: 'Before & after',
      icon: Icons.photo_camera_rounded,
      color: AppColors.accent,
      keywords: 'photos transformation gallery',
      builder: () => const ProgressPhotosScreen(),
    ),
    ExploreItem(
      title: 'Weekly check-in',
      subtitle: 'Log weight & photos',
      icon: Icons.event_note_rounded,
      color: AppColors.accent,
      keywords: 'checkin weekly weight waist',
      builder: () => const WeeklyCheckInScreen(),
    ),
    ExploreItem(
      title: 'Connect health',
      subtitle: 'Steps, sleep & calories',
      icon: Icons.favorite_rounded,
      color: AppColors.error,
      keywords: 'health connect steps sleep calories',
      builder: () => const ConnectHealthScreen(),
    ),
  ],
  'Move': [
    ExploreItem(
      title: 'Workout library',
      subtitle: 'Guided routines',
      icon: Icons.fitness_center_rounded,
      color: AppColors.taskSteps,
      keywords: 'exercise cardio strength yoga core workout',
      builder: () => const WorkoutLibraryScreen(),
    ),
    ExploreItem(
      title: 'Workout videos',
      subtitle: 'Follow-along videos',
      icon: Icons.smart_display_rounded,
      color: AppColors.error,
      keywords: 'youtube videos exercise',
      builder: () => const VideoLibraryScreen(),
    ),
    ExploreItem(
      title: 'Mindfulness',
      subtitle: 'Breathing & calm',
      icon: Icons.self_improvement_rounded,
      color: AppColors.taskYoga,
      keywords: 'meditation breathing relax mindfulness',
      builder: () => const MindfulnessScreen(),
    ),
  ],
  'Motivate': [
    ExploreItem(
      title: 'Streak & motivation',
      subtitle: 'Heatmap & freezes',
      icon: Icons.local_fire_department_rounded,
      color: AppColors.orange,
      keywords: 'streak heatmap freeze motivation',
      builder: () => const StreakScreen(),
    ),
    ExploreItem(
      title: 'Community',
      subtitle: 'Wins & challenges',
      icon: Icons.groups_rounded,
      color: AppColors.secondary,
      keywords: 'feed community challenges bonus',
      builder: () => const CommunityScreen(),
    ),
    ExploreItem(
      title: 'Reward points',
      subtitle: 'Milestones & history',
      icon: Icons.stars_rounded,
      color: AppColors.accent,
      keywords: 'rewards points milestones ledger',
      builder: () => const RewardsScreen(),
    ),
    ExploreItem(
      title: 'Achievements',
      subtitle: 'Your badges',
      icon: Icons.workspace_premium_rounded,
      color: AppColors.accent,
      keywords: 'badges achievements',
      builder: () => const BadgesGalleryScreen(),
    ),
  ],
  'Plan & support': [
    ExploreItem(
      title: 'Dayjoy Fit90 Premium',
      subtitle: 'Plans & benefits',
      icon: Icons.workspace_premium_rounded,
      color: AppColors.orange,
      keywords: 'subscription premium plan price gst upgrade buy membership',
      builder: () => const SubscriptionScreen(),
      premium: false,
    ),
    ExploreItem(
      title: 'Refer & earn 5%',
      subtitle: 'Code, wallet & payouts',
      icon: Icons.card_giftcard_rounded,
      color: AppColors.secondary,
      keywords: 'referral refer earn wallet code invite friends 5% payout',
      builder: () => const ReferralScreen(),
      premium: false,
    ),
    ExploreItem(
      title: 'Consult a specialist',
      subtitle: 'Video or voice call',
      icon: Icons.video_call_rounded,
      color: AppColors.info,
      keywords:
          'consult doctor trainer video call voice appointment booking specialist',
      builder: () => const BookConsultChooserScreen(),
    ),
    ExploreItem(
      title: 'My consultations',
      subtitle: 'Bookings & join call',
      icon: Icons.event_note_rounded,
      color: AppColors.primary,
      keywords: 'my consultations appointments join call video voice booking',
      builder: () => const MyAppointmentsScreen(),
    ),
    ExploreItem(
      title: 'Goal & plan',
      subtitle: 'Target & timeline',
      icon: Icons.flag_rounded,
      color: AppColors.accent,
      keywords: 'goal plan target pace',
      builder: () => const GoalPlanScreen(),
    ),
    ExploreItem(
      title: 'Reminders',
      subtitle: 'Daily schedule',
      icon: Icons.notifications_active_rounded,
      color: AppColors.primary,
      keywords: 'reminders schedule notifications',
      builder: () => const RemindersScreen(),
    ),
    ExploreItem(
      title: 'Consultant chat',
      subtitle: 'Message your coach',
      icon: Icons.chat_bubble_rounded,
      color: AppColors.secondary,
      keywords: 'chat coach consultant message',
      builder: () => const CoachChatScreen(),
    ),
    ExploreItem(
      title: 'Supplement consult',
      subtitle: 'Dayjoy products for your health',
      icon: Icons.medication_liquid_rounded,
      color: AppColors.info,
      keywords: 'supplement products health issue doctor recommendation',
      builder: () => const SupplementConsultScreen(),
    ),
    ExploreItem(
      title: 'AI skin analysis',
      subtitle: 'Face check → skincare routine',
      icon: Icons.face_retouching_natural_rounded,
      color: AppColors.taskYoga,
      keywords: 'skin face acne wrinkles dark circles skincare cleanser serum moisturizer',
      builder: () => const SkinAnalysisScreen(),
    ),
  ],
};

List<ExploreItem> get allExploreItems =>
    exploreSections.values.expand((e) => e).toList();
