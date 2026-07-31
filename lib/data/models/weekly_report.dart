/// A generated weekly report. Mirrors the Cloud Function output at
/// `participants/{uid}/weeklyReports/{week-NN}` (see functions/src/reports).
class WeeklyReport {
  const WeeklyReport({
    required this.weekNumber,
    required this.startDate,
    required this.endDate,
    required this.daysCompleted,
    required this.daysInWeek,
    required this.completionRate,
    required this.totalSteps,
    required this.activeCalories,
    required this.workoutMinutes,
    this.startWeightKg,
    this.endWeightKg,
    this.weightChangeKg,
    this.bmi,
    this.bmiChange,
    this.pointsEarned = 0,
  });

  final int weekNumber;
  final String startDate;
  final String endDate;
  final int daysCompleted;
  final int daysInWeek;
  final double completionRate; // 0..1
  final int totalSteps;
  final int activeCalories;
  final int workoutMinutes;
  final double? startWeightKg;
  final double? endWeightKg;
  final double? weightChangeKg;
  final double? bmi;
  final double? bmiChange;
  final int pointsEarned;

  factory WeeklyReport.fromJson(Map<String, dynamic> j) => WeeklyReport(
        weekNumber: (j['weekNumber'] as num?)?.toInt() ?? 1,
        startDate: j['startDate'] as String? ?? '',
        endDate: j['endDate'] as String? ?? '',
        daysCompleted: (j['daysCompleted'] as num?)?.toInt() ?? 0,
        daysInWeek: (j['daysInWeek'] as num?)?.toInt() ?? 7,
        completionRate: (j['completionRate'] as num?)?.toDouble() ?? 0,
        totalSteps: (j['totalSteps'] as num?)?.toInt() ?? 0,
        activeCalories: (j['activeCalories'] as num?)?.toInt() ?? 0,
        workoutMinutes: (j['workoutMinutes'] as num?)?.toInt() ?? 0,
        startWeightKg: (j['startWeightKg'] as num?)?.toDouble(),
        endWeightKg: (j['endWeightKg'] as num?)?.toDouble(),
        weightChangeKg: (j['weightChangeKg'] as num?)?.toDouble(),
        bmi: (j['bmi'] as num?)?.toDouble(),
        bmiChange: (j['bmiChange'] as num?)?.toDouble(),
        pointsEarned: (j['pointsEarned'] as num?)?.toInt() ?? 0,
      );
}
