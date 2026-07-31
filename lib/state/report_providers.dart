import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/weekly_report.dart';
import 'providers.dart';
import 'repository_providers.dart';

/// Generated weekly reports for the signed-in participant (oldest → newest).
final weeklyReportsProvider =
    StreamProvider.autoDispose<List<WeeklyReport>>((ref) {
  final uid = ref.watch(authUidProvider) ?? 'demo-user';
  return ref.watch(weeklyReportRepositoryProvider).watchAll(uid);
});
