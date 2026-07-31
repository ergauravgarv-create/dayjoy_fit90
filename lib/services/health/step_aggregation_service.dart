/// Pure, testable step-reconciliation logic. No plugins — so it's covered by
/// unit tests for the tricky cases: timezone/day boundaries, avoiding
/// double-counting phone + watch, and never lowering a historical value just
/// because a sync is delayed.
class StepAggregationService {
  const StepAggregationService();

  /// Local day key (yyyy-MM-dd) for [instant] in the device's local zone.
  String localDateKey(DateTime instant) {
    final DateTime local = instant.toLocal();
    final String y = local.year.toString().padLeft(4, '0');
    final String m = local.month.toString().padLeft(2, '0');
    final String d = local.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  bool isSameLocalDay(DateTime a, DateTime b) =>
      localDateKey(a) == localDateKey(b);

  /// Health Connect / HealthKit both expose an *aggregated* total that already
  /// merges phone + watch. Prefer that. Only fall back to summing raw
  /// per-source readings when no aggregate is available — and even then, guard
  /// against a watch that mirrors the phone by taking the max of overlapping
  /// sources rather than blindly summing.
  int resolveTodaySteps({
    int? aggregatedTotal,
    Map<String, int> perSource = const {},
  }) {
    if (aggregatedTotal != null) return aggregatedTotal;
    if (perSource.isEmpty) return 0;
    // Heuristic de-dup: if two sources are within 3% of each other they're
    // almost certainly the same steps mirrored — count once (the larger).
    final List<int> values = perSource.values.toList()..sort();
    int total = 0;
    int? prev;
    for (final int v in values) {
      if (prev != null && prev > 0 && (v - prev).abs() / prev < 0.03) {
        total = total - prev + v; // replace mirrored value with the larger
      } else {
        total += v;
      }
      prev = v;
    }
    return total;
  }

  /// Reconcile a freshly-read value against the value already stored for the
  /// day. Never decreases the stored total (sync delay must not "un-complete"
  /// a goal); returns the value to persist.
  int reconcile({required int stored, required int incoming}) =>
      incoming > stored ? incoming : stored;

  bool goalReached(int steps, int goal) => steps >= goal;

  double progress(int steps, int goal) =>
      goal <= 0 ? 0.0 : (steps / goal).clamp(0.0, 1.0);
}
