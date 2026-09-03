// Central constants — mirror the Flutter app's AppConstants so scoring rules
// stay in lock-step across client and server.

export const CONFIG = {
  timezone: 'Asia/Kolkata', // challenge is India-based (distributor, +91)
  region: 'asia-south1', // Mumbai
  stepGoal: 10000,
  // Scoring mirrors the Flutter client: 5 activity tasks x 16 + the daily water
  // task (20) = 100/day.
  pointsPerTask: 16,
  tasksPerDay: 5,
  waterTaskPoints: 20,
  waterTaskGlasses: 12, // 12 x 250 ml = 3 L to earn the water task
  dailyPointsTotal: 100,
  challengeDurationDays: 90,
  leaderboardSize: 100,
  streakBadges: [7, 15, 30, 60, 90],
} as const;

// The five daily task keys (order matters only for display).
export const TASK_KEYS = [
  'morningYoga',
  'morningNutrition',
  'fitnessActivity',
  'dailySteps',
  'nightNutrition',
] as const;

export type TaskKey = (typeof TASK_KEYS)[number];

export const BADGE_LABELS: Record<string, string> = {
  streak7: '7 Day Streak',
  streak15: '15 Day Streak',
  streak30: '30 Day Streak',
  streak60: '60 Day Streak',
  streak90: '90 Day Champion',
  perfectWeek: 'Perfect Week',
};
