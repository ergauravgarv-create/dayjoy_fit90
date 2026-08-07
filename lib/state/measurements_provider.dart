import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'prefs_provider.dart';

/// A body-measurement entry logged over time.
class Measurement {
  const Measurement({required this.date, required this.weightKg, this.waistCm});
  final DateTime date;
  final double weightKg;
  final double? waistCm;

  Map<String, dynamic> toJson() => {
        'date': date.millisecondsSinceEpoch,
        'weight': weightKg,
        'waist': waistCm,
      };

  factory Measurement.fromJson(Map<String, dynamic> j) => Measurement(
        date: DateTime.fromMillisecondsSinceEpoch(
            (j['date'] as num?)?.toInt() ?? 0),
        weightKg: (j['weight'] as num?)?.toDouble() ?? 0,
        waistCm: (j['waist'] as num?)?.toDouble(),
      );
}

/// The participant's logged measurements (oldest first), persisted on-device.
final measurementsProvider =
    NotifierProvider<MeasurementsController, List<Measurement>>(
        MeasurementsController.new);

class MeasurementsController extends Notifier<List<Measurement>> {
  static const String _key = 'measurements';

  @override
  List<Measurement> build() {
    final raw = ref.watch(sharedPreferencesProvider).getString(_key);
    if (raw == null || raw.isEmpty) return const [];
    try {
      return (jsonDecode(raw) as List)
          .map((e) => Measurement.fromJson(e as Map<String, dynamic>))
          .toList()
        ..sort((a, b) => a.date.compareTo(b.date));
    } catch (_) {
      return const [];
    }
  }

  void add({required double weightKg, double? waistCm}) {
    state = [
      ...state,
      Measurement(date: DateTime.now(), weightKg: weightKg, waistCm: waistCm),
    ]..sort((a, b) => a.date.compareTo(b.date));
    _persist();
  }

  void _persist() {
    ref.read(sharedPreferencesProvider).setString(
        _key, jsonEncode(state.map((m) => m.toJson()).toList()));
  }

  /// Weight readings (chronological); empty if nothing logged.
  List<double> get weightSeries =>
      state.map((m) => m.weightKg).toList();

  /// Waist readings that are present, chronological.
  List<double> get waistSeries =>
      state.where((m) => m.waistCm != null).map((m) => m.waistCm!).toList();
}
