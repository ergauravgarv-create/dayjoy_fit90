import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/meals/diet_plan.dart';
import 'prefs_provider.dart';

/// Store of diet plans keyed by participant id, persisted on-device. Authored
/// and approved by the doctor/admin; participants read the approved plan only.
/// Moves to the cloud with the Firebase backend.
final dietPlanProvider =
    NotifierProvider<DietPlanController, Map<String, DietPlan>>(
        DietPlanController.new);

class DietPlanController extends Notifier<Map<String, DietPlan>> {
  static const String _key = 'diet_plans';

  @override
  Map<String, DietPlan> build() {
    final raw = ref.watch(sharedPreferencesProvider).getString(_key);
    if (raw == null || raw.isEmpty) return {};
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return map.map((k, v) =>
          MapEntry(k, DietPlan.fromJson(v as Map<String, dynamic>)));
    } catch (_) {
      return {};
    }
  }

  void _persist() {
    ref.read(sharedPreferencesProvider).setString(
          _key,
          jsonEncode(state.map((k, v) => MapEntry(k, v.toJson()))),
        );
  }

  DietPlan? forParticipant(String id) => state[id];

  void save(DietPlan plan) {
    state = {...state, plan.participantId: plan};
    _persist();
  }
}
