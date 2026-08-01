import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_constants.dart';
import '../../core/env/app_config.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../state/providers.dart';

/// Phone-number entry. Calls [AuthController.sendOtp] (Firebase
/// `verifyPhoneNumber` in live mode; instant in mock mode), then advances to
/// the OTP screen when the code is sent.
class PhoneLoginScreen extends ConsumerStatefulWidget {
  const PhoneLoginScreen({super.key});

  @override
  ConsumerState<PhoneLoginScreen> createState() => _PhoneLoginScreenState();
}

class _PhoneLoginScreenState extends ConsumerState<PhoneLoginScreen> {
  final TextEditingController _phone = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _phone.dispose();
    super.dispose();
  }

  bool get _valid => _phone.text.trim().length == 10;

  Future<void> _send() async {
    if (!_valid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please enter a valid 10-digit mobile number.')),
      );
      return;
    }
    setState(() => _sending = true);
    await ref
        .read(authControllerProvider.notifier)
        .sendOtp('+91 ${_phone.text}');
    if (!mounted) return;
    setState(() => _sending = false);

    final AuthState st = ref.read(authControllerProvider);
    if (st.status == AuthStatus.codeSent) {
      context.push(Routes.otp, extra: st.phone);
    } else if (st.status == AuthStatus.error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(st.error ?? 'Could not send OTP')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final l = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(),
      body: Padding(
        padding: AppSpacing.page,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: AppSpacing.lg),
            Text(l.loginTitle(AppConstants.appName), style: text.displaySmall),
            const SizedBox(height: AppSpacing.sm),
            Text(l.loginSubtitle, style: text.bodyMedium),
            const SizedBox(height: AppSpacing.xxl),
            TextField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              maxLength: 10,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                counterText: '',
                errorText: (_phone.text.isNotEmpty && !_valid)
                    ? 'Enter a 10-digit mobile number'
                    : null,
                prefixIcon: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 14),
                  child: Text('🇮🇳  +91',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w600)),
                ),
                prefixIconConstraints:
                    const BoxConstraints(minWidth: 0, minHeight: 0),
                hintText: l.mobileHint,
              ),
            ),
            if (AppConfig.isMock) ...[
              const SizedBox(height: AppSpacing.xl),
              const _DemoRolePicker(),
            ],
            const Spacer(),
            FilledButton(
              onPressed: (_sending || !_valid) ? null : _send,
              child: _sending
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : Text(l.actionSendOtp),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              l.loginConsent,
              style: text.bodySmall?.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
        ),
      ),
    );
  }
}

/// Demo helper (mock mode only): choose which role to sign in as so the
/// coach / doctor / admin dashboards are reachable without a real backend.
class _DemoRolePicker extends ConsumerWidget {
  const _DemoRolePicker();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final selected = ref.watch(demoRoleProvider);
    final roles = <(UserRole, String)>[
      (UserRole.participant, l.roleParticipant),
      (UserRole.coach, l.roleCoach),
      (UserRole.doctor, l.roleDoctor),
      (UserRole.admin, l.roleAdmin),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l.demoSignInAs, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          children: [
            for (final (role, label) in roles)
              ChoiceChip(
                label: Text(label),
                selected: selected == role,
                labelStyle: TextStyle(
                  color: selected == role
                      ? Colors.white
                      : AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
                onSelected: (_) =>
                    ref.read(demoRoleProvider.notifier).set(role),
              ),
          ],
        ),
      ],
    );
  }
}
