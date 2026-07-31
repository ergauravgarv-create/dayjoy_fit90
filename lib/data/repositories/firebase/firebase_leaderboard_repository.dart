// REAL IMPLEMENTATION — enable with cloud_firestore. Not compiled in mock mode.
//
// ignore_for_file: depend_on_referenced_packages, uri_does_not_exist
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/leaderboard_entry.dart';
import '../leaderboard_repository.dart';

class FirebaseLeaderboardRepository implements LeaderboardRepository {
  FirebaseLeaderboardRepository({this.currentUid});

  /// When set, the matching row is flagged `isCurrentUser` for highlighting.
  final String? currentUid;

  final CollectionReference<Map<String, dynamic>> _col =
      FirebaseFirestore.instance.collection('leaderboards');
  final Map<String, List<LeaderboardEntry>> _cache = {};

  List<LeaderboardEntry> _parse(Map<String, dynamic>? data) {
    final raw = (data?['entries'] as List?) ?? const [];
    return raw.map((e) {
      final m = (e as Map).cast<String, dynamic>();
      return LeaderboardEntry(
        rank: (m['rank'] as num?)?.toInt() ?? 0,
        name: m['name'] as String? ?? '',
        city: m['city'] as String? ?? '',
        points: (m['points'] as num?)?.toInt() ?? 0,
        streak: (m['streak'] as num?)?.toInt() ?? 0,
        weightLostKg: (m['weightLostKg'] as num?)?.toDouble() ?? 0,
        photoUrl: m['photoUrl'] as String?,
        isCurrentUser: currentUid != null && m['participantId'] == currentUid,
      );
    }).toList();
  }

  @override
  Stream<List<LeaderboardEntry>> watch(String period) =>
      _col.doc(period).snapshots().map((d) {
        final list = _parse(d.data());
        _cache[period] = list;
        return list;
      });

  @override
  List<LeaderboardEntry>? currentSnapshot(String period) => _cache[period];
}
