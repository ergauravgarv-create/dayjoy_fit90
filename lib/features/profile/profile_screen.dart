import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_constants.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../shared/widgets/glass_card.dart';
import '../../shared/widgets/section_header.dart';
import '../../state/locale_provider.dart';
import '../../state/providers.dart';
import '../../data/models/appointment.dart';
import '../appointments/book_appointment_screen.dart';
import '../badges/badges_gallery_screen.dart';
import '../health/connect_health_screen.dart';
import '../legal/legal_page.dart';
import '../notifications/notifications_screen.dart';
import '../registration/registration_screen.dart';
import '../reminders/reminders_screen.dart';
import '../rewards/rewards_screen.dart';
import '../support/support_screen.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final participant = ref.watch(participantProvider)!;
    final int points = ref.watch(streakProvider);
    final TextTheme text = Theme.of(context).textTheme;
    final l = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l.navProfile)),
      body: ListView(
        padding:
            const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, 100),
        children: [
          // Identity card
          GlassCard(
            gradient: AppColors.brandGradient,
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 34,
                  backgroundColor: Colors.white,
                  child: Text(participant.name.characters.first,
                      style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 28,
                          fontWeight: FontWeight.w800)),
                ),
                const SizedBox(width: AppSpacing.lg),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(participant.name,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w800)),
                      Text(participant.mobile,
                          style: const TextStyle(color: Colors.white70)),
                      const SizedBox(height: 4),
                      Text('${participant.city} · ${participant.foodPreference}',
                          style: const TextStyle(color: Colors.white70)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Quick stats
          Row(
            children: [
              _MiniStat(
                  label: 'Day', value: '${participant.currentDay}/90'),
              _MiniStat(label: 'Streak', value: '$points'),
              _MiniStat(
                  label: 'BMI', value: participant.bmi.toStringAsFixed(1)),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),

          // Care team
          SectionHeader(title: l.profileCareTeam),
          const SizedBox(height: AppSpacing.md),
          _TeamTile(
            icon: Icons.fitness_center_rounded,
            color: AppColors.taskFitness,
            name: AppConstants.coachName,
            role: l.coachBookSession,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const BookAppointmentScreen(
                    providerRole: ProviderKind.coach),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          _TeamTile(
            icon: Icons.medical_services_rounded,
            color: AppColors.info,
            name: AppConstants.doctorName,
            role: l.doctorRequestConsult,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const BookAppointmentScreen(
                    providerRole: ProviderKind.doctor),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          // Settings
          SectionHeader(title: l.profileSettings),
          const SizedBox(height: AppSpacing.md),
          GlassCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                _NavRow(
                    icon: Icons.person_outline_rounded,
                    label: l.profileEditProfile,
                    onTap: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                              builder: (_) =>
                                  RegistrationScreen(existing: participant)),
                        )),
                _NavRow(
                    icon: Icons.favorite_border_rounded,
                    label: l.profileConnectHealth,
                    onTap: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                              builder: (_) => const ConnectHealthScreen()),
                        )),
                _NavRow(
                    icon: Icons.workspace_premium_outlined,
                    label: l.profileBadges,
                    onTap: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                              builder: (_) => const BadgesGalleryScreen()),
                        )),
                _NavRow(
                    icon: Icons.stars_rounded,
                    label: 'Reward points',
                    onTap: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                              builder: (_) => const RewardsScreen()),
                        )),
                _NavRow(
                    icon: Icons.notifications_none_rounded,
                    label: l.profileNotifications,
                    onTap: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                              builder: (_) => const NotificationsScreen()),
                        )),
                _NavRow(
                    icon: Icons.alarm_rounded,
                    label: 'Reminders',
                    onTap: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                              builder: (_) => const RemindersScreen()),
                        )),
                _NavRow(
                    icon: Icons.language_rounded,
                    label: l.profileLanguage,
                    onTap: () => _showLanguageDialog(context, ref, l)),
                _NavRow(
                    icon: Icons.lock_outline_rounded,
                    label: l.profilePrivacy,
                    onTap: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                              builder: (_) => privacyPolicyPage()),
                        )),
                _NavRow(
                    icon: Icons.description_outlined,
                    label: l.profileTerms,
                    onTap: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                              builder: (_) => termsOfServicePage()),
                        )),
                _NavRow(
                    icon: Icons.support_agent_rounded,
                    label: l.profileSupport,
                    last: true,
                    onTap: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                              builder: (_) => const SupportScreen()),
                        )),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          OutlinedButton.icon(
            onPressed: () async {
              await ref.read(authControllerProvider.notifier).signOut();
              if (context.mounted) context.go(Routes.login);
            },
            icon: const Icon(Icons.logout_rounded),
            label: Text(l.profileLogout),
          ),
          const SizedBox(height: AppSpacing.sm),
          TextButton(
            onPressed: () {},
            child: Text(l.profileDeleteAccount,
                style: text.bodyMedium?.copyWith(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}

void _showLanguageDialog(
    BuildContext context, WidgetRef ref, AppLocalizations l) {
  final current = ref.read(localeProvider);
  // Native name (with the English name in brackets) for each language.
  final items = <(String, Locale?)>[
    (l.languageSystem, null),
    ('English', const Locale('en')),
    ('हिंदी (Hindi)', const Locale('hi')),
    ('मराठी (Marathi)', const Locale('mr')),
    ('ગુજરાતી (Gujarati)', const Locale('gu')),
    ('বাংলা (Bengali)', const Locale('bn')),
    ('தமிழ் (Tamil)', const Locale('ta')),
    ('తెలుగు (Telugu)', const Locale('te')),
    ('ಕನ್ನಡ (Kannada)', const Locale('kn')),
    ('ଓଡ଼ିଆ (Odia)', const Locale('or')),
  ];
  showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(l.languageTitle),
      contentPadding: const EdgeInsets.only(top: AppSpacing.md),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView(
          shrinkWrap: true,
          children: [
            for (final (label, locale) in items)
              RadioListTile<String>(
                value: locale?.languageCode ?? 'system',
                groupValue: current?.languageCode ?? 'system',
                title: Text(label),
                onChanged: (_) {
                  ref.read(localeProvider.notifier).set(locale);
                  Navigator.of(ctx).pop();
                },
              ),
          ],
        ),
      ),
    ),
  );
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: GlassCard(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
          child: Column(
            children: [
              Text(value, style: text.titleLarge),
              Text(label, style: text.bodySmall),
            ],
          ),
        ),
      ),
    );
  }
}

class _TeamTile extends StatelessWidget {
  const _TeamTile(
      {required this.icon,
      required this.color,
      required this.name,
      required this.role,
      this.onTap});
  final IconData icon;
  final Color color;
  final String name;
  final String role;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return GlassCard(
      onTap: onTap,
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: color.withOpacity(0.15),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: text.titleMedium),
                Text(role, style: text.bodySmall),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded),
        ],
      ),
    );
  }
}

class _NavRow extends StatelessWidget {
  const _NavRow(
      {required this.icon, required this.label, this.last = false, this.onTap});
  final IconData icon;
  final String label;
  final bool last;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          leading: Icon(icon, color: AppColors.primary),
          title: Text(label),
          trailing: const Icon(Icons.chevron_right_rounded, size: 20),
          onTap: onTap ?? () {},
        ),
        if (!last)
          const Divider(height: 1, indent: 56, endIndent: 16),
      ],
    );
  }
}
