import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../data/models/participant.dart';
import '../../shared/widgets/glass_card.dart';
import '../../state/diet_chart_provider.dart';
import 'condition_rules_view.dart';
import 'diet_chart_models.dart';

const List<String> _slotOrder = [
  'Early Morning',
  'Breakfast',
  'Mid-Morning',
  'Lunch',
  'Evening',
  'Dinner',
  'Bedtime',
];

/// Full chart view. When [participant] is provided (consultant context), an
/// "Assign to client" action appears; otherwise it's read-only.
class DietChartDetailScreen extends ConsumerWidget {
  const DietChartDetailScreen({
    super.key,
    required this.chart,
    this.participant,
  });

  final DietChart chart;
  final Participant? participant;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Diet Chart')),
      body: DietChartView(chart: chart, consultant: participant != null),
      bottomNavigationBar: participant == null
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: FilledButton.icon(
                  icon: const Icon(Icons.verified_rounded),
                  label: Text('Approve & assign to ${participant!.name}'),
                  onPressed: () {
                    ref
                        .read(assignedChartProvider.notifier)
                        .assign(participant!.id, chart.id);
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text(
                              'Chart assigned to ${participant!.name}')),
                    );
                  },
                ),
              ),
            ),
    );
  }
}

class DietChartView extends StatefulWidget {
  const DietChartView({super.key, required this.chart, this.consultant = false});
  final DietChart chart;
  final bool consultant;

  @override
  State<DietChartView> createState() => _DietChartViewState();
}

class _DietChartViewState extends State<DietChartView> {
  int _day = 1;

  @override
  Widget build(BuildContext context) {
    final DietChart c = widget.chart;
    final TextTheme text = Theme.of(context).textTheme;
    final List<int> days = c.days.isEmpty ? [1] : c.days;
    if (!days.contains(_day)) _day = days.first;

    // Group the selected day's items by meal slot.
    final dayItems = c.itemsForDay(_day);
    final Map<String, List<DietChartItem>> bySlot = {};
    for (final it in dayItems) {
      (bySlot[it.slot] ??= []).add(it);
    }
    final orderedSlots = [
      ..._slotOrder.where(bySlot.containsKey),
      ...bySlot.keys.where((s) => !_slotOrder.contains(s)),
    ];

    return ListView(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, 40),
      children: [
        // Header
        GlassCard(
          gradient: AppColors.brandGradient,
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(c.condition,
                  style: const TextStyle(
                      color: Colors.white70, fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text(c.name,
                  style: text.titleLarge?.copyWith(
                      color: Colors.white, fontWeight: FontWeight.w800)),
              const SizedBox(height: AppSpacing.sm),
              Wrap(spacing: 8, runSpacing: 6, children: [
                _pill(c.dietType),
                _pill(c.goal),
                _pill('${days.length}-day plan'),
              ]),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        // Consultant approval note
        GlassCard(
          child: Row(
            children: [
              const Icon(Icons.medical_information_rounded,
                  color: AppColors.info),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  widget.consultant
                      ? 'Review the guidance & red-flags below, then approve & assign. Approver: ${c.approver}.'
                      : 'This chart was approved & assigned by your consultant. It is not a substitute for medical advice.',
                  style: text.bodySmall,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        // Red flags (safety)
        if (c.redFlagList.isNotEmpty) ...[
          _SafetyCard(title: 'Not suitable if…', items: c.redFlagList),
          const SizedBox(height: AppSpacing.md),
        ],

        // Guidance
        _InfoBlock(
            icon: Icons.tips_and_updates_rounded,
            title: 'General guidance',
            body: c.generalGuidance),
        const SizedBox(height: AppSpacing.sm),
        _InfoBlock(
            icon: Icons.no_food_rounded,
            title: 'Foods to avoid / limit',
            body: c.foodsToAvoid),
        const SizedBox(height: AppSpacing.md),

        // Per-condition clinical targets & rules
        ConditionRulesSection(condition: c.condition),
        const SizedBox(height: AppSpacing.xl),

        // Day selector
        Text('Daily plan', style: text.titleMedium),
        const SizedBox(height: AppSpacing.sm),
        SizedBox(
          height: 40,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: days.length,
            separatorBuilder: (_, __) => const SizedBox(width: 6),
            itemBuilder: (context, i) {
              final d = days[i];
              final sel = d == _day;
              return ChoiceChip(
                label: Text('Day $d'),
                selected: sel,
                labelStyle: TextStyle(
                    color: sel ? Colors.white : AppColors.textSecondary,
                    fontWeight: FontWeight.w600),
                onSelected: (_) => setState(() => _day = d),
              );
            },
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Text('Day $_day', style: text.titleSmall),
            const Spacer(),
            Text('${c.dayKcal(_day)} kcal · ${c.dayProtein(_day).round()} g protein',
                style: text.bodySmall
                    ?.copyWith(color: AppColors.textSecondary)),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),

        for (final slot in orderedSlots) _SlotCard(slot: slot, items: bySlot[slot]!),
      ],
    );
  }

  Widget _pill(String s) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.18),
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        child: Text(s,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600)),
      );
}

class _SlotCard extends StatelessWidget {
  const _SlotCard({required this.slot, required this.items});
  final String slot;
  final List<DietChartItem> items;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final String time = items.isNotEmpty ? items.first.time : '';
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: GlassCard(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(slot,
                    style: text.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w800)),
                const Spacer(),
                Text(time,
                    style: text.bodySmall
                        ?.copyWith(color: AppColors.textSecondary)),
              ],
            ),
            const SizedBox(height: 6),
            for (final it in items)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('•  '),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(it.dish, style: text.bodyMedium),
                          Text(it.quantity,
                              style: text.bodySmall
                                  ?.copyWith(color: AppColors.textSecondary)),
                        ],
                      ),
                    ),
                    if (it.kcal > 0)
                      Text('${it.kcal}',
                          style: text.bodySmall
                              ?.copyWith(color: AppColors.textSecondary)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SafetyCard extends StatelessWidget {
  const _SafetyCard({required this.title, required this.items});
  final String title;
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.error.withOpacity(0.08),
        borderRadius: AppRadius.card,
        border: Border.all(color: AppColors.error.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.warning_amber_rounded,
                  color: AppColors.error, size: 20),
              const SizedBox(width: 6),
              Text(title,
                  style: text.titleSmall?.copyWith(
                      color: AppColors.error, fontWeight: FontWeight.w800)),
            ],
          ),
          const SizedBox(height: 6),
          for (final s in items)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('•  '),
                  Expanded(child: Text(s, style: text.bodySmall)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _InfoBlock extends StatelessWidget {
  const _InfoBlock(
      {required this.icon, required this.title, required this.body});
  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return GlassCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: AppColors.primary),
              const SizedBox(width: 6),
              Text(title,
                  style: text.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 4),
          Text(body, style: text.bodySmall?.copyWith(height: 1.4)),
        ],
      ),
    );
  }
}
