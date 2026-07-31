import 'dart:async';

import '../../../core/constants/app_constants.dart';
import '../../models/daily_task.dart';
import '../checklist_repository.dart';

class MockChecklistRepository implements ChecklistRepository {
  final Map<int, DailyChecklist> _store = {};
  final Map<int, StreamController<DailyChecklist>> _controllers = {};

  DailyChecklist _ensure(int day) =>
      _store.putIfAbsent(day, () => DailyChecklist.freshFor(day, DateTime.now()));

  StreamController<DailyChecklist> _controller(int day) =>
      _controllers.putIfAbsent(day, () => StreamController<DailyChecklist>.broadcast());

  @override
  Stream<DailyChecklist> watchToday(String uid, int day) {
    final c = _controller(day);
    scheduleMicrotask(() => c.add(_ensure(day)));
    return c.stream;
  }

  @override
  DailyChecklist? currentSnapshot(String uid, int day) => _ensure(day);

  @override
  Future<void> setTask(
    String uid,
    int day,
    DailyTaskType type, {
    required bool completed,
    String? proofUrl,
    int? verifiedSteps,
    String? verificationMethod,
  }) async {
    final updated = _ensure(day).toggle(type, completed);
    _store[day] = updated;
    _controller(day).add(updated);
  }
}
