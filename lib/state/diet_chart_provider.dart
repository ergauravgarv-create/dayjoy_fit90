import 'package:csv/csv.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/diet_charts/diet_chart_models.dart';
import 'prefs_provider.dart';

/// Loads and parses the bundled clinical diet-chart database (50 charts,
/// ~4,425 meal rows + guidance) from assets. Cached after first load.
final dietChartsProvider = FutureProvider<List<DietChart>>((ref) async {
  final itemsCsv =
      await rootBundle.loadString('assets/data/diet_chart_meal_items.csv');
  final guideCsv =
      await rootBundle.loadString('assets/data/diet_chart_guidance.csv');

  const converter = CsvToListConverter(shouldParseNumbers: false, eol: '\n');
  final itemRows = converter.convert(_clean(itemsCsv));
  final guideRows = converter.convert(_clean(guideCsv));

  // ---- meal items, grouped by chart_id ----
  final ih = _headerIndex(itemRows.first);
  final Map<String, List<DietChartItem>> byChart = {};
  for (final row in itemRows.skip(1)) {
    if (row.length < ih.length) continue;
    final chartId = _s(row, ih, 'chart_id');
    (byChart[chartId] ??= []).add(DietChartItem(
      day: int.tryParse(_s(row, ih, 'day_number')) ?? 1,
      slot: _s(row, ih, 'meal_slot'),
      time: _s(row, ih, 'time'),
      dish: _s(row, ih, 'dish_or_item'),
      quantity: _s(row, ih, 'quantity'),
      kcal: (double.tryParse(_s(row, ih, 'calories_kcal')) ?? 0).round(),
      protein: double.tryParse(_s(row, ih, 'protein_g')) ?? 0,
      carbs: double.tryParse(_s(row, ih, 'carbohydrates_g')) ?? 0,
      fat: double.tryParse(_s(row, ih, 'fat_g')) ?? 0,
      fibre: double.tryParse(_s(row, ih, 'fiber_g')) ?? 0,
      notes: _s(row, ih, 'notes'),
    ));
  }

  // ---- guidance / chart definitions ----
  final gh = _headerIndex(guideRows.first);
  final List<DietChart> charts = [];
  for (final row in guideRows.skip(1)) {
    if (row.length < gh.length) continue;
    final id = _s(row, gh, 'chart_id');
    charts.add(DietChart(
      id: id,
      name: _s(row, gh, 'chart_name'),
      dietType: _s(row, gh, 'diet_type'),
      condition: _s(row, gh, 'health_condition'),
      goal: _s(row, gh, 'goal'),
      generalGuidance: _s(row, gh, 'general_guidance'),
      foodsToAvoid: _s(row, gh, 'foods_to_avoid_or_limit'),
      redFlags: _s(row, gh, 'red_flags_and_exclusions'),
      approver: _s(row, gh, 'required_approver'),
      status: _s(row, gh, 'status'),
      items: byChart[id] ?? const [],
    ));
  }
  return charts;
});

/// Per-condition clinical rules (targets/include/limit/avoid/monitor), joined
/// from condition_rules + program_definitions. Cached after first load.
final conditionRulesProvider = FutureProvider<ConditionRules>((ref) async {
  final rulesCsv =
      await rootBundle.loadString('assets/data/condition_rules.csv');
  final progCsv =
      await rootBundle.loadString('assets/data/program_definitions.csv');
  const converter = CsvToListConverter(shouldParseNumbers: false, eol: '\n');
  final ruleRows = converter.convert(_clean(rulesCsv));
  final progRows = converter.convert(_clean(progCsv));

  final ph = _headerIndex(progRows.first);
  final Map<String, String> nameToId = {};
  for (final row in progRows.skip(1)) {
    if (row.length < ph.length) continue;
    nameToId[_s(row, ph, 'program_name')] = _s(row, ph, 'program_id');
  }

  final rh = _headerIndex(ruleRows.first);
  final Map<String, List<ConditionRule>> byProgram = {};
  for (final row in ruleRows.skip(1)) {
    if (row.length < rh.length) continue;
    final pid = _s(row, rh, 'program_id');
    (byProgram[pid] ??= []).add(ConditionRule(
      type: _s(row, rh, 'rule_type'),
      text: _s(row, rh, 'rule_text'),
      numericTarget: _s(row, rh, 'numeric_target'),
      unit: _s(row, rh, 'unit_or_condition'),
    ));
  }
  return ConditionRules(byProgram, nameToId);
});

