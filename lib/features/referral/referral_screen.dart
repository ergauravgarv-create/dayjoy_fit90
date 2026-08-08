import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/billing/subscription_plans.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../shared/widgets/animated_count.dart';
import '../../shared/widgets/app_snack.dart';
import '../../shared/widgets/glass_card.dart';
import '../../shared/widgets/section_header.dart';
import '../../state/kyc_provider.dart';
import '../../state/referral_provider.dart';
import 'kyc_screen.dart';
import 'referrals_report_screen.dart';
import 'wallet_statement_screen.dart';

class ReferralScreen extends ConsumerWidget {
  const ReferralScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final TextTheme text = Theme.of(context).textTheme;
    final code = ref.watch(referralCodeProvider);
    final link = ref.watch(referralLinkProvider);
    final summary = ref.watch(walletSummaryProvider);
    final txns = ref.watch(walletProvider);
    final kyc = ref.watch(kycProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Refer & earn')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.xxl),
        children: [
          const SizedBox(height: AppSpacing.md),

          // Wallet balance
          GlassCard(
            gradient: AppColors.brandGradient,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Fit90 Wallet',
                    style: TextStyle(color: Colors.white70, fontSize: 13)),
                const SizedBox(height: 4),
                AnimatedCount(
                  value: summary.available,
                  prefix: '₹',
                  decimals: 2,
                  thousands: true,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 34,
                      fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    _pill('Pending ₹${summary.pending.toStringAsFixed(2)}'),
                    const SizedBox(width: AppSpacing.sm),
                    _pill('Earned ₹${summary.approved.toStringAsFixed(2)}'),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppColors.primary),
                    onPressed: () => _withdraw(context, ref, summary.available),
                    icon: const Icon(Icons.account_balance_rounded, size: 18),
                    label: const Text('Withdraw to bank'),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    Icon(
                      kyc.isVerified
                          ? Icons.verified_rounded
                          : Icons.info_outline_rounded,
                      size: 14,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      switch (kyc.status) {
                        KycStatus.verified => 'KYC verified',
                        KycStatus.pending => 'KYC under review',
                        KycStatus.rejected => 'KYC failed — re-submit',
                        KycStatus.notStarted =>
                          'KYC required to withdraw (min ₹1,000)',
                      },
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Referral code
          const SectionHeader(title: 'Your referral code'),
          const SizedBox(height: AppSpacing.md),
          GlassCard(
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(color: AppColors.primary.withOpacity(0.25)),
                  ),
                  child: Center(
                    child: Text(code,
                        style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2,
                            color: AppColors.primary)),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(link,
                    style: text.bodySmall
                        ?.copyWith(color: AppColors.textSecondary)),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: code));
                          showAppSnack(context, 'Code copied!',
                              type: AppSnackType.success);
                        },
                        icon: const Icon(Icons.copy_rounded, size: 18),
                        label: const Text('Copy'),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _shareWhatsApp(context, code, link),
                        icon: const Icon(Icons.chat_rounded, size: 18),
                        label: const Text('WhatsApp'),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () => _shareSheet(code, link),
                        icon: const Icon(Icons.ios_share_rounded, size: 18),
                        label: const Text('Share'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Stats
          Row(
            children: [
              Expanded(
                  child: _StatCard(
                      value: '${summary.totalReferrals}', label: 'Referrals')),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                  child: _StatCard(
                      value: '${summary.successfulReferrals}',
                      label: 'Successful')),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                  child: _StatCard(
                      value: '₹${summary.pending.toStringAsFixed(0)}',
                      label: 'Pending')),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                    builder: (_) => const ReferralsReportScreen()),
              ),
              icon: const Icon(Icons.people_alt_rounded, size: 18),
              label: const Text('See who you referred & earnings'),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Earn table
          const SectionHeader(title: 'Earn 5% on every plan'),
          const SizedBox(height: AppSpacing.md),
          GlassCard(
            child: Column(
              children: [
                for (final p in kPlans)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    child: Row(
                      children: [
                        Expanded(
                            child: Text('${p.durationLabel} · '
                                '${formatInr(p.priceInr)}')),
                        Text(
                          '+ ${formatInr(p.economics.referralAmount)}',
                          style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              color: AppColors.primary),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _rulesCard(context, text),
          const SizedBox(height: AppSpacing.lg),

          // Activity
          SectionHeader(
            title: 'Wallet activity',
            action: TextButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                    builder: (_) => const WalletStatementScreen()),
              ),
              child: const Text('Full statement'),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          if (txns.isEmpty)
            GlassCard(
              child: Row(
                children: [
                  const Icon(Icons.receipt_long_rounded,
                      color: AppColors.textSecondary),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      'No activity yet. Share your code — you earn 5% when a '
                      'friend buys their first subscription.',
                      style: text.bodySmall,
                    ),
                  ),
                ],
              ),
            )
          else
            GlassCard(
              child: Column(
                children: [
                  for (final t in txns) _TxnRow(txn: t),
                ],
              ),
            ),

          const SizedBox(height: AppSpacing.lg),
          // Demo helper (remove for production): lets you see a credited referral.
          Center(
            child: TextButton.icon(
              onPressed: () {
                const names = [
                  'Aarav Sharma',
                  'Diya Patel',
                  'Kabir Singh',
                  'Ananya Reddy',
                  'Vivaan Nair',
                  'Ishita Gupta',
                ];
                final n = ref.read(walletProvider).length;
                ref.read(walletProvider.notifier).creditReferral(
                      kPlans[1],
                      referredName: names[n % names.length],
                    );
                showAppSnack(context,
                    'Demo: a 3-month referral was credited (₹134.95).',
                    type: AppSnackType.info);
              },
              icon: const Icon(Icons.science_rounded, size: 16),
              label: const Text('Demo: simulate a successful referral'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _pill(String s) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        child: Text(s,
            style: const TextStyle(
                color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
      );

  Widget _rulesCard(BuildContext context, TextTheme text) {
    return GlassCard(
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: EdgeInsets.zero,
          childrenPadding: const EdgeInsets.only(bottom: AppSpacing.sm),
          leading: const Icon(Icons.info_outline_rounded,
              color: AppColors.primary),
          title: Text('How it works & rules',
              style: text.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
          children: const [
            _Rule('You get 5% of the GST-inclusive price when a friend buys their first subscription.'),
            _Rule('The new subscriber gets no cashback.'),
            _Rule('Single-level only — there are no multi-level commissions.'),
            _Rule('No limit on valid direct referrals or legitimate earnings.'),
            _Rule('Renewals don’t qualify unless a separate campaign runs.'),
            _Rule('Referral must be attributed before the first payment.'),
            _Rule('Self-referrals and duplicate accounts are not allowed.'),
            _Rule('Refunded or charged-back subscriptions are reversed.'),
            _Rule('Bank withdrawal needs KYC, a verified account and a minimum ₹1,000 balance.'),
          ],
        ),
      ),
    );
  }

  String _shareText(String code, String link) =>
      'Join me on Dayjoy Fit90 — personalized diet, workouts and doctor/trainer '
      'consultations. Use my code $code and get started: $link';

  void _shareSheet(String code, String link) {
    Share.share(_shareText(code, link),
        subject: 'Join me on Dayjoy Fit90');
  }

  Future<void> _shareWhatsApp(
      BuildContext context, String code, String link) async {
    final uri = Uri.parse(
        'https://wa.me/?text=${Uri.encodeComponent(_shareText(code, link))}');
    try {
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok && context.mounted) {
        showAppSnack(context, 'Could not open WhatsApp.',
            type: AppSnackType.error);
      }
    } catch (_) {
      if (context.mounted) {
        showAppSnack(context, 'Could not open WhatsApp.',
            type: AppSnackType.error);
      }
    }
  }

  Future<void> _withdraw(
      BuildContext context, WidgetRef ref, double available) async {
    if (!ref.read(kycVerifiedProvider)) {
      final go = await showDialog<bool>(
        context: context,
        builder: (dctx) => AlertDialog(
          backgroundColor: AppColors.surfaceOf(dctx),
          title: const Text('KYC required'),
          content: const Text(
              'Bank/UPI withdrawals require completed KYC verification. '
              'Verify your identity to continue.'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(dctx, false),
                child: const Text('Later')),
            FilledButton(
                onPressed: () => Navigator.pop(dctx, true),
                child: const Text('Verify now')),
          ],
        ),
      );
      if (go == true && context.mounted) {
        Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const KycScreen()),
        );
      }
      return;
    }
    if (available < kMinWithdrawalInr) {
      showAppSnack(context,
          'Minimum ${formatInr(kMinWithdrawalInr, decimals: 0)} balance needed to withdraw.',
          type: AppSnackType.info);
      return;
    }
    final yes = await showDialog<bool>(
      context: context,
      builder: (dctx) => AlertDialog(
        backgroundColor: AppColors.surfaceOf(dctx),
        title: const Text('Withdraw to bank'),
        content: Text(
            'Request a payout of ${formatInr(available)} to your verified bank '
            'account? The Dayjoy team processes payouts after the review period.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dctx, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(dctx, true),
              child: const Text('Request payout')),
        ],
      ),
    );
    if (yes == true) {
      ref.read(walletProvider.notifier).requestWithdrawal(available);
      if (context.mounted) {
        showAppSnack(context, 'Withdrawal requested — under review.',
            type: AppSnackType.success);
      }
    }
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.value, required this.label});
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return GlassCard(
      padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.md, horizontal: AppSpacing.sm),
      child: Column(
        children: [
          Text(value,
              style: text.titleLarge?.copyWith(
                  fontWeight: FontWeight.w900, color: AppColors.primary)),
          const SizedBox(height: 2),
          Text(label,
              style: text.bodySmall, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class _Rule extends StatelessWidget {
  const _Rule(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_rounded, size: 16, color: AppColors.primary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
              child: Text(text,
                  style: Theme.of(context).textTheme.bodySmall)),
        ],
      ),
    );
  }
}

class _TxnRow extends StatelessWidget {
  const _TxnRow({required this.txn});
  final WalletTxn txn;

  @override
  Widget build(BuildContext context) {
    final bool credit = txn.type == WalletTxnType.referralCredit &&
        txn.status != WalletTxnStatus.reversed;
    final Color c = switch (txn.status) {
      WalletTxnStatus.approved => AppColors.success,
      WalletTxnStatus.pending => AppColors.orange,
      WalletTxnStatus.reversed => AppColors.error,
      WalletTxnStatus.paid => AppColors.primary,
    };
    final sign = credit ? '+' : '−';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(
            credit ? Icons.south_west_rounded : Icons.north_east_rounded,
            size: 18,
            color: c,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(txn.note,
                    style: Theme.of(context).textTheme.bodyMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                Text(
                  '${DateFormat('d MMM, h:mm a').format(txn.createdAt)} · ${txn.status.name}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          Text('$sign${formatInr(txn.amountInr)}',
              style: TextStyle(fontWeight: FontWeight.w800, color: c)),
        ],
      ),
    );
  }
}
