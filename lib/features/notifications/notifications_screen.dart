import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../data/models/app_notification.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../shared/widgets/glass_card.dart';
import '../../state/engagement_providers.dart';
import '../../state/providers.dart';
import '../../state/repository_providers.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  IconData _icon(String type) => switch (type) {
        'dayComplete' => Icons.emoji_events_rounded,
        'badge' => Icons.workspace_premium_rounded,
        'reminder' => Icons.notifications_active_rounded,
        'weeklyReport' => Icons.insights_rounded,
        'weeklyCheckin' => Icons.event_note_rounded,
        'motivation' => Icons.auto_awesome_rounded,
        'broadcast' => Icons.campaign_rounded,
        'appointmentUpdate' ||
        'appointmentReminder' ||
        'appointmentRequested' =>
          Icons.medical_services_rounded,
        _ => Icons.notifications_rounded,
      };

  Color _color(String type) => switch (type) {
        'dayComplete' || 'badge' => AppColors.accent,
        'reminder' || 'weeklyCheckin' => AppColors.primary,
        'weeklyReport' || 'broadcast' => AppColors.info,
        _ => AppColors.taskYoga,
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(notificationsProvider);
    final uid = ref.watch(authUidProvider) ?? 'demo-user';
    final l = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l.notificationsTitle),
        actions: [
          TextButton(
            onPressed: () =>
                ref.read(notificationRepositoryProvider).markAllRead(uid),
            child: Text(l.markAllRead),
          ),
        ],
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (items) {
          if (items.isEmpty) {
            return Center(child: Text(l.allCaughtUp));
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.xxl),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
            itemBuilder: (context, i) {
              final AppNotification n = items[i];
              return GlassCard(
                onTap: () => ref
                    .read(notificationRepositoryProvider)
                    .markRead(uid, n.id),
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
                          Text(_ago(l, n.createdAt),
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(color: AppColors.textSecondary)),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
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
