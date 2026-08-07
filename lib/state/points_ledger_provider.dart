import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'community_provider.dart';
import 'prefs_provider.dart';

/// A single point-earning event.
class LedgerEntry {
  const LedgerEntry(
      {required this.date, required this.source, required this.points});
  final DateTime date;
  final String source;
  final int points;

  Map<String, dynamic> toJson() => {
        'date': date.millisecondsSinceEpoch,
        'source': source,
        'points': points,
      };

  factory LedgerEntry.fromJson(Map<String, dynamic> j) => LedgerEntry(
        date: DateTime.fromMillisecondsSinceEpoch(
            (j['date'] as num?)?.toInt() ?? 0),
        source: j['source'] as String? ?? 'Points',
        points: (j['points'] as num?)?.toInt() ?? 0,
      );
}

/// Manually logged point events (e.g. completing all daily tasks), persisted.
final pointsLedgerProvider =
    NotifierProvider<PointsLedgerController, List<LedgerEntry>>(
        PointsLedgerController.new);

class PointsLedgerController extends Notifier<List<LedgerEntry>> {
  static const String _key = 'points_ledger';

  @override
  List<LedgerEntry> build() {
    final raw = ref.watch(sharedPreferencesProvider).getString(_key);
    if (raw == null || raw.isEmpty) return const [];
    try {
      return (jsonDecode(raw) as List)
          .map((e) => LedgerEntry.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return const [];
    }
  }

  void add(String source, int points) {
    if (points <= 0) return;
    state = [
      LedgerEntry(date: DateTime.now(), source: source, points: points),
      ...state,
    ];
    ref
        .read(sharedPreferencesProvider)
        .setString(_key, jsonEncode(state.map((e) => e.toJson()).toList()));
  }
}

/// The full ledger: manual entries merged with claimed-challenge bonuses
/// (which carry their own real timestamps), newest first.
final combinedLedgerProvider = Provider<List<LedgerEntry>>((ref) {
  final manual = ref.watch(pointsLedgerProvider);
  final claimed = ref.watch(claimedChallengesProvider); // id -> claimedAt

  final entries = <LedgerEntry>[...manual];
  for (final e in claimed.entries) {
    final matches = kChallenges.where((c) => c.id == e.key);
    if (matches.isEmpty) continue;
    final c = matches.first;
    entries.add(LedgerEntry(
        date: e.value,
        source: 'Challenge: ${c.title}',
        points: c.bonusPoints));
  }
  entries.sort((a, b) => b.date.compareTo(a.date));
  return entries;
});

/// Sum of all ledgered points (bonus + logged), for a "points earned in-app"
/// figure separate from the seeded profile total.
final ledgerTotalProvider = Provider<int>(
    (ref) => ref.watch(combinedLedgerProvider).fold(0, (s, e) => s + e.points));
