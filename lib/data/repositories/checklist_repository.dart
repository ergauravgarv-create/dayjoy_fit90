import '../../core/constants/app_constants.dart';
import '../models/daily_task.dart';

/// Reads & writes a participant's daily checklist. In Firebase mode each write
/// lands in `participants/{uid}/days/{yyyy-MM-dd}` and triggers the
/// `awardDailyPoints` Cloud Function (points/streak/badges are server-side).
abstract interface class ChecklistRepository {
  /// Live checklist for [day].
  Stream<DailyChecklist> watchToday(String uid, int day);

  /// Best-effort synchronous cache for [day].
  DailyChecklist? currentSnapshot(String uid, int day);

  /// Persist a single task's completion (+ optional proof / step data). The
  /// client never writes points — the function computes them.
  Future<void> setTask(
    String uid,
    int day,
    DailyTaskType type, {
    required bool completed,
    String? proofUrl,
    int? verifiedSteps,
    String? verificationMethod,
  });
}
