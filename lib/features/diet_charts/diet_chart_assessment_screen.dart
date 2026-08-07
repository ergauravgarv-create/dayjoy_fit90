import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../data/models/participant.dart';
import '../../shared/widgets/glass_card.dart';
import '../../state/diet_chart_provider.dart';
import 'condition_rules_view.dart';
import 'diet_chart_detail_screen.dart';
import 'diet_chart_models.dart';

/// Condition options — these strings match the charts' `health_condition`.
const List<String> _conditionOptions = [
  'Weight management',
  'Type 2 diabetes / prediabetes',
  'Hypertension',
  'Dyslipidemia',
  'Fatty liver / MASLD',
  'Gout / hyperuricemia',
  'CKD—stable, earlier stages',
  'PCOS / PMOS',
  'Hypothyroidism',
  'Iron-deficiency anemia / low iron',
  'GERD / reflux',
  'Irritable bowel syndrome',
  'Arthritis / joint health',
  'Bone health / osteoporosis risk',
  'Pregnancy',
  'Postpartum—breastfeeding',
  'Postpartum—not breastfeeding',
];

enum _Gate { none, warn, stop, specialist, emergency }

int _escRank(String action) {
  const order = [
    'emergency',
    'urgent_or_emergency',
    'stop_and_refer',
    'block_plan',
    'specialist_only',
    'urgent_clinician',
    'specialist_review',
    'allergy_specialist_review',
    'multidisciplinary_review',
  ];
  final i = order.indexOf(action);
  return i < 0 ? 99 : i;
}

({Color color, String label}) _escMeta(String action) => switch (action) {
      'emergency' ||
      'urgent_or_emergency' =>
        (color: AppColors.error, label: 'Emergency'),
      'stop_and_refer' ||
      'block_plan' =>
        (color: AppColors.error, label: 'Stop & refer'),
      'specialist_only' => (color: AppColors.error, label: 'Specialist only'),
      'urgent_clinician' =>
        (color: AppColors.orange, label: 'Urgent clinician'),
      _ => (color: AppColors.orange, label: 'Specialist review'),
    };

/// Consultant assessment that applies the clinical safety gates, then suggests
/// matching diet charts from the library.
class DietChartAssessmentScreen extends ConsumerStatefulWidget {
  const DietChartAssessmentScreen({super.key, required this.participant});
  final Participant participant;

  @override
  ConsumerState<DietChartAssessmentScreen> createState() =>
      _DietChartAssessmentScreenState();
}

