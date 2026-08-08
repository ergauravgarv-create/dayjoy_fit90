import 'package:flutter/material.dart';

import '../../../core/billing/subscription_plans.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/section_header.dart';

/// ADMIN-ONLY commercial working of the subscription + referral model: GST,
/// the 5% referral incentive, company balance, the management/developer/admin
/// split and BV generated per plan. Reached only from the admin dashboard,
/// which is itself gated to the admin role by the router.
class ReferralEconomicsScreen extends StatelessWidget {
  const ReferralEconomicsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Referral & BV economics')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.xxl),
        children: [
          const SizedBox(height: AppSpacing.md),
          GlassCard(
            gradient: AppColors.brandGradient,
            child: Row(
              children: [
                const Icon(Icons.lock_person_rounded,
                    color: Colors.white, size: 26),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    'Confidential — internal financial model. Visible to admins '
                    'only. Not shown to participants.',
                    style: text.bodySmall?.copyWith(
                        color: Colors.white, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          const SectionHeader(title: 'Assumptions'),
          const SizedBox(height: AppSpacing.md),
          GlassCard(
            child: Column(
              children: const [
                _Kv('GST rate', '18%'),
                _Kv('Google Play fee', '0%'),
                _Kv('Referral incentive', '5% of GST-inclusive price'),
                _Kv('Management / company margin', '10% of company balance'),
                _Kv('Strategic developer incentive', '5% of company balance'),
                _Kv('Administrative expenses', '5% of company balance'),
                _Kv('BV base allocation', '80% of company balance'),
                _Kv('BV formula', 'BV base × 100 ÷ 105'),
                _Kv('New-subscriber cashback', 'None'),
                _Kv('Referral program', 'Single-level only'),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          const SectionHeader(title: 'Per-plan working'),
          const SizedBox(height: AppSpacing.md),
          for (final p in kPlans)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: _PlanEconomicsCard(plan: p),
            ),

          const SizedBox(height: AppSpacing.sm),
          Text(
            'Figures are computed from unrounded values; minor one-paisa '
            'differences from rounded tables are expected. Payment-gateway '
            'charges, refunds, chargebacks and withholding taxes are excluded.',
            style: text.bodySmall?.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _PlanEconomicsCard extends StatelessWidget {
  const _PlanEconomicsCard({required this.plan});
  final SubscriptionPlan plan;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final e = plan.economics;
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(plan.durationLabel,
                  style: text.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w800)),
              const Spacer(),
              Text(formatInr(plan.priceInr),
                  style: text.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900, color: AppColors.primary)),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          const Divider(height: 1),
          const SizedBox(height: AppSpacing.sm),
          _Row('Customer price (incl. GST)', formatInr(e.priceInclGst)),
          _Row('GST included', formatInr(e.gstAmount)),
          _Row('Taxable (GST-exclusive) value', formatInr(e.taxableValue)),
          _Row('Referral incentive (5%)', formatInr(e.referralAmount),
              accent: AppColors.secondary),
          _Row('Company balance', formatInr(e.companyBalance),
              bold: true),
          const SizedBox(height: 4),
          _Row('Management (10%)', formatInr(e.managementAmount)),
          _Row('Strategic developer (5%)', formatInr(e.developerAmount)),
          _Row('Administration (5%)', formatInr(e.adminAmount)),
          _Row('BV base (80%)', formatInr(e.bvBase)),
          const SizedBox(height: 4),
          _Row('BV generated', '${e.bvPoints.toStringAsFixed(2)} BV',
              bold: true, accent: AppColors.primary),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row(this.label, this.value, {this.bold = false, this.accent});
  final String label;
  final String value;
  final bool bold;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(
            child: Text(label,
                style: text.bodyMedium?.copyWith(
                    fontWeight: bold ? FontWeight.w800 : FontWeight.w400)),
          ),
          Text(value,
              style: text.bodyMedium?.copyWith(
                  fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
                  color: accent)),
        ],
      ),
    );
  }
}

class _Kv extends StatelessWidget {
  const _Kv(this.k, this.v);
  final String k;
  final String v;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: Text(k, style: text.bodyMedium)),
          const SizedBox(width: AppSpacing.md),
          Text(v,
              style:
                  text.bodyMedium?.copyWith(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
