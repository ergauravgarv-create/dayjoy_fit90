/// App-wide constants for the 90-day challenge.
abstract final class AppConstants {
  static const String appName = 'Dayjoy Fit90';
  static const String tagline = 'Transform Yourself.\nOne Day at a Time.';

  static const int challengeDurationDays = 90;
  static const int dailyStepGoal = 10000;
  static const int weeklyCheckInInterval = 7;

  // Points per task (5 tasks x 20 = 100/day)
  static const int pointsPerTask = 20;
  static const int dailyPointsTotal = 100;

  static const String coachName = 'Ms. Sonali';
  static const String doctorName = 'Dr. Prachita';

  static const List<String> motivationalQuotes = [
    'Small steps every day lead to big changes every year.',
    'Discipline is choosing what you want most over what you want now.',
    'Your body can do it. It\'s your mind you need to convince.',
    'The only bad workout is the one that didn\'t happen.',
    'Progress, not perfection.',
    'Consistency is what transforms average into excellence.',
  ];
}

/// The three (plus admin) roles used for role-based access.
enum UserRole { participant, coach, doctor, admin }

/// The five mandatory daily tasks.
enum DailyTaskType {
  morningYoga,
  morningNutrition,
  fitnessActivity,
  dailySteps,
  nightNutrition,
}

extension DailyTaskTypeX on DailyTaskType {
  String get title => switch (this) {
        DailyTaskType.morningYoga => 'Morning Yoga',
        DailyTaskType.morningNutrition => 'Morning Nutrition',
        DailyTaskType.fitnessActivity => 'Fitness Activity',
        DailyTaskType.dailySteps => 'Daily Step Goal',
        DailyTaskType.nightNutrition => 'Night Nutrition',
      };

  String get subtitle => switch (this) {
        DailyTaskType.morningYoga => 'Capture your yoga session',
        DailyTaskType.morningNutrition =>
          '25g Ample Meal Shake + 10g Vital Protein',
        DailyTaskType.fitnessActivity => 'Gym, walk, run, cycle & more',
        DailyTaskType.dailySteps => '10,000 steps target',
        DailyTaskType.nightNutrition =>
          '25g Ample Meal Shake + 10g Vital Protein',
      };
}
