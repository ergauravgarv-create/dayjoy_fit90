import '../models/weekly_checkin.dart';

/// Reads & writes weekly check-ins.
abstract interface class WeeklyCheckInRepository {
  Stream<List<WeeklyCheckIn>> watchAll(String uid);

  /// Best-effort synchronous latest check-in.
  WeeklyCheckIn? latestSnapshot(String uid);

  Future<void> submit(String uid, WeeklyCheckIn checkin);
}
