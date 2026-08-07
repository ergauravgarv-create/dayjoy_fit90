import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'prefs_provider.dart';

/// An intermittent-fasting protocol (fasting hours out of 24).
class FastProtocol {
  const FastProtocol(this.label, this.fastingHours);
  final String label;
  final int fastingHours;
}

const List<FastProtocol> kFastProtocols = [
  FastProtocol('16:8', 16),
  FastProtocol('18:6', 18),
  FastProtocol('20:4', 20),
  FastProtocol('OMAD', 23),
];

class FastRecord {
  const FastRecord(
      {required this.startMillis,
      required this.endMillis,
      required this.targetHours});
  final int startMillis;
  final int endMillis;
  final int targetHours;

  double get durationHours => (endMillis - startMillis) / 3600000.0;
  bool get metGoal => durationHours >= targetHours - 0.25;

  Map<String, dynamic> toJson() =>
      {'s': startMillis, 'e': endMillis, 't': targetHours};

  factory FastRecord.fromJson(Map<String, dynamic> j) => FastRecord(
        startMillis: (j['s'] as num).toInt(),
        endMillis: (j['e'] as num).toInt(),
        targetHours: (j['t'] as num?)?.toInt() ?? 16,
      );
}

class FastState {
  const FastState({
    this.activeStartMillis,
    this.protocolHours = 16,
    this.history = const [],
  });

  final int? activeStartMillis; // null = not currently fasting
  final int protocolHours;
  final List<FastRecord> history;

  bool get isFasting => activeStartMillis != null;

  FastState copyWith({
    int? activeStartMillis,
    bool clearActive = false,
    int? protocolHours,
    List<FastRecord>? history,
  }) =>
      FastState(
        activeStartMillis:
            clearActive ? null : (activeStartMillis ?? this.activeStartMillis),
        protocolHours: protocolHours ?? this.protocolHours,
        history: history ?? this.history,
      );
}

final fastingProvider =
    NotifierProvider<FastController, FastState>(FastController.new);

class FastController extends Notifier<FastState> {
  static const String _key = 'fasting_state';

  @override
  FastState build() {
    final raw = ref.watch(sharedPreferencesProvider).getString(_key);
    if (raw == null || raw.isEmpty) return const FastState();
    try {
      final j = jsonDecode(raw) as Map<String, dynamic>;
      return FastState(
        activeStartMillis: (j['active'] as num?)?.toInt(),
        protocolHours: (j['protocol'] as num?)?.toInt() ?? 16,
        history: ((j['history'] as List?) ?? const [])
            .map((e) => FastRecord.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
    } catch (_) {
      return const FastState();
    }
  }

  void setProtocol(int hours) {
    state = state.copyWith(protocolHours: hours);
    _persist();
  }

  void startFast(int nowMillis) {
    if (state.isFasting) return;
    state = state.copyWith(activeStartMillis: nowMillis);
    _persist();
  }

  /// End the active fast and record it. Returns the completed record (or null).
  FastRecord? endFast(int nowMillis) {
    final start = state.activeStartMillis;
    if (start == null) return null;
    final record = FastRecord(
        startMillis: start,
        endMillis: nowMillis,
        targetHours: state.protocolHours);
    state = state.copyWith(
      clearActive: true,
      history: [record, ...state.history],
    );
    _persist();
    return record;
  }

  void _persist() {
    ref.read(sharedPreferencesProvider).setString(
        _key,
        jsonEncode({
          'active': state.activeStartMillis,
          'protocol': state.protocolHours,
          'history': state.history.map((r) => r.toJson()).toList(),
        }));
  }
}

String _dayKey(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

/// Consecutive days (ending today or yesterday) with a goal-meeting fast.
final fastingStreakProvider = Provider<int>((ref) {
  final hist = ref.watch(fastingProvider).history;
  final days = <String>{};
  for (final r in hist) {
    if (r.metGoal) {
      days.add(_dayKey(DateTime.fromMillisecondsSinceEpoch(r.endMillis)));
    }
  }
  if (days.isEmpty) return 0;
  int s = 0;
  DateTime d = DateTime.now();
  if (!days.contains(_dayKey(d))) d = d.subtract(const Duration(days: 1));
  while (days.contains(_dayKey(d))) {
    s++;
    d = d.subtract(const Duration(days: 1));
  }
  return s;
});
