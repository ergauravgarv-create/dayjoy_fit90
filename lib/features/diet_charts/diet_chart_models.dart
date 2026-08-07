/// One item (dish) in a clinical diet chart, for a given day and meal slot.
class DietChartItem {
  const DietChartItem({
    required this.day,
    required this.slot,
    required this.time,
    required this.dish,
    required this.quantity,
    required this.kcal,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.fibre,
    required this.notes,
  });

  final int day; // 1..7
  final String slot; // Early Morning, Breakfast, ...
  final String time;
  final String dish;
  final String quantity;
  final int kcal;
  final double protein;
  final double carbs;
  final double fat;
  final double fibre;
  final String notes;
}

/// A full clinical diet chart (7-day) with guidance and safety red-flags.
/// Prepared for a condition + diet type; requires consultant approval to share.
class DietChart {
  DietChart({
    required this.id,
    required this.name,
    required this.dietType,
    required this.condition,
    required this.goal,
    required this.generalGuidance,
    required this.foodsToAvoid,
    required this.redFlags,
    required this.approver,
    required this.status,
    required this.items,
  });

  final String id; // DC001
  final String name;
  final String dietType; // Veg / Non-Veg
  final String condition; // e.g. Hypertension
  final String goal; // e.g. Weight loss / Condition support
  final String generalGuidance;
  final String foodsToAvoid;
  final String redFlags;
  final String approver;
  final String status;
  final List<DietChartItem> items;

  bool get isVeg => dietType.toLowerCase().startsWith('veg');

  /// Sorted distinct day numbers present (usually 1..7).
  List<int> get days =>
      (items.map((i) => i.day).toSet().toList()..sort());

  List<DietChartItem> itemsForDay(int day) =>
      items.where((i) => i.day == day).toList();

  /// Red-flag exclusions, split into individual bullet lines.
  List<String> get redFlagList => redFlags
      .split(RegExp(r'\s*\|\s*'))
      .map((s) => s.trim())
      .where((s) => s.isNotEmpty)
      .toList();

  int dayKcal(int day) =>
      itemsForDay(day).fold(0, (s, i) => s + i.kcal);
  double dayProtein(int day) =>
      itemsForDay(day).fold(0.0, (s, i) => s + i.protein);
}

/// A single per-condition dietary rule (target / include / limit / avoid /
/// caution / separate / monitor), with an optional numeric target.
class ConditionRule {
  const ConditionRule({
    required this.type,
    required this.text,
    required this.numericTarget,
    required this.unit,
  });

  final String type; // target, include, limit, avoid, caution, separate, monitor
  final String text;
  final String numericTarget; // e.g. "<5" (may be empty)
  final String unit; // e.g. "g salt/day" or applicability like "Always"

  /// Short "<5 g salt/day" label when a numeric target exists.
  String? get targetLabel {
    if (numericTarget.trim().isEmpty) return null;
    final u = unit.trim();
    return u.isEmpty ? numericTarget.trim() : '${numericTarget.trim()} $u';
  }
}

/// A cross-condition combination rule (e.g. "T2D+CKD_EARLY" → renal-diabetes
/// review). Applies when all its program tokens are active for the client.
class CombinationRule {
  const CombinationRule({
    required this.tokens,
    required this.rule,
    required this.requiredReview,
  });

  final List<String> tokens; // program ids or special tokens (CKD, ANY_3_PLUS…)
  final String rule;
  final String requiredReview;

  /// Blocking: no automatic plan (needs a specialist).
  bool get specialistOnly => requiredReview == 'specialist_only';
}

/// A condition-specific escalation trigger the consultant must rule out before
/// assigning a plan (emergency / urgent / stop-refer / specialist).
class EscalationRule {
  const EscalationRule({
    required this.programIds,
    required this.trigger,
    required this.action,
    required this.rationale,
  });

  final List<String> programIds; // ['All'] or specific program ids
  final String trigger;
  final String action;
  final String rationale;

  bool get universal => programIds.contains('All');
}

/// Per-condition rule set: look up clinical rules by condition (via program).
class ConditionRules {
  const ConditionRules(this.byProgram, this.programIdByName);

  final Map<String, List<ConditionRule>> byProgram;
  final Map<String, String> programIdByName; // program_name -> program_id

  List<ConditionRule> forCondition(String conditionName) {
    final pid = programIdByName[conditionName];
    if (pid == null) return const [];
    return byProgram[pid] ?? const [];
  }
}
