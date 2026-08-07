import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../shared/widgets/glass_card.dart';
import '../../state/diet_chart_provider.dart';
import 'diet_chart_models.dart';

const List<String> _typeOrder = [
  'target', 'include', 'limit', 'avoid', 'caution', 'separate', 'monitor',
];

({IconData icon, Color color, String label}) _meta(String type) {
  switch (type) {
    case 'target':
      return (icon: Icons.flag_rounded, color: AppColors.primary, label: 'Target');
    case 'include':
      return (
        icon: Icons.check_circle_rounded,
        color: AppColors.success,
        label: 'Include'
      );
    case 'limit':
      return (
        icon: Icons.trending_down_rounded,
        color: AppColors.orange,
        label: 'Limit'
      );
    case 'avoid':
      return (icon: Icons.block_rounded, color: AppColors.error, label: 'Avoid');
    case 'caution':
      return (
        icon: Icons.warning_amber_rounded,
        color: AppColors.orange,
        label: 'Caution'
      );
    case 'separate':
      return (
        icon: Icons.schedule_rounded,
        color: AppColors.info,
        label: 'Timing'
      );
    default: // monitor
      return (
        icon: Icons.monitor_heart_rounded,
        color: AppColors.info,
        label: 'Monitor'
      );
  }
}

List<ConditionRule> _sorted(List<ConditionRule> rules) {
  final copy = [...rules];
  copy.sort((a, b) {
    int ia = _typeOrder.indexOf(a.type);
    int ib = _typeOrder.indexOf(b.type);
    if (ia < 0) ia = 99;
    if (ib < 0) ib = 99;
    return ia - ib;
  });
  return copy;
}

/// Full "Clinical targets & rules" card for a condition (used in chart detail).
class ConditionRulesSection extends ConsumerWidget {
  const ConditionRulesSection({super.key, required this.condition});
  final String condition;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(conditionRulesProvider);
    final rules = async.valueOrNull?.forCondition(condition) ?? const [];
    if (rules.isEmpty) return const SizedBox.shrink();

    final TextTheme text = Theme.of(context).textTheme;
    return GlassCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.rule_rounded, size: 18, color: AppColors.primary),
              const SizedBox(width: 6),
              Text('Clinical targets & rules',
                  style: text.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          for (final r in _sorted(rules)) _RuleRow(rule: r),
        ],
      ),
    );
  }
}

/// Collapsible per-condition rules (used in the assessment screen).
class ConditionRulesTile extends ConsumerWidget {
  const ConditionRulesTile({super.key, required this.condition});
  final String condition;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(conditionRulesProvider);
    final rules = async.valueOrNull?.forCondition(condition) ?? const [];
    if (rules.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: GlassCard(
        padding: EdgeInsets.zero,
        child: Theme(
          data: Theme.of(context)
              .copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            tilePadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            childrenPadding: const EdgeInsets.fromLTRB(
                AppSpacing.md, 0, AppSpacing.md, AppSpacing.md),
            title: Text(condition,
                style: Theme.of(context)
                    .textTheme
                    .titleSmall
                    ?.copyWith(fontWeight: FontWeight.w700)),
            children: [for (final r in _sorted(rules)) _RuleRow(rule: r)],
          ),
        ),
      ),
    );
  }
}

class _RuleRow extends StatelessWidget {
  const _RuleRow({required this.rule});
  final ConditionRule rule;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final m = _meta(rule.type);
    final String? target = rule.targetLabel;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(m.icon, size: 18, color: m.color),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(m.label,
                        style: text.bodySmall?.copyWith(
                            color: m.color, fontWeight: FontWeight.w800)),
                    if (target != null) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: m.color.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                        ),
                        child: Text(target,
                            style: text.bodySmall?.copyWith(
                                color: m.color, fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(rule.text, style: text.bodySmall?.copyWith(height: 1.35)),
                if (rule.unit.trim().isNotEmpty &&
                    target == null &&
                    rule.unit.trim().toLowerCase() != 'always')
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text('Applies: ${rule.unit.trim()}',
                        style: text.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                            fontStyle: FontStyle.italic)),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
