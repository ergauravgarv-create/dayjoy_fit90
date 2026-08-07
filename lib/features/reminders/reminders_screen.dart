import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../services/notifications/reminder.dart';
import '../../shared/widgets/glass_card.dart';
import '../../state/reminders_provider.dart';

class RemindersScreen extends ConsumerWidget {
  const RemindersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reminders = ref.watch(remindersProvider);
    final TextTheme text = Theme.of(context).textTheme;
    final int activeCount = reminders.where((r) => r.enabled).length;

    return Scaffold(
      appBar: AppBar(title: const Text('Reminders')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, 40),
        children: [
          GlassCard(
            gradient: AppColors.brandGradient,
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Row(
              children: [
                const Icon(Icons.notifications_active_rounded,
                    color: Colors.white, size: 32),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Stay on track',
                          style: text.titleMedium
                              ?.copyWith(color: Colors.white)),
                      const SizedBox(height: 2),
                      Text(
                          '$activeCount reminder${activeCount == 1 ? '' : 's'} on · '
                          'gentle nudges for your daily habits',
                          style:
                              const TextStyle(color: Colors.white70)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (kIsWeb) ...[
            const SizedBox(height: AppSpacing.md),
            GlassCard(
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded,
                      color: AppColors.info),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                        'Reminders are delivered on the mobile app. Your times '
                        'are saved here and will work once installed on a phone.',
                        style: text.bodySmall),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          for (final cat in ReminderCategory.values) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Row(
                children: [
                  Text(cat.label, style: text.titleMedium),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    '${reminders.where((r) => r.kind.category == cat && r.enabled).length} on',
                    style: text.bodySmall
                        ?.copyWith(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            for (final r
                in reminders.where((r) => r.kind.category == cat))
              _ReminderTile(reminder: r),
            const SizedBox(height: AppSpacing.md),
          ],
        ],
      ),
    );
  }
}

class _ReminderTile extends ConsumerWidget {
  const _ReminderTile({required this.reminder});
  final Reminder reminder;

  Future<void> _pickTime(BuildContext context, WidgetRef ref) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: reminder.time,
    );
    if (picked != null) {
      await ref.read(remindersProvider.notifier).setTime(reminder.kind, picked);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final TextTheme text = Theme.of(context).textTheme;
    final bool on = reminder.enabled;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: GlassCard(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: (on ? AppColors.primary : AppColors.textSecondary)
                    .withOpacity(0.12),
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Icon(reminder.kind.icon,
                  color: on ? AppColors.primary : AppColors.textSecondary),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(reminder.kind.label, style: text.titleMedium),
                  const SizedBox(height: 2),
                  InkWell(
                    onTap: () => _pickTime(context, ref),
                    child: Row(
                      children: [
                        Icon(Icons.schedule_rounded,
                            size: 14,
                            color: on
                                ? AppColors.primary
                                : AppColors.textSecondary),
                        const SizedBox(width: 4),
                        Text(reminder.time.format(context),
                            style: text.bodyMedium?.copyWith(
                                color: on
                                    ? AppColors.primary
                                    : AppColors.textSecondary,
                                fontWeight: FontWeight.w700)),
                        const SizedBox(width: 4),
                        Text('· tap to change', style: text.bodySmall),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Switch(
              value: on,
              onChanged: (v) =>
                  ref.read(remindersProvider.notifier).setEnabled(
                        reminder.kind,
                        v,
                      ),
            ),
          ],
        ),
      ),
    );
  }
}
