import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../data/models/app_notification.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/glass_card.dart';
import '../../state/activity_provider.dart';
import '../../state/engagement_providers.dart';
import '../../state/providers.dart';
import '../../state/repository_providers.dart';
import '../appointments/my_appointments_screen.dart';
import '../badges/badges_gallery_screen.dart';
import '../subscription/subscription_screen.dart';
import '../community/community_screen.dart';
import '../reminders/reminders_screen.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  IconData _icon(String type) => switch (type) {
        'dayComplete' => Icons.emoji_events_rounded,
        'badge' => Icons.workspace_premium_rounded,
        'challenge' => Icons.flag_rounded,
        'reminder' => Icons.notifications_active_rounded,
        'weeklyReport' => Icons.insights_rounded,
        'weeklyCheckin' => Icons.event_note_rounded,
        'motivation' => Icons.auto_awesome_rounded,
        'broadcast' => Icons.campaign_rounded,
        'appointment' => Icons.video_call_rounded,
        'consultNote' => Icons.sticky_note_2_rounded,
        'followUp' => Icons.event_repeat_rounded,
        'subscription' => Icons.workspace_premium_rounded,
        'appointmentUpdate' ||
        'appointmentReminder' ||
        'appointmentRequested' =>
          Icons.medical_services_rounded,
        _ => Icons.notifications_rounded,
      };

  Color _color(String type) => switch (type) {
        'dayComplete' || 'badge' || 'challenge' => AppColors.accent,
        'reminder' || 'weeklyCheckin' => AppColors.primary,
        'weeklyReport' || 'broadcast' => AppColors.info,
        'appointment' => AppColors.success,
        'consultNote' => AppColors.info,
        'followUp' => AppColors.orange,
        'subscription' => AppColors.orange,
        _ => AppColors.taskYoga,
      };

  /// Screen to deep-link to when a notification is tapped, or null.
  Widget? _destinationFor(String type) => switch (type) {
        'badge' => const BadgesGalleryScreen(),
        'challenge' => const CommunityScreen(),
        'reminder' => const RemindersScreen(),
        'appointment' || 'consultNote' || 'followUp' =>
          const MyAppointmentsScreen(),
        'subscription' => const SubscriptionScreen(),
        _ => null,
      };

  bool _isLocal(String id) =>
      id.startsWith('badge_') ||
      id.startsWith('challenge_') ||
      id.startsWith('appt_') ||
      id.startsWith('sub_');

  void _onTap(
      BuildContext context, WidgetRef ref, String uid, AppNotification n) {
    if (_isLocal(n.id)) {
      ref.read(activityReadProvider.notifier).markRead(n.id);
    } else {
      ref.read(notificationRepositoryProvider).markRead(uid, n.id);
    }
    final dest = _destinationFor(n.type);
    if (dest != null) {
      Navigator.of(context)
          .push(MaterialPageRoute<void>(builder: (_) => dest));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uid = ref.watch(authUidProvider) ?? 'demo-user';
    final l = AppLocalizations.of(context);

    final List<AppNotification> server =
        ref.watch(notificationsProvider).valueOrNull ?? const [];
    final List<AppNotification> local = ref.watch(localActivityProvider);
    final List<AppNotification> items = [...server, ...local]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return Scaffold(
      appBar: AppBar(
        title: Text(l.notificationsTitle),
        actions: [
          TextButton(
            onPressed: () {
              ref.read(notificationRepositoryProvider).markAllRead(uid);
              ref
                  .read(activityReadProvider.notifier)
                  .markAll(local.map((n) => n.id));
            },
            child: Text(l.markAllRead),
          ),
        ],
      ),
      body: items.isEmpty
          ? EmptyState(
              icon: Icons.notifications_none_rounded,
              title: l.allCaughtUp,
              message: 'New updates, reminders and wins will show up here.',
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.xxl),
              itemCount: items.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(height: AppSpacing.sm),
              itemBuilder: (context, i) {
                final AppNotification n = items[i];
                final bool linkable = _destinationFor(n.type) != null;
                return GlassCard(
                  onTap: () => _onTap(context, ref, uid, n),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        backgroundColor: _color(n.type).withOpacity(0.15),
                        child: Icon(_icon(n.type), color: _color(n.type)),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(n.title,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleSmall
                                          ?.copyWith(
                                              fontWeight: n.read
                                                  ? FontWeight.w600
                                                  : FontWeight.w800)),
                                ),
                                if (!n.read)
                                  Container(
                                    width: 9,
                                    height: 9,
                                    decoration: const BoxDecoration(
                                        color: AppColors.primary,
                                        shape: BoxShape.circle),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(n.body,
                                style: Theme.of(context).textTheme.bodySmall),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Text(_ago(l, n.createdAt),
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                            color: AppColors.textSecondary)),
                                if (linkable) ...[
                                  const Spacer(),
                                  Text('View',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                              color: AppColors.primary,
                                              fontWeight: FontWeight.w700)),
                                  const Icon(Icons.chevron_right_rounded,
                                      size: 16, color: AppColors.primary),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }

  String _ago(AppLocalizations l, DateTime t) {
    final d = DateTime.now().difference(t);
    if (d.inMinutes < 60) return l.timeMinAgo(d.inMinutes);
    if (d.inHours < 24) return l.timeHourAgo(d.inHours);
    if (d.inDays < 7) return l.timeDayAgo(d.inDays);
    return DateFormat('d MMM').format(t);
  }
}
