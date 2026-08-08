import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../state/subscription_provider.dart';
import 'subscription_screen.dart';

/// A few headline unlocks shown on the paywall.
const List<String> _paywallHighlights = [
  'Unlimited doctor & trainer consultations',
  'Personalized diet charts & food tracking',
  'Workouts, yoga, Zumba & skin analysis',
  'Progress tracking & doctor-reviewed guidance',
];

/// Returns true if the user has premium; otherwise shows the paywall for
/// [featureName] and returns false. Use to guard premium entry points:
/// `if (ensurePremium(context, ref, 'Meal tracker')) { ...navigate... }`.
bool ensurePremium(BuildContext context, WidgetRef ref, String featureName) {
  if (ref.read(isPremiumProvider)) return true;
  showPaywall(context, featureName);
  return false;
}

/// A "preview locked feature" sheet with a Buy Health plan call-to-action.
Future<void> showPaywall(BuildContext context, String featureName) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: AppColors.surfaceOf(context),
    builder: (sheetContext) {
      final text = Theme.of(sheetContext).textTheme;
      return Padding(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.xl, 0, AppSpacing.xl, AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 68,
                height: 68,
                decoration: const BoxDecoration(
                    gradient: AppColors.brandGradient, shape: BoxShape.circle),
                child: const Icon(Icons.lock_rounded,
                    color: Colors.white, size: 32),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text('$featureName is a Premium feature',
                style: text.titleLarge, textAlign: TextAlign.left),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Unlock it with a Dayjoy Fit90 Health plan — one subscription '
              'covers everything:',
              style: text.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.md),
            for (final h in _paywallHighlights)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.check_circle_rounded,
                        size: 18, color: AppColors.primary),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(child: Text(h)),
                  ],
                ),
              ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                const Icon(Icons.verified_user_rounded,
                    size: 15, color: AppColors.textSecondary),
                const SizedBox(width: 6),
                Text('Price includes 18% GST.',
                    style: text.bodySmall
                        ?.copyWith(fontWeight: FontWeight.w700)),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () {
                  Navigator.of(sheetContext).pop();
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                        builder: (_) => const SubscriptionScreen()),
                  );
                },
                icon: const Icon(Icons.workspace_premium_rounded, size: 18),
                label: const Text('Buy Health plan'),
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Center(
              child: TextButton(
                onPressed: () => Navigator.of(sheetContext).pop(),
                child: const Text('Maybe later'),
              ),
            ),
          ],
        ),
      );
    },
  );
}

/// A small lock chip to overlay on premium cards for free users.
class PremiumLockBadge extends StatelessWidget {
  const PremiumLockBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        gradient: AppColors.goldGradient,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.lock_rounded, size: 11, color: Colors.white),
          SizedBox(width: 3),
          Text('PRO',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }
}
