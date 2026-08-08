import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/billing/subscription_plans.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/glass_card.dart';
import '../../state/referral_provider.dart';

enum _Filter { all, credits, spends, withdrawals, reversals }

/// The signed change a transaction makes to the available balance — mirrors
/// walletSummaryProvider so the running balance matches the wallet.
double _delta(WalletTxn t) {
  switch (t.type) {
    case WalletTxnType.referralCredit:
      return t.status == WalletTxnStatus.approved ? t.amountInr : 0;
    case WalletTxnType.reversal:
      return -t.amountInr;
    case WalletTxnType.withdrawal:
    case WalletTxnType.spend:
      return -t.amountInr;
  }
}

class WalletStatementScreen extends ConsumerStatefulWidget {
  const WalletStatementScreen({super.key});

  @override
  ConsumerState<WalletStatementScreen> createState() =>
      _WalletStatementScreenState();
}

class _WalletStatementScreenState
    extends ConsumerState<WalletStatementScreen> {
  _Filter _filter = _Filter.all;

  bool _matches(WalletTxn t) => switch (_filter) {
        _Filter.all => true,
        _Filter.credits => t.type == WalletTxnType.referralCredit,
        _Filter.spends => t.type == WalletTxnType.spend,
        _Filter.withdrawals => t.type == WalletTxnType.withdrawal,
        _Filter.reversals =>
          t.type == WalletTxnType.reversal ||
              (t.type == WalletTxnType.referralCredit &&
                  t.status == WalletTxnStatus.reversed),
      };

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final txns = ref.watch(walletProvider); // newest-first
    final summary = ref.watch(walletSummaryProvider);

    // Running balance computed over the full chronological history.
    final chrono = txns.reversed.toList();
    final balAfter = <String, double>{};
    double bal = 0;
    for (final t in chrono) {
      bal += _delta(t);
      balAfter[t.id] = bal;
    }

    final shown = txns.where(_matches).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Wallet statement'),
        actions: [
          if (txns.isNotEmpty)
            IconButton(
              tooltip: 'Share statement',
              icon: const Icon(Icons.ios_share_rounded),
              onPressed: () => _share(txns, balAfter, summary.available),
            ),
        ],
      ),
      body: txns.isEmpty
          ? const EmptyState(
              icon: Icons.receipt_long_rounded,
              title: 'No transactions yet',
              message:
                  'Referral credits, subscription payments and withdrawals will '
                  'appear here.',
            )
          : Column(
              children: [
                // Balance summary
                Padding(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.lg,
                      AppSpacing.md, AppSpacing.lg, AppSpacing.sm),
                  child: GlassCard(
                    gradient: AppColors.brandGradient,
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Available balance',
                                  style: TextStyle(
                                      color: Colors.white70, fontSize: 12)),
                              Text(formatInr(summary.available),
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 26,
                                      fontWeight: FontWeight.w900)),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('Earned ${formatInr(summary.approved)}',
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 12)),
                            Text('Pending ${formatInr(summary.pending)}',
                                style: const TextStyle(
                                    color: Colors.white70, fontSize: 12)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // Filters
                SizedBox(
                  height: 44,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg),
                    children: [
                      for (final f in _Filter.values)
                        Padding(
                          padding: const EdgeInsets.only(right: AppSpacing.sm),
                          child: ChoiceChip(
                            label: Text(_filterLabel(f)),
                            selected: _filter == f,
                            labelStyle: TextStyle(
                              color: _filter == f
                                  ? Colors.white
                                  : AppColors.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                            onSelected: (_) => setState(() => _filter = f),
                          ),
                        ),
                    ],
                  ),
                ),

                Expanded(
                  child: shown.isEmpty
                      ? Center(
                          child: Text('No ${_filterLabel(_filter).toLowerCase()}',
                              style: text.bodyMedium))
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(AppSpacing.lg,
                              AppSpacing.sm, AppSpacing.lg, AppSpacing.xxl),
                          itemCount: shown.length,
                          separatorBuilder: (_, __) =>
                              const Divider(height: AppSpacing.lg),
                          itemBuilder: (_, i) => _Row(
                            txn: shown[i],
                            balanceAfter: balAfter[shown[i].id] ?? 0,
                          ),
                        ),
                ),
              ],
            ),
    );
  }

  String _filterLabel(_Filter f) => switch (f) {
        _Filter.all => 'All',
        _Filter.credits => 'Credits',
        _Filter.spends => 'Payments',
        _Filter.withdrawals => 'Withdrawals',
        _Filter.reversals => 'Reversals',
      };

  void _share(List<WalletTxn> txns, Map<String, double> balAfter,
      double available) {
    final b = StringBuffer()
      ..writeln('Dayjoy Fit90 — Wallet statement')
      ..writeln('Available balance: ${formatInr(available)}')
      ..writeln('');
    for (final t in txns) {
      final sign = _delta(t) < 0 ? '-' : (_delta(t) > 0 ? '+' : ' ');
      b.writeln('${DateFormat('d MMM yyyy').format(t.createdAt)}  '
          '$sign${formatInr(t.amountInr)}  ${t.note} '
          '(${t.status.name}) → ${formatInr(balAfter[t.id] ?? 0)}');
    }
    Share.share(b.toString(), subject: 'Dayjoy Fit90 wallet statement');
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.txn, required this.balanceAfter});
  final WalletTxn txn;
  final double balanceAfter;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final double d = _delta(txn);
    final bool credit = d > 0;
    final bool pending = txn.type == WalletTxnType.referralCredit &&
        txn.status == WalletTxnStatus.pending;

    final Color amtColor = pending
        ? AppColors.orange
        : (credit ? AppColors.success : AppColors.error);
    final String amtStr =
        '${credit ? '+' : (d < 0 ? '−' : '')}${formatInr(txn.amountInr)}';

    final IconData icon = switch (txn.type) {
      WalletTxnType.referralCredit => Icons.group_add_rounded,
      WalletTxnType.spend => Icons.workspace_premium_rounded,
      WalletTxnType.withdrawal => Icons.account_balance_rounded,
      WalletTxnType.reversal => Icons.undo_rounded,
    };

    return Row(
      children: [
        CircleAvatar(
          radius: 18,
          backgroundColor: amtColor.withOpacity(0.14),
          child: Icon(icon, size: 18, color: amtColor),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(txn.note,
                  style: text.bodyMedium, maxLines: 1,
                  overflow: TextOverflow.ellipsis),
              Text(
                '${DateFormat('d MMM yyyy, h:mm a').format(txn.createdAt)}'
                '${pending ? ' · pending' : ''}',
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
            Text(amtStr,
                style: TextStyle(
                    fontWeight: FontWeight.w800, color: amtColor)),
            Text('Bal ${formatInr(balanceAfter)}',
                style: text.bodySmall
                    ?.copyWith(color: AppColors.textSecondary)),
          ],
        ),
      ],
    );
  }
}
