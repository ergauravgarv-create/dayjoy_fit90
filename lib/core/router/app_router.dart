import 'package:go_router/go_router.dart';

import '../../features/auth/otp_screen.dart';
import '../../features/auth/phone_login_screen.dart';
import '../../features/checkin/weekly_checkin_screen.dart';
import '../../features/checklist/checklist_screen.dart';
import '../../features/registration/registration_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/leaderboard/leaderboard_screen.dart';
import '../../features/onboarding/goal_plan_screen.dart';
import '../../features/onboarding/language_select_screen.dart';
import '../../features/onboarding/onboarding_screen.dart';
import '../../features/onboarding/transformation_intro_screen.dart';
import '../../features/profile/profile_screen.dart';
import '../../features/progress/progress_screen.dart';
import '../../features/shell/app_shell.dart';
import '../../features/splash/splash_screen.dart';
import '../../features/staff/admin/admin_dashboard.dart';
import '../../features/staff/coach/coach_dashboard.dart';
import '../../features/staff/doctor/doctor_dashboard.dart';
import '../constants/app_constants.dart';

/// Route path constants — reference these instead of raw strings.
abstract final class Routes {
  static const String splash = '/';
  static const String language = '/language';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String otp = '/otp';
  static const String register = '/register';
  static const String goalSetup = '/goal-setup';
  static const String transformationIntro = '/transformation-intro';
  static const String weeklyCheckin = '/weekly-checkin';

  static const String home = '/home';
  static const String checklist = '/checklist';
  static const String progress = '/progress';
  static const String leaderboard = '/leaderboard';
  static const String profile = '/profile';

  // Staff dashboards
  static const String coach = '/coach';
  static const String doctor = '/doctor';
  static const String admin = '/admin';

  /// The landing route for a given role after sign-in.
  static String forRole(UserRole role) => switch (role) {
        UserRole.participant => home,
        UserRole.coach => coach,
        UserRole.doctor => doctor,
        UserRole.admin => admin,
      };
}

final GoRouter appRouter = GoRouter(
  initialLocation: Routes.splash,
  routes: [
    GoRoute(
      path: Routes.splash,
      builder: (_, __) => const SplashScreen(),
    ),
    GoRoute(
      path: Routes.language,
      builder: (_, __) => const LanguageSelectScreen(),
    ),
    GoRoute(
      path: Routes.onboarding,
      builder: (_, __) => const OnboardingScreen(),
    ),
    GoRoute(
      path: Routes.login,
      builder: (_, __) => const PhoneLoginScreen(),
    ),
    GoRoute(
      path: Routes.otp,
      builder: (context, state) =>
          OtpScreen(mobile: state.extra as String? ?? ''),
    ),

    // Onboarding registration (new participant) + weekly check-in.
    GoRoute(
        path: Routes.register,
        builder: (_, __) => const RegistrationScreen()),
    GoRoute(
        path: Routes.goalSetup,
        builder: (_, __) => const GoalPlanScreen(onboarding: true)),
    GoRoute(
        path: Routes.transformationIntro,
        builder: (_, __) => const TransformationIntroScreen()),
    GoRoute(
        path: Routes.weeklyCheckin,
        builder: (_, __) => const WeeklyCheckInScreen()),

    // Staff dashboards (outside the participant bottom-nav shell).
    GoRoute(path: Routes.coach, builder: (_, __) => const CoachDashboard()),
    GoRoute(path: Routes.doctor, builder: (_, __) => const DoctorDashboard()),
    GoRoute(path: Routes.admin, builder: (_, __) => const AdminDashboard()),

    // Persistent bottom-nav shell wrapping the 5 main tabs.
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) =>
          AppShell(navigationShell: navigationShell),
      branches: [
        StatefulShellBranch(routes: [
          GoRoute(
            path: Routes.home,
            builder: (_, __) => const HomeScreen(),
          ),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(
            path: Routes.checklist,
            builder: (_, __) => const ChecklistScreen(),
          ),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(
            path: Routes.progress,
            builder: (_, __) => const ProgressScreen(),
          ),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(
            path: Routes.leaderboard,
            builder: (_, __) => const LeaderboardScreen(),
          ),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(
            path: Routes.profile,
            builder: (_, __) => const ProfileScreen(),
          ),
        ]),
      ],
    ),
  ],
);
