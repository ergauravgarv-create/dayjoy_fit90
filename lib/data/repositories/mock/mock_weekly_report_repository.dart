import '../../mock/mock_data.dart';
import '../../models/weekly_report.dart';
import '../weekly_report_repository.dart';

class MockWeeklyReportRepository implements WeeklyReportRepository {
  @override
  Stream<List<WeeklyReport>> watchAll(String uid) =>
      Stream<List<WeeklyReport>>.value(MockData.weeklyReports);

  @override
  List<WeeklyReport>? currentSnapshot(String uid) => MockData.weeklyReports;
}
