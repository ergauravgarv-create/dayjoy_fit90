import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'prefs_provider.dart';

enum KycStatus { notStarted, pending, verified, rejected }

/// KYC record for wallet withdrawals. Only masked identifiers are kept on the
/// device — full PAN / bank details must live server-side in production.
class KycInfo {
  const KycInfo({
    this.status = KycStatus.notStarted,
    this.fullName = '',
    this.panMasked = '',
    this.payoutLabel = '',
    this.submittedAt,
  });

  final KycStatus status;
  final String fullName;
  final String panMasked; // e.g. AB••••1C
  final String payoutLabel; // e.g. "HDFC ••1234" or "name@upi"
  final DateTime? submittedAt;

  bool get isVerified => status == KycStatus.verified;

  KycInfo copyWith({KycStatus? status}) => KycInfo(
        status: status ?? this.status,
        fullName: fullName,
        panMasked: panMasked,
        payoutLabel: payoutLabel,
        submittedAt: submittedAt,
      );

  Map<String, dynamic> toJson() => {
        'status': status.name,
        'fullName': fullName,
        'panMasked': panMasked,
        'payoutLabel': payoutLabel,
        'submittedAt': submittedAt?.toIso8601String(),
      };

  factory KycInfo.fromJson(Map<String, dynamic> j) => KycInfo(
        status: KycStatus.values.firstWhere((s) => s.name == j['status'],
            orElse: () => KycStatus.notStarted),
        fullName: j['fullName'] as String? ?? '',
        panMasked: j['panMasked'] as String? ?? '',
        payoutLabel: j['payoutLabel'] as String? ?? '',
        submittedAt: DateTime.tryParse(j['submittedAt'] as String? ?? ''),
      );
}

/// Mask a PAN (ABCDE1234F) → AB••••4F. Falls back gracefully for short input.
String maskPan(String pan) {
  final p = pan.trim().toUpperCase();
  if (p.length < 4) return '••';
  return '${p.substring(0, 2)}••••${p.substring(p.length - 2)}';
}

/// Mask an account number / UPI id for display. Keeps UPI handle visible;
/// masks all but the last 4 digits of an account number.
String maskPayout(String value, {required bool isUpi, String? bankName}) {
  final v = value.trim();
  if (isUpi) return v; // UPI ids are not secret like an account number
  final last4 = v.length >= 4 ? v.substring(v.length - 4) : v;
  final label = bankName == null || bankName.isEmpty ? 'Bank' : bankName;
  return '$label ••$last4';
}

final kycProvider =
    NotifierProvider<KycController, KycInfo>(KycController.new);

class KycController extends Notifier<KycInfo> {
  static const String _key = 'kyc_info';

  @override
  KycInfo build() {
    final raw = ref.watch(sharedPreferencesProvider).getString(_key);
    if (raw == null || raw.isEmpty) return const KycInfo();
    try {
      return KycInfo.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return const KycInfo();
    }
  }

  void _persist(KycInfo info) => ref
      .read(sharedPreferencesProvider)
      .setString(_key, jsonEncode(info.toJson()));

  /// Submit KYC. Full [pan] / [payoutValue] are masked before storage; in
  /// production they'd be sent securely to the backend for verification.
  void submit({
    required String fullName,
    required String pan,
    required bool isUpi,
    required String payoutValue,
    String? bankName,
  }) {
    final info = KycInfo(
      status: KycStatus.pending,
      fullName: fullName.trim(),
      panMasked: maskPan(pan),
      payoutLabel: maskPayout(payoutValue, isUpi: isUpi, bankName: bankName),
      submittedAt: DateTime.now(),
    );
    state = info;
    _persist(info);
  }

  /// Demo-only: approve a pending KYC. In production the backend flips this.
  void markVerified() {
    if (state.status == KycStatus.notStarted) return;
    state = state.copyWith(status: KycStatus.verified);
    _persist(state);
  }

  void reset() {
    state = const KycInfo();
    _persist(state);
  }
}

/// Whether the user can withdraw (KYC verified).
final kycVerifiedProvider =
    Provider<bool>((ref) => ref.watch(kycProvider).isVerified);
