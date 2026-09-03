import 'package:dayjoy_fit90/data/models/daily_task.dart';
import 'package:dayjoy_fit90/core/constants/app_constants.dart';
import 'package:dayjoy_fit90/data/models/participant.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DailyChecklist', () {
    test('starts empty with five tasks', () {
      final c = DailyChecklist.freshFor(1, DateTime(2026, 1, 1));
      expect(c.tasks.length, 5);
      expect(c.completedCount, 0);
      expect(c.allComplete, isFalse);
    });

    test('completing all tasks awards full points', () {
      var c = DailyChecklist.freshFor(1, DateTime(2026, 1, 1));
      for (final t in DailyTaskType.values) {
        c = c.toggle(t, true);
      }
      expect(c.allComplete, isTrue);
      // The 5 checklist tasks award pointsPerTask each; the separate daily
      // water task contributes the remaining points to reach the daily total.
      expect(c.pointsEarned,
          DailyTaskType.values.length * AppConstants.pointsPerTask);
      expect(c.pointsEarned + AppConstants.waterTaskPoints,
          AppConstants.dailyPointsTotal);
      expect(c.completionPercent, 1.0);
    });
  });

  group('Participant', () {
    test('computes BMI, weight lost and goal progress', () {
      final p = Participant(
        id: 'x',
        name: 'Test',
        mobile: '+91 0000000000',
        age: 30,
        gender: 'Male',
        heightCm: 170,
        startWeightKg: 90,
        currentWeightKg: 81,
        targetWeightKg: 72,
        city: 'Pune',
      );
      expect(p.weightLostKg, 9);
      expect(p.totalToLoseKg, 18);
      expect(p.goalProgress, closeTo(0.5, 0.001));
      expect(p.bmi, closeTo(28.03, 0.1));
    });
  });
}
