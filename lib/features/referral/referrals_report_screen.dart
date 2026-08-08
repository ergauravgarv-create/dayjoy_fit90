import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/billing/subscription_plans.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/glass_card.dart';
import '../../state/referral_provider.dart';

/// A report of the people the user has referred and the incentive earned from
/// each of their subscriptions.
class ReferralsReportScreen extends ConsumerWidget {
  const ReferralsReportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final TextTheme text = Theme.of(context).textTheme;
    final txns = ref.watch(walletProvider);
    final summary = ref.watch(walletSummaryProvider);

    final referrals = txns
        .where((t) => t.type == WalletTxnType.referralCredit)
        .toList(); // already newest-first

    return Scaffold(
      appBar: AppBar(title: const Text('My referrals')),
      body: referrals.isEmpty
          ? EmptyState(
              icon: Icons.group_add_rounded,
              title: 'No referrals yet',
              message:
                  'Share your code — when a friend buys their first subscription '
                  'you earn 5%, and they’ll show up here.',
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.xxl),
              children: [
                // Summary
                GlassCard(
                  gradient: AppColors.brandGradient,
                  child: Row(
                    children: [
                      Expanded(
                        child: _Metric(
                          value: '${summary.successfulReferrals}',
                          label: 'Successful',
                        ),
                      ),
                      _divider(),
                      Expanded(
                        child: _Metric(
                          value: formatInr(summary.approved),
                          label: 'Earned',
                        ),
                      ),
                      _divider(),
                      Expanded(
                        child: _Metric(
                          value: formatInr(summary.pending),
                          label: 'Pending',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                Text('${referrals.length} referral'
                    '${referrals.length == 1 ? '' : 's'}',
                    style: text.titleMedium),
                const SizedBox(height: AppSpacing.md),

                for (final t in referrals)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: _ReferralRow(txn: t),
                  ),
              ],
            ),
    );
  }

  Widget _divider() => Container(
      width: 1, height: 34, color: Colors.white.withOpacity(0.25));
}

class _Metric extends StatelessWidget {
  const _Metric({required this.value, required this.label});
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w900)),
        const SizedBox(height: 2),
        Text(label,
            style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 12)),
      ],
    );
  }
}

class _ReferralRow extends StatelessWidget {
  const _ReferralRow({required this.txn});
  final WalletTxn txn;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final String name = txn.referredName ?? 'Referred friend';
    final plan = txn.planId != null ? planById(txn.planId!) : null;
    final String planLabel = plan?.title ?? plan?.durationLabel ?? 'Subscription';

    final Color c = switch (txn.status) {
      WalletTxnStatus.approved => AppColors.success,
      WalletTxnStatus.pending => AppColors.orange,
      WalletTxnStatus.reversed => AppColors.error,
      WalletTxnStatus.paid => AppColors.primary,
    };
    final String statusLabel = switch (txn.status) {
      WalletTxnStatus.approved => 'Credited',
      WalletTxnStatus.pending => 'Pending',
      WalletTxnStatus.reversed => 'Reversed',
      WalletTxnStatus.paid => 'Paid',
    };

    return GlassCard(
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: AppColors.primary.withOpacity(0.15),
            child: Text(
              name.characters.first.toUpperCase(),
              style: const TextStyle(
                  color: AppColors.primary, fontWeight: FontWeight.w800),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: text.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w700),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                Text(
                  '$planLabel · ${DateFormat('d MMM yyyy').format(txn.createdAt)}',
                  style: text.bodySmall
                      ?.copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${txn.status == WalletTxnStatus.reversed ? '−' : '+'}${formatInr(txn.amountInr)}',
                style: TextStyle(
                    fontWeight: FontWeight.w900,
                    color: txn.status == WalletTxnStatus.reversed
                        ? AppColors.error
                        : AppColors.primary),
              ),
              const SizedBox(height: 2),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: c.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Text(statusLabel,
                    style: TextStyle(
                        color: c,
                        fontSize: 10,
                        fontWeight: FontWeight.w800)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
