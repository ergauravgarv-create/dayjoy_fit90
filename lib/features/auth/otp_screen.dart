import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_constants.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../state/providers.dart';

/// 6-box OTP entry. On "verify" it signs the mock participant in and enters
/// the app shell.
class OtpScreen extends ConsumerStatefulWidget {
  const OtpScreen({super.key, required this.mobile});

  final String mobile;

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen> {
  final List<TextEditingController> _controllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _nodes = List.generate(6, (_) => FocusNode());

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    for (final n in _nodes) {
      n.dispose();
    }
    super.dispose();
  }

  String get _code => _controllers.map((c) => c.text).join();
  bool _verifying = false;

  Future<void> _verify() async {
    setState(() => _verifying = true);
    final bool ok =
        await ref.read(authControllerProvider.notifier).verifyOtp(_code);
    if (!mounted) return;
    setState(() => _verifying = false);
    if (ok) {
      final auth = ref.read(authControllerProvider);
      if (auth.role == UserRole.participant && auth.needsRegistration) {
        context.go(Routes.register);
      } else {
        context.go(Routes.forRole(auth.role));
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ref.read(authControllerProvider).error ??
              AppLocalizations.of(context).otpInvalid),
        ),
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
            Text(l.otpTitle, style: text.headlineSmall),
            const SizedBox(height: AppSpacing.sm),
            Text(l.otpSubtitle(widget.mobile), style: text.bodyMedium),
            const SizedBox(height: AppSpacing.xxl),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                for (int i = 0; i < 6; i++)
                  SizedBox(
                    width: 48,
                    child: TextField(
                      controller: _controllers[i],
                      focusNode: _nodes[i],
                      textAlign: TextAlign.center,
                      keyboardType: TextInputType.number,
                      maxLength: 1,
                      style: const TextStyle(
                          fontSize: 22, fontWeight: FontWeight.w700),
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly
                      ],
                      decoration: const InputDecoration(counterText: ''),
                      onChanged: (v) {
                        if (v.isNotEmpty && i < 5) {
                          _nodes[i + 1].requestFocus();
                        } else if (v.isEmpty && i > 0) {
                          _nodes[i - 1].requestFocus();
                        }
                        setState(() {});
                      },
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            Row(
              children: [
                Text(l.otpDidntGetCode, style: text.bodySmall),
                Text(l.otpResendIn('0:28'),
                    style: text.bodySmall
                        ?.copyWith(color: AppColors.primary)),
              ],
            ),
            const Spacer(),
            FilledButton(
              onPressed: _verifying ? null : _verify,
              child: _verifying
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : Text(l.actionVerify),
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
        ),
      ),
    );
  }
}
