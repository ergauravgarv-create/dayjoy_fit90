import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/billing/subscription_plans.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../shared/widgets/app_snack.dart';
import '../../shared/widgets/glass_card.dart';
import '../../shared/widgets/section_header.dart';
import '../../state/referral_provider.dart';
import '../../state/subscription_provider.dart';

/// Premium benefits (approved list, section 4).
const List<String> _benefits = [
  'Unlimited doctor consultations (subject to availability)',
  'Unlimited trainer consultations (subject to availability)',
  'Personalized diet charts & revisions',
  'Indian food, calorie & macro tracking',
  'Personalized exercise, yoga & Zumba plans',
  'Metabolic & lifestyle activity plans',
  'Doctor-reviewed health guidance',
  'AI-assisted face & skin wellness analysis',
  'Personalized skincare recommendations',
  'Product & supplement recommendations',
  'Weight, measurement & progress tracking',
  'Updated recommendations as your data changes',
  'All present & future Fit90 premium features',
];

class SubscriptionScreen extends ConsumerStatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  ConsumerState<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends ConsumerState<SubscriptionScreen> {
  // Default to the "Most Popular" plan.
  String _selectedId = '3m';

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final sub = ref.watch(subscriptionProvider);
    final plan = planById(_selectedId) ?? kPlans.first;
    final double wallet = ref.watch(walletSummaryProvider).available;