/// Cross-condition combination rules (e.g. T2D+CKD). Cached after first load.
final combinationRulesProvider =
    FutureProvider<List<CombinationRule>>((ref) async {
  final csv =
      await rootBundle.loadString('assets/data/combination_rules.csv');
  const converter = CsvToListConverter(shouldParseNumbers: false, eol: '\n');
  final rows = converter.convert(_clean(csv));
  final h = _headerIndex(rows.first);
  final List<CombinationRule> out = [];
  for (final row in rows.skip(1)) {
    if (row.length < h.length) continue;
    final combo = _s(row, h, 'condition_combination');
    out.add(CombinationRule(
      tokens: combo
          .split('+')
          .map((t) => t.trim())
          .where((t) => t.isNotEmpty)
          .toList(),
      rule: _s(row, h, 'rule'),
      requiredReview: _s(row, h, 'required_review'),
    ));
  }
  return out;
});

/// Condition-specific escalation triggers (emergency/urgent/stop/specialist).
final escalationRulesProvider =
    FutureProvider<List<EscalationRule>>((ref) async {
  final csv =
      await rootBundle.loadString('assets/data/escalation_rules.csv');
  const converter = CsvToListConverter(shouldParseNumbers: false, eol: '\n');
  final rows = converter.convert(_clean(csv));
  final h = _headerIndex(rows.first);
  final List<EscalationRule> out = [];
  for (final row in rows.skip(1)) {
    if (row.length < h.length) continue;
    out.add(EscalationRule(
      programIds: _s(row, h, 'program_ids')
          .split(';')
          .map((t) => t.trim())
          .where((t) => t.isNotEmpty)
          .toList(),
      trigger: _s(row, h, 'trigger'),
      action: _s(row, h, 'action'),
      rationale: _s(row, h, 'rationale'),
    ));
  }
  return out;
});

String _clean(String csv) {
  var s = csv.replaceAll('\r\n', '\n');
  if (s.isNotEmpty && s.codeUnitAt(0) == 0xFEFF) s = s.substring(1);
  return s;
}

Map<String, int> _headerIndex(List<dynamic> header) {
  final map = <String, int>{};
  for (int i = 0; i < header.length; i++) {
    map[header[i].toString().trim()] = i;
  }
  return map;
}

String _s(List<dynamic> row, Map<String, int> h, String key) {
  final i = h[key];
  if (i == null || i >= row.length) return '';
  return row[i].toString().trim();
}

/// Charts assigned to participants (participantId → chartId), persisted
/// on-device. Assigning is the consultant's approval to share the chart.
final assignedChartProvider =
    NotifierProvider<AssignedChartController, Map<String, String>>(
        AssignedChartController.new);

class AssignedChartController extends Notifier<Map<String, String>> {
  static const String _key = 'assigned_charts';

  @override
  Map<String, String> build() {
    final raw = ref.watch(sharedPreferencesProvider).getStringList(_key) ?? [];
    final map = <String, String>{};
    for (final e in raw) {
      final parts = e.split('=');
      if (parts.length == 2) map[parts[0]] = parts[1];
    }
    return map;
  }

  void assign(String participantId, String chartId) {
    state = {...state, participantId: chartId};
    _persist();
  }

  void clear(String participantId) {
    final next = {...state}..remove(participantId);
    state = next;
    _persist();
  }

  void _persist() {
    ref.read(sharedPreferencesProvider).setStringList(
        _key, state.entries.map((e) => '${e.key}=${e.value}').toList());
  }
}
