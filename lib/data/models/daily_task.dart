import '../../core/constants/app_constants.dart';

/// One of the five daily checklist tasks with its completion state.
class DailyTask {
  const DailyTask({
    required this.type,
    this.completed = false,
    this.completedAt,
    this.proofUrl,
  });

  final DailyTaskType type;
  final bool completed;
  final DateTime? completedAt;
  final String? proofUrl;

  int get points => completed ? AppConstants.pointsPerTask : 0;

  DailyTask copyWith({
    bool? completed,
    DateTime? completedAt,
    String? proofUrl,
  }) {
    return DailyTask(
      type: type,
      completed: completed ?? this.completed,
      completedAt: completedAt ?? this.completedAt,
      proofUrl: proofUrl ?? this.proofUrl,
    );
  }
}

/// A single day's checklist (the `dailySubmissions/{uid}_{day}` document).
class DailyChecklist {
  const DailyChecklist({
    required this.day,
    required this.date,
    required this.tasks,
  });

  final int day;
  final DateTime date;
  final List<DailyTask> tasks;

  int get completedCount => tasks.where((t) => t.completed).length;

  double get completionPercent =>
      tasks.isEmpty ? 0.0 : completedCount / tasks.length;

  bool get allComplete => completedCount == tasks.length && tasks.isNotEmpty;

  int get pointsEarned => tasks.fold(0, (sum, t) => sum + t.points);

  DailyChecklist toggle(DailyTaskType type, bool completed) {
    return DailyChecklist(
      day: day,
      date: date,
      tasks: [
        for (final t in tasks)
          if (t.type == type)
            t.copyWith(
              completed: completed,
              completedAt: completed ? DateTime.now() : null,
            )
          else
            t,
      ],
    );
  }

  factory DailyChecklist.freshFor(int day, DateTime date) => DailyChecklist(
        day: day,
        date: date,
        tasks: [
          for (final type in DailyTaskType.values) DailyTask(type: type),
        ],
      );
}
