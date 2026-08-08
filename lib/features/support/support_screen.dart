import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../shared/widgets/glass_card.dart';
import 'schedule_call_screen.dart';
import 'support_chat_screen.dart';

/// Dayjoy Care contact details — update here if they change.
const String kCareHours = '10 AM – 6 PM · Mon to Sat';
const String kCarePhone = '+91 7733990555';
const String kCarePhoneDial = 'tel:+917733990555';
const String kCareEmail = 'support@dayjoy.in';

/// Customer-care hub: live chat, schedule a callback, helpline and email.
class SupportScreen extends StatelessWidget {
  const SupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;

    void push(Widget screen) => Navigator.of(context)
        .push(MaterialPageRoute<void>(builder: (_) => screen));

    Future<void> launch(String uri, String fallback) async {
      final ok = await launchUrl(Uri.parse(uri),
          mode: LaunchMode.externalApplication);
      if (!ok && context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(fallback)));
      }
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Help & Support')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.xxl),
        children: [
          const SizedBox(height: AppSpacing.md),
          GlassCard(
            gradient: AppColors.brandGradient,
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Row(
              children: [
                const Icon(Icons.support_agent_rounded,
                    color: Colors.white, size: 40),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Dayjoy Care',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w800)),
                      Text('We\'re here to help — $kCareHours.',
                          style: TextStyle(
                              color: Colors.white.withOpacity(0.9))),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          _SupportTile(
            icon: Icons.chat_bubble_rounded,
            color: AppColors.primary,
            title: 'Chat with us',
            subtitle: 'Message Dayjoy Care — usually replies in minutes',
            onTap: () => push(const SupportChatScreen()),
          ),
          const SizedBox(height: AppSpacing.md),
          _SupportTile(
            icon: Icons.phone_in_talk_rounded,
            color: AppColors.info,
            title: 'Schedule a call',
            subtitle: 'Pick a date & time and we\'ll call you back',
            onTap: () => push(const ScheduleCallScreen()),
          ),
          const SizedBox(height: AppSpacing.md),
          _SupportTile(
            icon: Icons.call_rounded,
            color: AppColors.success,
            title: 'Call the helpline',
            subtitle: '$kCarePhone · $kCareHours',
            onTap: () => launch(kCarePhoneDial, 'Helpline: $kCarePhone'),
          ),
          const SizedBox(height: AppSpacing.md),
          _SupportTile(
            icon: Icons.mail_rounded,
            color: AppColors.accent,
            title: 'Email us',
            subtitle: kCareEmail,
            onTap: () => launch('mailto:$kCareEmail', 'Email: $kCareEmail'),
          ),

          const SizedBox(height: AppSpacing.xl),
          Text(
            'Dayjoy Care is available $kCareHours. For medical emergencies, '
            'please contact your local emergency services — this app is not for '
            'urgent medical help.',
            style: text.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _SupportTile extends StatelessWidget {
  const _SupportTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

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
                Text(title, style: text.titleMedium),
                Text(subtitle, style: text.bodySmall),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded),
        ],
      ),
    );
  }
}