class _DietChartAssessmentScreenState
    extends ConsumerState<DietChartAssessmentScreen> {
  late String _diet = widget.participant.foodPreference
          .toLowerCase()
          .startsWith('veg')
      ? 'Veg'
      : 'Non-Veg';
  String _goal = 'Weight loss';
  final Set<String> _conditions = {};

  // Safety screens (map to the escalation rules).
  bool _under18 = false;
  bool _pregnantNow = false;
  bool _eatingDisorder = false;
  bool _unstable = false; // hospitalised/surgery/active infection/unstable
  bool _emergencySymptoms = false;
  bool _hypoMeds = false; // insulin/sulfonylurea/recurrent hypoglycemia
  bool _advancedCkd = false;
  bool _advancedLiver = false;
  bool _type1 = false;

  bool _submitted = false;

  @override
  void initState() {
    super.initState();
    // Pre-tick conditions from the client's recorded medical conditions.
    final h = widget.participant.healthConditions?.toLowerCase() ?? '';
    if (h.contains('diabet')) _conditions.add('Type 2 diabetes / prediabetes');
    if (h.contains('hypertension')) _conditions.add('Hypertension');
    if (h.contains('cholesterol')) _conditions.add('Dyslipidemia');
    if (h.contains('pcos')) _conditions.add('PCOS / PMOS');
    if (h.contains('thyroid')) _conditions.add('Hypothyroidism');
    if (_conditions.isEmpty) _conditions.add('Weight management');
  }

  ({_Gate level, String message}) _verdict() {
    if (_emergencySymptoms) {
      return (
        level: _Gate.emergency,
        message:
            'Emergency — do NOT issue a diet plan. Advise urgent medical evaluation immediately.'
      );
    }
    if (_type1 || _advancedCkd || _advancedLiver) {
      return (
        level: _Gate.specialist,
        message:
            'Specialist care required (Type 1 diabetes, advanced kidney or advanced liver disease). Do not auto-assign a chart — refer to the appropriate specialist.'
      );
    }
    if (_eatingDisorder || _unstable) {
      return (
        level: _Gate.stop,
        message:
            'Stop & refer — medical nutrition therapy is needed. Do not issue weight-loss targets for this client.'
      );
    }
    // Non-blocking warnings.
    final List<String> warns = [];
    if (_pregnantNow && _goal == 'Weight loss') {
      warns.add('Pregnant — do not use weight-loss charts; use a Pregnancy chart.');
    }
    if (_under18 && _goal == 'Weight loss') {
      warns.add('Client under 18 — use a paediatric pathway, not weight loss.');
    }
    if (_hypoMeds) {
      warns.add(
          'On insulin/sulfonylurea or hypoglycemia risk — coordinate carbohydrate timing with the prescriber.');
    }
    if (_conditions.contains('Type 2 diabetes / prediabetes') &&
        _conditions.contains('CKD—stable, earlier stages')) {
      warns.add('Diabetes + CKD — needs renal-diabetes specialist review.');
    }
    if (_conditions.length >= 3) {
      warns.add('Three or more conditions — consultant review recommended.');
    }
    if (warns.isEmpty) return (level: _Gate.none, message: '');
    return (level: _Gate.warn, message: warns.join('\n'));
  }

  List<DietChart> _suggest(List<DietChart> all) {
    final bool veg = _diet == 'Veg';
    var list = all.where((c) {
      final condOk = _conditions.contains(c.condition);
      final dietOk = veg ? c.isVeg : !c.isVeg;
      return condOk && dietOk;
    }).toList();
    // Rank: charts matching the chosen goal first.
    final wantLoss = _goal == 'Weight loss';
    list.sort((a, b) {
      final aLoss = a.goal.toLowerCase().contains('weight loss');
      final bLoss = b.goal.toLowerCase().contains('weight loss');
      final aScore = (aLoss == wantLoss) ? 0 : 1;
      final bScore = (bLoss == wantLoss) ? 0 : 1;
      return aScore - bScore;
    });
    return list;
  }

  /// Program ids active for this client (selected conditions + safety toggles +
  /// weight-loss goal), used to match combination rules.
  Set<String> _activePrograms(ConditionRules cr) {
    final active = <String>{};
    for (final cond in _conditions) {
      final pid = cr.programIdByName[cond];
      if (pid != null) active.add(pid);
    }
    if (_advancedCkd) active.add('CKD_ADV');
    if (_advancedLiver) active.add('LIVER_ADV');
    if (_goal == 'Weight loss') active.add('WL');
    return active;
  }

  bool _comboMatches(CombinationRule c, Set<String> active) {
    bool has(String p) => active.contains(p);
    for (final t in c.tokens) {
      if (t == 'ANY_3_PLUS') {
        if (_conditions.length < 3) return false;
      } else if (t == 'CKD') {
        if (!has('CKD_EARLY') && !has('CKD_ADV')) return false;
      } else if (t == 'CKD_OR_LIVER') {
        if (!has('CKD_EARLY') &&
            !has('CKD_ADV') &&
            !has('MASLD') &&
            !has('LIVER_ADV')) return false;
      } else {
        if (!has(t)) return false;
      }
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(dietChartsProvider);
    final TextTheme text = Theme.of(context).textTheme;
    final verdict = _verdict();
    // Use the real chart conditions once loaded so selections match exactly.
    final List<String> conditionOptions = async.valueOrNull == null
        ? _conditionOptions
        : (async.valueOrNull!.map((c) => c.condition).toSet().toList()..sort());

    // Combination rules (need the condition→program map).
    final crAsync = ref.watch(conditionRulesProvider);
    final combosAsync = ref.watch(combinationRulesProvider);
    List<CombinationRule> combos = const [];
    bool comboBlocks = false;
    final cr = crAsync.valueOrNull;
    final allCombos = combosAsync.valueOrNull;
    if (cr != null && allCombos != null) {
      final active = _activePrograms(cr);
      combos = allCombos.where((c) => _comboMatches(c, active)).toList();
      comboBlocks = combos.any((c) => c.specialistOnly);
    }
    final bool toggleBlock = verdict.level == _Gate.emergency ||
        verdict.level == _Gate.specialist ||
        verdict.level == _Gate.stop;
    final bool hardBlock = toggleBlock || comboBlocks;

    // Escalation triggers applicable to the client's conditions (review list).
    final escAsync = ref.watch(escalationRulesProvider);
    List<EscalationRule> escChecks = const [];
    if (cr != null && escAsync.valueOrNull != null) {
      final active = _activePrograms(cr);
      escChecks = escAsync.valueOrNull!
          .where((e) => e.universal || e.programIds.any(active.contains))
          .toList()
        ..sort((a, b) => _escRank(a.action).compareTo(_escRank(b.action)));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Assess & suggest')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, 40),
        children: [
          Text(widget.participant.name, style: text.titleLarge),
          Text(
              '${widget.participant.gender}, ${widget.participant.age} · BMI ${widget.participant.bmi.toStringAsFixed(1)}',
              style: text.bodySmall),
          const SizedBox(height: AppSpacing.lg),

          _label('Diet preference'),
          _chips(const ['Veg', 'Non-Veg'], _diet, (v) => setState(() => _diet = v)),
          const SizedBox(height: AppSpacing.md),

          _label('Primary goal'),
          _chips(const ['Weight loss', 'Condition support'], _goal,
              (v) => setState(() => _goal = v)),
          const SizedBox(height: AppSpacing.md),

          _label('Health conditions'),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.xs,
            children: [
              for (final c in conditionOptions)
                FilterChip(
                  label: Text(c),
                  selected: _conditions.contains(c),
                  labelStyle: TextStyle(
                    color: _conditions.contains(c)
                        ? Colors.white
                        : AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                  checkmarkColor: Colors.white,
                  onSelected: (sel) => setState(() =>
                      sel ? _conditions.add(c) : _conditions.remove(c)),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),

          _label('Safety screen (tick anything that applies)'),
          _safety('Under 18 years', _under18, (v) => _under18 = v),
          _safety('Pregnant now', _pregnantNow, (v) => _pregnantNow = v),
          _safety('Current/past eating disorder or purging', _eatingDisorder,
              (v) => _eatingDisorder = v),
          _safety(
              'Recent hospitalization / surgery / active infection / medically unstable',
              _unstable,
              (v) => _unstable = v),
          _safety(
              'Emergency symptoms (chest pain, breathlessness, severe weakness, vision/speech change)',
              _emergencySymptoms,
              (v) => _emergencySymptoms = v),
          _safety('On insulin / sulfonylurea or recurrent hypoglycemia',
              _hypoMeds, (v) => _hypoMeds = v),
          _safety('Advanced kidney disease / dialysis / transplant',
              _advancedCkd, (v) => _advancedCkd = v),
          _safety('Advanced / decompensated liver disease', _advancedLiver,
              (v) => _advancedLiver = v),
          _safety('Type 1 diabetes', _type1, (v) => _type1 = v),
          const SizedBox(height: AppSpacing.lg),

          FilledButton.icon(
            icon: const Icon(Icons.auto_awesome_rounded),
            label: const Text('Suggest matching charts'),
            onPressed: () => setState(() => _submitted = true),
          ),
          const SizedBox(height: AppSpacing.lg),

          if (_submitted) ...[
            if (verdict.level != _Gate.none) ...[
              _VerdictBanner(level: verdict.level, message: verdict.message),
              const SizedBox(height: AppSpacing.md),
            ],
            if (comboBlocks && !toggleBlock) ...[
              const _VerdictBanner(
                level: _Gate.specialist,
                message:
                    'A condition combination requires specialist care — no automatic plan. See the combination rules below.',
              ),
              const SizedBox(height: AppSpacing.md),
            ],
            if (combos.isNotEmpty) ...[
              Text('Combination rules', style: text.titleMedium),
              const SizedBox(height: AppSpacing.sm),
              for (final combo in combos) _CombinationCard(rule: combo),
              const SizedBox(height: AppSpacing.md),
            ],
            if (escChecks.isNotEmpty) ...[
              Text('Escalation checks — confirm none apply',
                  style: text.titleMedium),
              const SizedBox(height: AppSpacing.sm),
              for (final e in escChecks) _EscalationCard(rule: e),
              const SizedBox(height: AppSpacing.md),
            ],
            if (hardBlock)
              Text(
                'No charts are suggested for this client. Please follow the referral/review action(s) above.',
                style: text.bodyMedium
                    ?.copyWith(color: AppColors.textSecondary),
              )
            else
              async.when(
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (e, _) => Text('Could not load charts: $e'),
                data: (all) {
                  final s = _suggest(all);
                  if (s.isEmpty) {
                    return Text(
                        'No exact chart for this combination. Try "Browse all charts", or adjust the conditions.',
                        style: text.bodyMedium);
                  }
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${s.length} suggested chart${s.length == 1 ? '' : 's'}',
                          style: text.titleMedium),
                      const SizedBox(height: AppSpacing.sm),
                      for (final c in s) _SuggestionCard(chart: c, participant: widget.participant),
                    ],
                  );
                },
              ),
            if (!hardBlock) ...[
              const SizedBox(height: AppSpacing.xl),
              Text('Clinical targets for selected conditions',
                  style: text.titleMedium),
              const SizedBox(height: AppSpacing.sm),
              for (final cond in _conditions)
                ConditionRulesTile(condition: cond),
            ],
          ],
        ],
      ),
    );
  }

  Widget _label(String s) => Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
        child: Text(s, style: Theme.of(context).textTheme.titleMedium),
      );

  Widget _chips(List<String> opts, String sel, ValueChanged<String> onSel) =>
      Wrap(
        spacing: AppSpacing.sm,
        children: [
          for (final o in opts)
            ChoiceChip(
              label: Text(o),
              selected: sel == o,
              labelStyle: TextStyle(
                color: sel == o ? Colors.white : AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
              onSelected: (_) => onSel(o),
            ),
        ],
      );

  Widget _safety(String label, bool value, ValueChanged<bool> onChanged) =>
      CheckboxListTile(
        value: value,
        onChanged: (v) => setState(() => onChanged(v ?? false)),
        title: Text(label, style: Theme.of(context).textTheme.bodyMedium),
        controlAffinity: ListTileControlAffinity.leading,
        contentPadding: EdgeInsets.zero,
        dense: true,
      );
}

