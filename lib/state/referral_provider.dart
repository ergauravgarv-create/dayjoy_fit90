import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/billing/subscription_plans.dart';
import 'prefs_provider.dart';
import 'providers.dart';

/// Deterministic, shareable referral code for a user id, e.g. FIT90-AB12CD.
String referralCodeFor(String uid) {
  const alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
  int h = 2166136261;
  for (final c in uid.codeUnits) {
    h = ((h ^ c) * 16777619) & 0x7fffffff;
  }
  final sb = StringBuffer();
  var x = h == 0 ? 1 : h;
  for (var i = 0; i < 6; i++) {
    sb.write(alphabet[x % 36]);
    x = (x ~/ 36) + (i + 7) * 13;
  }
  return 'FIT90-${sb.toString()}';
}

String referralLinkFor(String code) => 'https://fit90.in/ref/$code';

final referralCodeProvider = Provider<String>((ref) {
  final uid = ref.watch(authUidProvider) ?? 'demo-user';
  return referralCodeFor(uid);
});

final referralLinkProvider =
    Provider<String>((ref) => referralLinkFor(ref.watch(referralCodeProvider)));

// ===== Wallet ==============================================================

enum WalletTxnType { referralCredit, withdrawal, spend, reversal }

enum WalletTxnStatus { pending, approved, reversed, paid }

class WalletTxn {
  const WalletTxn({
    required this.id,
    required this.type,
    required this.amountInr,
    required this.note,
    required this.status,
    required this.createdAt,
    this.referredName,
    this.planId,
  });

  final String id;
  final WalletTxnType type;
  final double amountInr;
  final String note;
  final WalletTxnStatus status;
  final DateTime createdAt;

  /// For referral credits: who was referred and which plan they bought.
  final String? referredName;
  final String? planId;

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'amount': amountInr,
        'note': note,
        'status': status.name,
        'createdAt': createdAt.toIso8601String(),
        if (referredName != null) 'referredName': referredName,
        if (planId != null) 'planId': planId,
      };

  factory WalletTxn.fromJson(Map<String, dynamic> j) => WalletTxn(
        id: j['id'] as String? ?? '',
        type: WalletTxnType.values.firstWhere(
            (t) => t.name == j['type'],
            orElse: () => WalletTxnType.referralCredit),
        amountInr: (j['amount'] as num?)?.toDouble() ?? 0,
        note: j['note'] as String? ?? '',
        status: WalletTxnStatus.values.firstWhere(
            (s) => s.name == j['status'],
            orElse: () => WalletTxnStatus.approved),
        createdAt:
            DateTime.tryParse(j['createdAt'] as String? ?? '') ?? DateTime.now(),
        referredName: j['referredName'] as String?,
        planId: j['planId'] as String?,
      );
}

final walletProvider =
    NotifierProvider<WalletController, List<WalletTxn>>(WalletController.new);

class WalletController extends Notifier<List<WalletTxn>> {
  static const String _key = 'wallet_txns';

  @override
  List<WalletTxn> build() {
    final raw = ref.watch(sharedPreferencesProvider).getString(_key);
    if (raw == null || raw.isEmpty) return const [];
    try {
      return (jsonDecode(raw) as List)
          .map((e) => WalletTxn.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return const [];
    }
  }

  void _persist() {
    ref.read(sharedPreferencesProvider).setString(
        _key, jsonEncode(state.map((t) => t.toJson()).toList()));
  }

  String _id() => 'w${state.length}_${DateTime.now().microsecondsSinceEpoch}';

  /// Credit a referral incentive (5% of the referred plan's price). In
  /// production this fires from the backend after payment clears the
  /// refund/fraud-review window; here it's used to reflect confirmed referrals.
  void creditReferral(
    SubscriptionPlan plan, {
    String? referredName,
    WalletTxnStatus status = WalletTxnStatus.approved,
  }) {
    final txn = WalletTxn(
      id: _id(),
      type: WalletTxnType.referralCredit,
      amountInr: plan.economics.referralAmount,
      note: 'Referral incentive · ${plan.durationLabel} subscription',
      status: status,
      createdAt: DateTime.now(),
      referredName: referredName,
      planId: plan.id,
    );
    state = [txn, ...state];
    _persist();
  }

  /// Spend wallet balance (e.g. pay for a subscription renewal/upgrade).
  void spend(double amountInr, String note) {
    final txn = WalletTxn(
      id: _id(),
      type: WalletTxnType.spend,
      amountInr: amountInr,
      note: note,
      status: WalletTxnStatus.paid,
      createdAt: DateTime.now(),
    );
    state = [txn, ...state];
    _persist();
  }

  /// Record a withdrawal request (payout is processed by the Dayjoy team).
  void requestWithdrawal(double amountInr) {
    final txn = WalletTxn(
      id: _id(),
      type: WalletTxnType.withdrawal,
      amountInr: amountInr,
      note: 'Withdrawal to bank (under review)',
      status: WalletTxnStatus.pending,
      createdAt: DateTime.now(),
    );
    state = [txn, ...state];
    _persist();
  }
}

/// Derived wallet + referral figures for the UI.
class WalletSummary {
  const WalletSummary({
    required this.available,
    required this.pending,
    required this.approved,
    required this.reversed,
    required this.totalReferrals,
    required this.successfulReferrals,
  });

  final double available; // spendable / withdrawable
  final double pending; // referral credits awaiting review
  final double approved; // total approved referral incentive
  final double reversed; // reversed incentive
  final int totalReferrals;
  final int successfulReferrals;
}

final walletSummaryProvider = Provider<WalletSummary>((ref) {
  final txns = ref.watch(walletProvider);
  double available = 0, pending = 0, approved = 0, reversed = 0;
  int total = 0, successful = 0;
  for (final t in txns) {
    switch (t.type) {
      case WalletTxnType.referralCredit:
        total++;
        if (t.status == WalletTxnStatus.approved) {
          approved += t.amountInr;
          available += t.amountInr;
          successful++;
        } else if (t.status == WalletTxnStatus.pending) {
          pending += t.amountInr;
        } else if (t.status == WalletTxnStatus.reversed) {
          reversed += t.amountInr;
        }
        break;
      case WalletTxnType.reversal:
        reversed += t.amountInr;
        available -= t.amountInr;
        break;
      case WalletTxnType.withdrawal:
      case WalletTxnType.spend:
        // Pending withdrawals ring-fence the funds; paid ones remove them.
        available -= t.amountInr;
        break;
    }
  }
  return WalletSummary(
    available: available < 0 ? 0 : available,
    pending: pending,
    approved: approved,
    reversed: reversed,
    totalReferrals: total,
    successfulReferrals: successful,
  );
});

/// Minimum wallet balance required to withdraw to a bank account. KYC state
/// lives in kyc_provider.dart.
const double kMinWithdrawalInr = 1000;
