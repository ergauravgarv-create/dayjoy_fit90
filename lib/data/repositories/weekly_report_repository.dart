import '../models/weekly_report.dart';

/// Reads generated weekly reports (server-produced).
abstract interface class WeeklyReportRepository {
  Stream<List<WeeklyReport>> watchAll(String uid);
  List<WeeklyReport>? currentSnapshot(String uid);
}