class _VerdictBanner extends StatelessWidget {
  const _VerdictBanner({required this.level, required this.message});
  final _Gate level;
  final String message;

  @override
  Widget build(BuildContext context) {
    final bool danger = level == _Gate.emergency ||
        level == _Gate.stop ||
        level == _Gate.specialist;
    final Color c = danger ? AppColors.error : AppColors.orange;
    final String title = switch (level) {
      _Gate.emergency => 'Emergency',
      _Gate.specialist => 'Specialist referral required',
      _Gate.stop => 'Stop & refer',
      _ => 'Review before assigning',
    };
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: c.withOpacity(0.08),
        borderRadius: AppRadius.card,
        border: Border.all(color: c.withOpacity(0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(danger ? Icons.dangerous_rounded : Icons.warning_amber_rounded,
              color: c),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: c, fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text(message,
                    style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SuggestionCard extends StatelessWidget {
  const _SuggestionCard({required this.chart, required this.participant});
  final DietChart chart;
  final Participant participant;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: GlassCard(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) =>
                DietChartDetailScreen(chart: chart, participant: participant),
          ),
        ),
        child: Row(
          children: [
            const Icon(Icons.restaurant_menu_rounded, color: AppColors.primary),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${chart.condition} · ${chart.goal}',
                      style: text.titleSmall
                          ?.copyWith(fontWeight: FontWeight.w700)),
                  Text('${chart.dietType} · review & assign',
                      style: text.bodySmall),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded),
          ],
        ),
      ),
    );
  }
}

