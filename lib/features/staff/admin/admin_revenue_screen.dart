import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/billing/subscription_plans.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/section_header.dart';
import '../../../state/subscription_sales_provider.dart';

/// ADMIN-ONLY revenue & subscriptions dashboard: active subscribers by plan and
/// the aggregated revenue, GST, referral payouts and BV from the economics
/// model. Reached from the admin dashboard (gated to the admin role).
class AdminRevenueScreen extends ConsumerWidget {
  const AdminRevenueScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final TextTheme text = Theme.of(context).textTheme;
    final t = ref.watch(revenueTotalsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Revenue & subscriptions')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.xxl),
        children: [
          const SizedBox(height: AppSpacing.md),
          GlassCard(
            gradient: AppColors.brandGradient,
            child: Row(
              children: [
                const Icon(Icons.payments_rounded, color: Colors.white, size: 28),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Active subscribers',
                          style: TextStyle(color: Colors.white70, fontSize: 13)),
                      Text('${t.subscribers}',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 30,
                              fontWeight: FontWeight.w900)),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text('Revenue (incl. GST)',
                        style: TextStyle(color: Colors.white70, fontSize: 12)),
                    Text(formatInr(t.revenueInclGst),
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w900)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: AppSpacing.md,
            crossAxisSpacing: AppSpacing.md,
            childAspectRatio: 1.7,
            children: [
              _Kpi('GST collected', formatInr(t.gstCollected), AppColors.info),
              _Kpi('Referral payouts', formatInr(t.referralPayout),
                  AppColors.secondary),
              _Kpi('Company balance', formatInr(t.companyBalance),
                  AppColors.primary),
              _Kpi('Total BV', '${t.bvPoints.toStringAsFixed(0)} BV',
                  AppColors.orange),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),

          const SectionHeader(title: 'Subscribers by plan'),
          const SizedBox(height: AppSpacing.md),
          GlassCard(
            child: Column(
              children: [
                for (int i = 0; i < t.perPlan.length; i++) ...[
                  _PlanRow(row: t.perPlan[i], total: t.subscribers),
                  if (i != t.perPlan.length - 1)
                    const Divider(height: AppSpacing.lg),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Allocation split
          const SectionHeader(title: 'Internal allocation'),
          const SizedBox(height: AppSpacing.md),
          GlassCard(
            child: Column(
              children: [
                _kv('Taxable (GST-exclusive) value', formatInr(t.taxable)),
                _kv('Management (10%)', formatInr(t.management)),
                _kv('Strategic developer (5%)', formatInr(t.developer)),
                _kv('Administration (5%)', formatInr(t.admin)),
                _kv('BV base (80%)', formatInr(t.bvBase)),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Confidential — internal figures. Computed from unrounded values; '
            'excludes payment-gateway charges, refunds and withholding taxes.',
            style: text.bodySmall?.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _kv(String k, String v) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Expanded(child: Text(k)),
            Text(v, style: const TextStyle(fontWeight: FontWeight.w700)),
          ],
        ),
      );
}

class _Kpi extends StatelessWidget {
  const _Kpi(this.label, this.value, this.color);
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return GlassCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(value,
              style: text.titleLarge
                  ?.copyWith(fontWeight: FontWeight.w900, color: color)),
          const SizedBox(height: 2),
          Text(label,
              style: text.bodySmall
                  ?.copyWith(color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

class _PlanRow extends StatelessWidget {
  const _PlanRow({required this.row, required this.total});
  final PlanRevenue row;
  final int total;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final double share = total == 0 ? 0 : row.count / total;
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(row.plan.title ?? row.plan.durationLabel,
                  style: text.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.pill),
                child: LinearProgressIndicator(
                  value: share,
                  minHeight: 6,
                  backgroundColor: AppColors.primary.withOpacity(0.10),
                  valueColor:
                      const AlwaysStoppedAnimation(AppColors.primary),
                ),
              ),
              const SizedBox(height: 4),
              Text('${row.count} subscribers · ${formatInr(row.revenueInclGst)}',
                  style: text.bodySmall
                      ?.copyWith(color: AppColors.textSecondary)),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Text('${(share * 100).toStringAsFixed(0)}%',
            style: text.titleMedium
                ?.copyWith(fontWeight: FontWeight.w800)),
      ],
    );
  }
}
