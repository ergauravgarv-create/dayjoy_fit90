/// Pure trend maths for the progress analytics page. No Flutter/Riverpod deps
/// so it can be unit-tested and reused.

class TrendAnalytics {
  const TrendAnalytics({
    required this.weeklyChangeKg,
    required this.weeklyRateKg,
    required this.projectedGoalDate,
    required this.daysToGoal,
    required this.bmiSeries,
    required this.goalReached,
    required this.pace,
  });

  /// Change over the last ~7 days (negative = weight lost). Estimated from the
  /// average rate when there aren't two logs a week apart.
  final double weeklyChangeKg;

  /// Average loss per week since the start (positive = losing).
  final double weeklyRateKg;

  /// Projected date the target weight is reached at the current pace, or null
  /// if already reached / not currently losing.
  final DateTime? projectedGoalDate;
  final int? daysToGoal;

  /// BMI value for each point of the supplied weight series.
  final List<double> bmiSeries;

  final bool goalReached;

  /// 'ahead' | 'onTrack' | 'slow' | 'none' — vs the linear 90-day plan.
  final String pace;
}

class WeightLog {
  const WeightLog(this.date, this.weight);
  final DateTime date;
  final double weight;
}

TrendAnalytics computeTrends({
  required double startWeight,
  required double currentWeight,
  required double targetWeight,
  required double heightCm,
  required DateTime? startDate,
  required int currentDay,
  required List<WeightLog> logs, // chronological
  required List<double> weightSeries,
  required DateTime now,
}) {
  final double h = heightCm / 100.0;
  double bmiOf(double w) => h > 0 ? w / (h * h) : 0;
  final List<double> bmiSeries = weightSeries.map(bmiOf).toList();

  final int daysElapsed = startDate != null
      ? now.difference(startDate).inDays.clamp(1, 100000)
      : (currentDay - 1).clamp(1, 100000);

  final double totalLost = startWeight - currentWeight; // + = lost
  final double ratePerDay = totalLost / daysElapsed; // kg/day
  final double weeklyRate = ratePerDay * 7;

  // Weekly change from actual logs when two are ~a week apart.
  double? weeklyChange;
  if (logs.length >= 2) {
    final latest = logs.last;
    final cutoff = latest.date.subtract(const Duration(days: 7));
    WeightLog? refLog;
    for (final l in logs) {
      if (l.date.isBefore(latest.date) &&
          (l.date.isBefore(cutoff) || l.date.isAtSameMomentAs(cutoff))) {
        refLog = l; // keep the latest log on/before the cutoff
      }
    }
    refLog ??= logs.first;
    final int spanDays = latest.date.difference(refLog.date).inDays;
    if (spanDays > 0) {
      weeklyChange = (latest.weight - refLog.weight) / spanDays * 7;
    }
  }
  weeklyChange ??= -weeklyRate; // estimate; loss is negative

  final double remaining = currentWeight - targetWeight; // + = still to lose
  final bool goalReached = remaining <= 0;
  DateTime? projectedDate;
  int? daysToGoal;
  if (!goalReached && ratePerDay > 0.001) {
    daysToGoal = (remaining / ratePerDay).ceil();
    projectedDate = now.add(Duration(days: daysToGoal));
  }

  // Pace vs a straight-line 90-day plan.
  final double totalToLose = startWeight - targetWeight;
  String pace = 'none';
  if (totalToLose > 0) {
    final double expectedByNow =
        totalToLose * (daysElapsed / 90).clamp(0.0, 1.0);
    if (totalLost >= expectedByNow * 1.05) {
      pace = 'ahead';
    } else if (totalLost >= expectedByNow * 0.85) {
      pace = 'onTrack';
    } else {
      pace = 'slow';
    }
  }

  return TrendAnalytics(
    weeklyChangeKg: weeklyChange,
    weeklyRateKg: weeklyRate,
    projectedGoalDate: projectedDate,
    daysToGoal: daysToGoal,
    bmiSeries: bmiSeries,
    goalReached: goalReached,
    pace: pace,
  );
}
