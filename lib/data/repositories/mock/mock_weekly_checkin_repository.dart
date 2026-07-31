import 'dart:async';

import '../../models/weekly_checkin.dart';
import '../weekly_checkin_repository.dart';

class MockWeeklyCheckInRepository implements WeeklyCheckInRepository {
  final Map<String, List<WeeklyCheckIn>> _store = {};
  final StreamController<void> _tick = StreamController<void>.broadcast();

  List<WeeklyCheckIn> _list(String uid) => _store.putIfAbsent(uid, () => []);

  @override
  Stream<List<WeeklyCheckIn>> watchAll(String uid) {
    scheduleMicrotask(() => _tick.add(null));
    return _tick.stream.map((_) => List<WeeklyCheckIn>.of(_list(uid)));
  }

  @override
  WeeklyCheckIn? latestSnapshot(String uid) {
    final list = _list(uid);
    return list.isEmpty ? null : list.last;
  }

  @override
  Future<void> submit(String uid, WeeklyCheckIn checkin) async {
    final list = _list(uid);
    // Replace an existing entry for the same week, else append.
    final i = list.indexWhere((c) => c.weekNumber == checkin.weekNumber);
    if (i >= 0) {
      list[i] = checkin;
    } else {
      list.add(checkin);
    }
    _tick.add(null);
  }
}