class _CombinationCard extends StatelessWidget {
  const _CombinationCard({required this.rule});
  final CombinationRule rule;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final bool danger = rule.specialistOnly ||
        rule.requiredReview.contains('renal') ||
        rule.requiredReview.contains('multidisciplinary');
    final Color c = danger ? AppColors.error : AppColors.orange;
    final String label = rule.requiredReview.replaceAll('_', ' ');
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: GlassCard(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.merge_type_rounded, color: c, size: 20),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(rule.rule,
                      style: text.bodyMedium?.copyWith(height: 1.35)),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: c.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                    child: Text(label,
                        style: text.bodySmall?.copyWith(
                            color: c, fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EscalationCard extends StatelessWidget {
  const _EscalationCard({required this.rule});
  final EscalationRule rule;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final m = _escMeta(rule.action);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: GlassCard(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.report_gmailerrorred_rounded, color: m.color, size: 20),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: m.color.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                    child: Text(m.label,
                        style: text.bodySmall?.copyWith(
                            color: m.color, fontWeight: FontWeight.w700)),
                  ),
                  const SizedBox(height: 4),
                  Text(rule.trigger,
                      style: text.bodyMedium?.copyWith(height: 1.35)),
                  if (rule.rationale.trim().isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(rule.rationale,
                        style: text.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                            fontStyle: FontStyle.italic)),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
