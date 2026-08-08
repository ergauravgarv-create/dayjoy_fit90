import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../shared/widgets/app_snack.dart';
import '../../shared/widgets/glass_card.dart';
import '../../shared/widgets/section_header.dart';
import '../../state/kyc_provider.dart';

/// KYC verification required before wallet withdrawal. The user enters their own
/// details; only masked identifiers are stored on the device.
class KycScreen extends ConsumerStatefulWidget {
  const KycScreen({super.key});

  @override
  ConsumerState<KycScreen> createState() => _KycScreenState();
}

class _KycScreenState extends ConsumerState<KycScreen> {
  final _name = TextEditingController();
  final _pan = TextEditingController();
  final _payout = TextEditingController();
  final _bank = TextEditingController();
  bool _isUpi = true;
  bool _consent = false;

  @override
  void dispose() {
    _name.dispose();
    _pan.dispose();
    _payout.dispose();
    _bank.dispose();
    super.dispose();
  }

  bool get _panValid =>
      RegExp(r'^[A-Za-z]{5}[0-9]{4}[A-Za-z]$').hasMatch(_pan.text.trim());

  void _submit() {
    if (_name.text.trim().isEmpty) {
      showAppSnack(context, 'Enter your full name (as per PAN).',
          type: AppSnackType.info);
      return;
    }
    if (!_panValid) {
      showAppSnack(context, 'Enter a valid PAN (e.g. ABCDE1234F).',
          type: AppSnackType.info);
      return;
    }
    if (_payout.text.trim().isEmpty) {
      showAppSnack(context, 'Enter your payout details.',
          type: AppSnackType.info);
      return;
    }
    if (!_isUpi && _bank.text.trim().isEmpty) {
      showAppSnack(context, 'Enter your bank name.', type: AppSnackType.info);
      return;
    }
    if (!_consent) {
      showAppSnack(context, 'Please provide consent to continue.',
          type: AppSnackType.info);
      return;
    }
    ref.read(kycProvider.notifier).submit(
          fullName: _name.text,
          pan: _pan.text,
          isUpi: _isUpi,
          payoutValue: _payout.text,
          bankName: _isUpi ? null : _bank.text,
        );
    showAppSnack(context, 'KYC submitted for verification.',
        type: AppSnackType.success);
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final kyc = ref.watch(kycProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('KYC verification')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.xxl),
        children: [
          const SizedBox(height: AppSpacing.md),

          if (kyc.status != KycStatus.notStarted) _StatusBanner(kyc: kyc),

          if (kyc.status == KycStatus.verified) ...[
            const SizedBox(height: AppSpacing.md),
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _row('Name', kyc.fullName),
                  _row('PAN', kyc.panMasked),
                  _row('Payout to', kyc.payoutLabel),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            OutlinedButton.icon(
              onPressed: () => ref.read(kycProvider.notifier).reset(),
              icon: const Icon(Icons.edit_rounded, size: 18),
              label: const Text('Update details'),
            ),
          ] else ...[
            const SizedBox(height: AppSpacing.md),
            Text('Verify your identity to withdraw wallet earnings to your bank '
                'or UPI. Your details are used only for payouts.',
                style: text.bodyMedium),
            const SizedBox(height: AppSpacing.lg),

            const SectionHeader(title: 'Your details'),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _name,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                  labelText: 'Full name (as per PAN)'),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _pan,
              textCapitalization: TextCapitalization.characters,
              inputFormatters: [
                LengthLimitingTextInputFormatter(10),
                FilteringTextInputFormatter.allow(RegExp('[A-Za-z0-9]')),
              ],
              decoration: const InputDecoration(
                  labelText: 'PAN', hintText: 'ABCDE1234F'),
            ),
            const SizedBox(height: AppSpacing.lg),

            const SectionHeader(title: 'Payout method'),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: _Toggle(
                    label: 'UPI',
                    selected: _isUpi,
                    onTap: () => setState(() => _isUpi = true),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: _Toggle(
                    label: 'Bank account',
                    selected: !_isUpi,
                    onTap: () => setState(() => _isUpi = false),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            if (!_isUpi) ...[
              TextField(
                controller: _bank,
                decoration: const InputDecoration(labelText: 'Bank name'),
              ),
              const SizedBox(height: AppSpacing.md),
            ],
            TextField(
              controller: _payout,
              keyboardType:
                  _isUpi ? TextInputType.emailAddress : TextInputType.number,
              inputFormatters: _isUpi
                  ? null
                  : [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                labelText: _isUpi ? 'UPI ID' : 'Account number',
                hintText: _isUpi ? 'name@bank' : null,
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            CheckboxListTile(
              value: _consent,
              onChanged: (v) => setState(() => _consent = v ?? false),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
              title: Text(
                'I confirm these details are mine and consent to their use for '
                'payouts and verification.',
                style: text.bodySmall,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            FilledButton(
              onPressed: _submit,
              child: const Text('Submit for verification'),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Only masked details are stored on your device. Verification is '
              'completed by the Dayjoy team.',
              style: text.bodySmall?.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],

          // Demo-only: simulate the backend approving a pending KYC.
          if (kyc.status == KycStatus.pending) ...[
            const SizedBox(height: AppSpacing.lg),
            Center(
              child: TextButton.icon(
                onPressed: () => ref.read(kycProvider.notifier).markVerified(),
                icon: const Icon(Icons.verified_rounded, size: 16),
                label: const Text('Demo: mark verified'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _row(String k, String v) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            SizedBox(
                width: 90,
                child: Text(k,
                    style: TextStyle(color: AppColors.textSecondary))),
            Expanded(
                child: Text(v,
                    style: const TextStyle(fontWeight: FontWeight.w700))),
          ],
        ),
      );
}

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({required this.kyc});
  final KycInfo kyc;

  @override
  Widget build(BuildContext context) {
    final (Color c, IconData icon, String label) = switch (kyc.status) {
      KycStatus.verified => (
          AppColors.success,
          Icons.verified_rounded,
          'KYC verified — you can withdraw.'
        ),
      KycStatus.pending => (
          AppColors.orange,
          Icons.hourglass_top_rounded,
          'KYC under review.'
        ),
      KycStatus.rejected => (
          AppColors.error,
          Icons.error_rounded,
          'KYC could not be verified. Please re-submit.'
        ),
      KycStatus.notStarted => (
          AppColors.info,
          Icons.info_rounded,
          'KYC required to withdraw.'
        ),
    };
    return GlassCard(
      child: Row(
        children: [
          Icon(icon, color: c),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(fontWeight: FontWeight.w700)),
                if (kyc.submittedAt != null)
                  Text(
                    'Submitted ${DateFormat('d MMM yyyy').format(kyc.submittedAt!)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Toggle extends StatelessWidget {
  const _Toggle(
      {required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: selected ? AppColors.brandGradient : null,
          color: selected
              ? null
              : (isDark ? AppColors.surfaceMutedDark : AppColors.surfaceMuted),
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Text(label,
            style: TextStyle(
                color: selected ? Colors.white : null,
                fontWeight: FontWeight.w700)),
      ),
    );
  }
}