    return Scaffold(
      appBar: AppBar(title: const Text('Dayjoy Fit90 Premium')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.xxl),
        children: [
          const SizedBox(height: AppSpacing.md),

          if (sub != null && sub.isActive) ...[
            _ActiveBanner(sub: sub),
            const _AutoRenewCard(),
          ],

          Text('Choose your plan', style: text.titleLarge),
          const SizedBox(height: 4),
          Text(
            'One subscription unlocks everything — consultations, diet, workouts, '
            'skin analysis and more.',
            style: text.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.lg),

          for (final p in kPlans)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: _PlanCard(
                plan: p,
                selected: p.id == _selectedId,
                onTap: () => setState(() => _selectedId = p.id),
              ),
            ),

          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              const Icon(Icons.verified_user_rounded,
                  size: 16, color: AppColors.textSecondary),
              const SizedBox(width: 6),
              Text('Price includes 18% GST.',
                  style: text.bodySmall
                      ?.copyWith(fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),

          const SectionHeader(title: "What's included"),
          const SizedBox(height: AppSpacing.md),
          GlassCard(
            child: Column(
              children: [
                for (final b in _benefits) _BenefitRow(text: b),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          if (wallet > 0) ...[
            Row(
              children: [
                const Icon(Icons.account_balance_wallet_rounded,
                    size: 16, color: AppColors.primary),
                const SizedBox(width: 6),
                Text(
                  'Fit90 Wallet: ${formatInr(wallet)} — usable at checkout',
                  style: text.bodySmall?.copyWith(
                      color: AppColors.primary, fontWeight: FontWeight.w700),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
          FilledButton(
            onPressed: () => _choosePayment(plan),
            child: Text(
                'Get ${plan.title ?? plan.durationLabel} · ${formatInr(plan.priceInr)}'),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Card / Google Play billing is handled securely by the Dayjoy '
            'backend. Wallet balance can pay in full when it covers the price. '
            'Manage or cancel anytime.',
            style: text.bodySmall?.copyWith(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Offer wallet payment (when the balance covers it) or standard billing.
  void _choosePayment(SubscriptionPlan plan) {
    final double wallet = ref.read(walletSummaryProvider).available;
    final double price = plan.priceInr.toDouble();
    final bool canUseWallet = wallet >= price;

    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: AppColors.surfaceOf(context),
      builder: (sheetContext) {
        final t = Theme.of(sheetContext).textTheme;
        return Padding(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Pay for ${plan.title ?? plan.durationLabel}',
                  style: t.titleLarge),
              Text('${formatInr(plan.priceInr)} · incl. 18% GST',
                  style: t.bodySmall),
              const SizedBox(height: AppSpacing.lg),

              // Wallet option
              _PayOption(
                icon: Icons.account_balance_wallet_rounded,
                title: 'Pay from Fit90 Wallet',
                subtitle: canUseWallet
                    ? 'Balance ${formatInr(wallet)} — pays in full'
                    : 'Balance ${formatInr(wallet)} — not enough for this plan',
                enabled: canUseWallet,
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  ref
                      .read(walletProvider.notifier)
                      .spend(price, '${plan.title ?? plan.durationLabel} subscription');
                  _activate(plan, paidFromWallet: true);
                },
              ),
              const SizedBox(height: AppSpacing.sm),

              // Standard billing
              _PayOption(
                icon: Icons.credit_card_rounded,
                title: 'Pay via Google Play / card',
                subtitle: 'Secure checkout',
                enabled: true,
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  _activate(plan, paidFromWallet: false);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _activate(SubscriptionPlan plan, {required bool paidFromWallet}) {
    // NOTE: card/Play payment must go through Play Billing / the backend. Wallet
    // payment is real (referral balance is debited). This activates the plan.
    ref.read(subscriptionProvider.notifier).activate(plan);
    showAppSnack(
      context,
      paidFromWallet
          ? '${plan.title ?? plan.durationLabel} activated — paid from wallet.'
          : '${plan.title ?? plan.durationLabel} activated. Premium unlocked!',
      type: AppSnackType.success,
    );
  }
}

class _ActiveBanner extends StatelessWidget {
  const _ActiveBanner({required this.sub});
  final ActiveSubscription sub;

  @override
  Widget build(BuildContext context) {
    final plan = sub.plan;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: GlassCard(
        gradient: AppColors.brandGradient,
        child: Row(
          children: [
            const Icon(Icons.workspace_premium_rounded,
                color: Colors.white, size: 30),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Premium active',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 16)),
                  Text(
                    '${plan?.durationLabel ?? ''} · ${sub.daysLeft} days left',
                    style: TextStyle(color: Colors.white.withOpacity(0.92)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Auto-renew toggle + payment-method chooser (shown when a plan is active).
class _AutoRenewCard extends ConsumerWidget {
  const _AutoRenewCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sub = ref.watch(subscriptionProvider);
    if (sub == null || !sub.isActive) return const SizedBox.shrink();
    final TextTheme text = Theme.of(context).textTheme;
    final plan = sub.plan;
    final notifier = ref.read(subscriptionProvider.notifier);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: GlassCard(
        child: Column(
          children: [
            Row(
              children: [
                const Icon(Icons.autorenew_rounded, color: AppColors.primary),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Auto-renew', style: text.titleMedium),
                      Text(
                        sub.autoRenew
                            ? 'On — renews automatically at expiry'
                            : 'Off — renew manually',
                        style: text.bodySmall
                            ?.copyWith(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: sub.autoRenew,
                  onChanged: (v) => notifier.setAutoRenew(v),
                ),
              ],
            ),
            if (sub.autoRenew) ...[
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: _MethodChip(
                      icon: Icons.credit_card_rounded,
                      label: 'Card / Play',
                      selected: sub.renewMethod == RenewMethod.card,
                      onTap: () => notifier.setRenewMethod(RenewMethod.card),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: _MethodChip(
                      icon: Icons.account_balance_wallet_rounded,
                      label: 'Wallet',
                      selected: sub.renewMethod == RenewMethod.wallet,
                      onTap: () => notifier.setRenewMethod(RenewMethod.wallet),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Your ${plan?.title ?? 'plan'} (${formatInr(plan?.priceInr ?? 0)}) '
                'will renew in ${sub.daysLeft} day${sub.daysLeft == 1 ? '' : 's'} '
                'via ${sub.renewMethod == RenewMethod.wallet ? 'Fit90 Wallet' : 'card / Google Play'}. '
                'Billing is executed securely by the Dayjoy backend.',
                style:
                    text.bodySmall?.copyWith(color: AppColors.textSecondary),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _MethodChip extends StatelessWidget {
  const _MethodChip({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
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
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withOpacity(0.12)
              : (isDark ? AppColors.surfaceMutedDark : AppColors.surfaceMuted),
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: selected ? AppColors.primary : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon,
                size: 18,
                color: selected ? AppColors.primary : AppColors.textSecondary),
            const SizedBox(width: 6),
            Text(label,
                style: TextStyle(
                    color: selected ? AppColors.primary : null,
                    fontWeight: FontWeight.w700,
                    fontSize: 13)),
          ],
        ),
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.plan,
    required this.selected,
    required this.onTap,
  });

  final SubscriptionPlan plan;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color border = selected ? AppColors.primary : Colors.transparent;
    final Color base = isDark ? AppColors.surfaceDark : AppColors.surface;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: base,
          borderRadius: AppRadius.card,
          border: Border.all(color: border, width: 2),
          boxShadow: [
            BoxShadow(
                color: AppColors.shadow,
                blurRadius: 18,
                offset: const Offset(0, 8)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  selected
                      ? Icons.radio_button_checked_rounded
                      : Icons.radio_button_unchecked_rounded,
                  color: selected ? AppColors.primary : AppColors.textSecondary,
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(plan.title ?? plan.durationLabel,
                    style: text.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w800)),
                const Spacer(),
                if (plan.tag != PlanTag.none) _TagChip(tag: plan.tag),
              ],
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.only(left: 32),
              child: Text(plan.durationLabel,
                  style: text.bodySmall
                      ?.copyWith(fontWeight: FontWeight.w600)),
            ),
            const SizedBox(height: AppSpacing.md),
            Padding(
              padding: const EdgeInsets.only(left: 32),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(formatInr(plan.priceInr),
                      style: text.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w900)),
                  const SizedBox(width: 8),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 3),
                    child: Text(
                      '≈ ${formatInr(plan.roundedMonthly)}/mo',
                      style: text.bodySmall
                          ?.copyWith(color: AppColors.textSecondary),
                    ),
                  ),
                  const Spacer(),
                  if (plan.discountPct > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.success.withOpacity(0.14),
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                      child: Text(
                        'Save ${plan.discountPct % 1 == 0 ? plan.discountPct.toStringAsFixed(0) : plan.discountPct.toStringAsFixed(1)}%',
                        style: const TextStyle(
                            color: AppColors.success,
                            fontSize: 12,
                            fontWeight: FontWeight.w800),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  const _TagChip({required this.tag});
  final PlanTag tag;

  @override
  Widget build(BuildContext context) {
    final bool best = tag == PlanTag.bestValue;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        gradient: best ? AppColors.goldGradient : AppColors.brandGradient,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        best ? 'BEST VALUE' : 'MOST POPULAR',
        style: const TextStyle(
            color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900),
      ),
    );
  }
}

class _PayOption extends StatelessWidget {
  const _PayOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.enabled,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return Opacity(
      opacity: enabled ? 1 : 0.5,
      child: GlassCard(
        onTap: enabled ? onTap : null,
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: AppColors.primary.withOpacity(0.12),
              child: Icon(icon, color: AppColors.primary),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: text.titleSmall
                          ?.copyWith(fontWeight: FontWeight.w700)),
                  Text(subtitle, style: text.bodySmall),
                ],
              ),
            ),
            if (enabled)
              const Icon(Icons.chevron_right_rounded,
                  color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}

class _BenefitRow extends StatelessWidget {
  const _BenefitRow({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle_rounded,
              size: 18, color: AppColors.primary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
