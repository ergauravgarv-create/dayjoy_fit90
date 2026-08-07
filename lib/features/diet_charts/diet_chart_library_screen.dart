import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../data/models/participant.dart';
import '../../shared/widgets/glass_card.dart';
import '../../state/diet_chart_provider.dart';
import 'diet_chart_detail_screen.dart';
import 'diet_chart_models.dart';

/// Browse & filter the clinical diet-chart library. When [participant] is set
/// (consultant context) the list is pre-filtered to their veg/non-veg
/// preference and tapping a chart lets the consultant approve & assign it.
class DietChartLibraryScreen extends ConsumerStatefulWidget {
  const DietChartLibraryScreen({super.key, this.participant});
  final Participant? participant;

  @override
  ConsumerState<DietChartLibraryScreen> createState() =>
      _DietChartLibraryScreenState();
}

class _DietChartLibraryScreenState
    extends ConsumerState<DietChartLibraryScreen> {
  String _query = '';
  late String _diet = widget.participant == null
      ? 'All'
      : (widget.participant!.foodPreference.toLowerCase().startsWith('veg')
          ? 'Veg'
          : 'Non-Veg');

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(dietChartsProvider);
    final TextTheme text = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Diet Chart Library')),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
            child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Text('Could not load charts.\n$e',
                    textAlign: TextAlign.center))),
        data: (charts) {
          final q = _query.trim().toLowerCase();
          final filtered = charts.where((c) {
            final dietOk = _diet == 'All' ||
                (_diet == 'Veg' && c.isVeg) ||
                (_diet == 'Non-Veg' && !c.isVeg);
            final qOk = q.isEmpty ||
                c.condition.toLowerCase().contains(q) ||
                c.goal.toLowerCase().contains(q) ||
                c.name.toLowerCase().contains(q);
            return dietOk && qOk;
          }).toList();

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.sm),
                child: TextField(
                  onChanged: (v) => setState(() => _query = v),
                  decoration: const InputDecoration(
                    hintText: 'Search condition (diabetes, PCOS, liver…)',
                    prefixIcon: Icon(Icons.search_rounded),
                  ),
                ),
              ),
              SizedBox(
                height: 40,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding:
                      const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                  children: [
                    for (final d in const ['All', 'Veg', 'Non-Veg'])
                      Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: ChoiceChip(
                          label: Text(d),
                          selected: _diet == d,
                          labelStyle: TextStyle(
                            color: _diet == d
                                ? Colors.white
                                : AppColors.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                          onSelected: (_) => setState(() => _diet = d),
                        ),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, 0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text('${filtered.length} charts',
                      style: text.bodySmall
                          ?.copyWith(color: AppColors.textSecondary)),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg, 0, AppSpacing.lg, 40),
                  itemCount: filtered.length,
                  itemBuilder: (context, i) =>
                      _ChartCard(chart: filtered[i], participant: widget.participant),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ChartCard extends StatelessWidget {
  const _ChartCard({required this.chart, this.participant});
  final DietChart chart;
  final Participant? participant;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final Color tint = chart.isVeg ? AppColors.success : AppColors.error;
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
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: tint.withOpacity(0.14),
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Icon(Icons.restaurant_menu_rounded, color: tint),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(chart.condition,
                      style: text.titleSmall
                          ?.copyWith(fontWeight: FontWeight.w700)),
                  Text('${chart.dietType} · ${chart.goal}',
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
