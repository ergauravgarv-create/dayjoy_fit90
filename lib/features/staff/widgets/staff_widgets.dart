import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../data/models/appointment.dart';
import '../../../data/models/participant.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../state/providers.dart';

/// Sign-out button shared by all staff dashboards.
class StaffSignOutAction extends ConsumerWidget {
  const StaffSignOutAction({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return IconButton(
      tooltip: 'Sign out',
      icon: const Icon(Icons.logout_rounded),
      onPressed: () async {
        await ref.read(authControllerProvider.notifier).signOut();
        if (context.mounted) context.go(Routes.login);
      },
    );
  }
}

/// Gradient greeting header for a staff dashboard.
class StaffHeaderCard extends StatelessWidget {
  const StaffHeaderCard({
    super.key,
    required this.name,
    required this.role,
    required this.icon,
  });

  final String name;
  final String role;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      gradient: AppColors.brandGradient,
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: Colors.white,
            child: Icon(icon, color: AppColors.primary, size: 30),
          ),
          const SizedBox(width: AppSpacing.lg),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(role,
                  style: const TextStyle(color: Colors.white70, fontSize: 13)),
              Text(name,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w800)),
            ],
          ),
        ],
      ),
    );
  }
}

/// A single appointment with contextual actions.
class AppointmentCard extends StatelessWidget {
  const AppointmentCard({
    super.key,
    required this.appointment,
    this.onConfirm,
    this.onDecline,
    this.onComplete,
  });

  final Appointment appointment;
  final VoidCallback? onConfirm;
  final VoidCallback? onDecline;
  final VoidCallback? onComplete;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final l = AppLocalizations.of(context);
    final bool requested = appointment.status == AppointmentStatus.requested;
    final bool confirmed = appointment.status == AppointmentStatus.confirmed;

    return GlassCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.primary.withOpacity(0.15),
                child: Text(appointment.participantName.characters.first,
                    style: const TextStyle(
                        color: AppColors.primary, fontWeight: FontWeight.w700)),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(appointment.participantName, style: text.titleMedium),
                    Text(
                      '${appointment.type}'
                      '${appointment.participantCity != null ? ' · ${appointment.participantCity}' : ''}',
                      style: text.bodySmall,
                    ),
                  ],
                ),
              ),
              _StatusPill(status: appointment.status),
            ],
          ),
          if (appointment.scheduledAt != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                const Icon(Icons.schedule_rounded,
                    size: 14, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Text(
                  DateFormat('EEE d MMM, h:mm a').format(appointment.scheduledAt!),
                  style: text.bodySmall,
                ),
              ],
            ),
          ],
          if (requested || confirmed) ...[
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                if (requested) ...[
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onDecline,
                      child: Text(l.actionDecline),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: FilledButton(
                      onPressed: onConfirm,
                      child: Text(l.actionConfirm),
                    ),
                  ),
                ] else if (confirmed) ...[
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onComplete,
                      icon: const Icon(Icons.check_rounded, size: 18),
                      label: Text(l.actionMarkComplete),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});
  final AppointmentStatus status;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final Color color = switch (status) {
      AppointmentStatus.requested => AppColors.warning,
      AppointmentStatus.confirmed => AppColors.info,
      AppointmentStatus.completed => AppColors.success,
      AppointmentStatus.cancelled => AppColors.error,
      AppointmentStatus.rescheduled => AppColors.taskYoga,
    };
    final String label = switch (status) {
      AppointmentStatus.requested => l.statusRequested,
      AppointmentStatus.confirmed => l.statusConfirmed,
      AppointmentStatus.completed => l.statusCompleted,
      AppointmentStatus.cancelled => l.statusCancelled,
      AppointmentStatus.rescheduled => l.statusRescheduled,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.14),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(label,
          style: TextStyle(
              color: color, fontSize: 11, fontWeight: FontWeight.w700)),
    );
  }
}

/// A participant row for staff/admin rosters.
class RosterTile extends StatelessWidget {
  const RosterTile({super.key, required this.participant, this.onTap});

  final Participant participant;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final l = AppLocalizations.of(context);
    return GlassCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: AppColors.primary.withOpacity(0.15),
            child: Text(participant.name.characters.first,
                style: const TextStyle(
                    color: AppColors.primary, fontWeight: FontWeight.w700)),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(participant.name, style: text.titleMedium),
                Text('${l.dayShort(participant.currentDay)} · ${participant.city}',
                    style: text.bodySmall),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  child: LinearProgressIndicator(
                    value: participant.goalProgress,
                    minHeight: 6,
                    backgroundColor: AppColors.primary.withOpacity(0.10),
                    valueColor:
                        const AlwaysStoppedAnimation(AppColors.primary),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                children: [
                  const Icon(Icons.local_fire_department_rounded,
                      size: 14, color: AppColors.accent),
                  Text(' ${participant.streak}',
                      style: text.titleSmall
                          ?.copyWith(color: AppColors.accent)),
                ],
              ),
              Text('-${participant.weightLostKg.toStringAsFixed(1)} kg',
                  style: text.bodySmall?.copyWith(color: AppColors.success)),
            ],
          ),
        ],
      ),
    );
  }
}
