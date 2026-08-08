import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../data/models/appointment.dart';
import '../../shared/widgets/app_snack.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/glass_card.dart';
import '../../shared/widgets/skeleton.dart';
import '../../state/appointments_provider.dart';
import '../../state/repository_providers.dart';
import '../subscription/paywall.dart';
import 'book_appointment_screen.dart';
import 'book_consult_chooser_screen.dart';
import 'consult_actions.dart';
import 'followup_scheduler.dart';
import 'reschedule_sheet.dart';

/// The participant's booked consultations (doctor + trainer) with a "Join call"
/// button that opens the in-app video/voice room at call time.
class MyAppointmentsScreen extends ConsumerStatefulWidget {
  const MyAppointmentsScreen({super.key});

  @override
  ConsumerState<MyAppointmentsScreen> createState() =>
      _MyAppointmentsScreenState();
}

class _MyAppointmentsScreenState extends ConsumerState<MyAppointmentsScreen> {
  @override
  void initState() {
    super.initState();
    // Sync device reminders once on open (the stream is usually already cached,
    // so ref.listen below wouldn't otherwise fire on first build).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final list = ref.read(myAppointmentsProvider).valueOrNull;
      if (list != null) syncFollowUpReminders(ref, list);
    });
  }

  @override
  Widget build(BuildContext context) {
    final apptsAsync = ref.watch(myAppointmentsProvider);
    final appts = apptsAsync.valueOrNull ?? const <Appointment>[];

    // Also re-sync whenever the bookings change while the screen is open.
    ref.listen<AsyncValue<List<Appointment>>>(myAppointmentsProvider,
        (prev, next) {
      final list = next.valueOrNull;
      if (list != null) syncFollowUpReminders(ref, list);
    });

    if (apptsAsync.isLoading && appts.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('My consultations')),
        body: const Padding(
          padding: EdgeInsets.all(AppSpacing.lg),
          child: SkeletonList(count: 4, itemHeight: 132),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('My consultations')),
      body: appts.isEmpty
          ? EmptyState(
              icon: Icons.event_available_rounded,
              title: 'No consultations yet',
              message:
                  'Book a video or voice call with your doctor or trainer — '
                  'the call opens right here inside the app.',
              actionLabel: 'Book a consultation',
              onAction: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                    builder: (_) => const BookConsultChooserScreen()),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.xxl),
              itemCount: appts.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(height: AppSpacing.md),
              itemBuilder: (_, i) => _ApptCard(appt: appts[i]),
            ),
    );
  }
}

class _ApptCard extends ConsumerWidget {
  const _ApptCard({required this.appt});
  final Appointment appt;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final TextTheme text = Theme.of(context).textTheme;
    final bool isDoctor = appt.providerRole == ProviderKind.doctor;
    final String providerName =
        isDoctor ? AppConstants.doctorName : AppConstants.coachName;
    final String providerRole = isDoctor ? 'Doctor' : 'Trainer';
    final Color accent = isDoctor ? AppColors.info : AppColors.taskFitness;
    final bool joinable = canJoinNow(appt);

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: accent.withOpacity(0.15),
                child: Icon(
                  isDoctor
                      ? Icons.medical_services_rounded
                      : Icons.fitness_center_rounded,
                  color: accent,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('$providerName · $providerRole',
                        style: text.titleMedium),
                    Text(appt.type, style: text.bodySmall),
                  ],
                ),
              ),
              _StatusPill(status: appt.status),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              _Chip(
                icon: appt.mode == ConsultMode.videoCall
                    ? Icons.videocam_rounded
                    : Icons.call_rounded,
                label: appt.mode.label,
              ),
              const SizedBox(width: AppSpacing.sm),
              if (appt.scheduledAt != null)
                _Chip(
                  icon: Icons.schedule_rounded,
                  label: DateFormat('EEE d MMM, h:mm a')
                      .format(appt.scheduledAt!),
                ),
            ],
          ),
          if (appt.providerNote != null && appt.providerNote!.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            _NoteBlock(
              note: appt.providerNote!,
              fromDoctor: isDoctor,
              followUpAt: appt.followUpAt,
            ),
          ],
          if (appt.followUpAt != null) ...[
            const SizedBox(height: AppSpacing.sm),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  final name = appt.providerRole == ProviderKind.doctor
                      ? 'Doctor consultation'
                      : 'Trainer consultation';
                  if (!ensurePremium(context, ref, name)) return;
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => BookAppointmentScreen(
                          providerRole: appt.providerRole),
                    ),
                  );
                },
                icon: const Icon(Icons.event_repeat_rounded, size: 18),
                label: const Text('Book follow-up'),
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          _actionRow(context, joinable),
          _secondaryActions(context, ref),
        ],
      ),
    );
  }

  /// Reschedule / cancel — available while the booking is still upcoming.
  Widget _secondaryActions(BuildContext context, WidgetRef ref) {
    final bool canModify = appt.status == AppointmentStatus.requested ||
        appt.status == AppointmentStatus.confirmed ||
        appt.status == AppointmentStatus.rescheduled;
    if (!canModify) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => showRescheduleSheet(context, ref, appt),
              icon: const Icon(Icons.event_repeat_rounded, size: 18),
              label: const Text('Reschedule'),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => _confirmCancel(context, ref),
              icon: const Icon(Icons.close_rounded, size: 18),
              label: const Text('Cancel'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.error,
                side: BorderSide(color: AppColors.error.withOpacity(0.4)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmCancel(BuildContext context, WidgetRef ref) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.surfaceOf(dialogContext),
        title: const Text('Cancel consultation?'),
        content: const Text(
            'This will cancel your booking. You can always book again later.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Keep booking'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Cancel it'),
          ),
        ],
      ),
    );
    if (yes == true) {
      await ref
          .read(staffRepositoryProvider)
          .updateAppointmentStatus(appt.id, AppointmentStatus.cancelled);
      if (context.mounted) {
        showAppSnack(context, 'Consultation cancelled.',
            type: AppSnackType.info);
      }
    }
  }

  Widget _actionRow(BuildContext context, bool joinable) {
    switch (appt.status) {
      case AppointmentStatus.requested:
      case AppointmentStatus.rescheduled:
        return _hint(context, Icons.hourglass_top_rounded,
            'Waiting for confirmation. You\'ll be able to join here once it\'s confirmed.');
      case AppointmentStatus.confirmed:
        if (joinable) {
          return SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => joinConsultation(context, appt),
              icon: Icon(appt.mode == ConsultMode.videoCall
                  ? Icons.videocam_rounded
                  : Icons.call_rounded),
              label: Text('Join ${appt.mode.label.toLowerCase()}'),
            ),
          );
        }
        return _hint(context, Icons.check_circle_rounded, 'Confirmed.');
      case AppointmentStatus.completed:
        return _hint(context, Icons.verified_rounded, 'Consultation completed.');
      case AppointmentStatus.cancelled:
        return _hint(context, Icons.cancel_rounded, 'This booking was cancelled.');
      case AppointmentStatus.noShow:
        return _hint(context, Icons.event_busy_rounded,
            'Marked as no-show (missed appointment).');
    }
  }

  Widget _hint(BuildContext context, IconData icon, String msg) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.textSecondary),
        const SizedBox(width: 6),
        Expanded(
          child: Text(msg,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: AppColors.textSecondary)),
        ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceMutedDark : AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: AppColors.primary),
          const SizedBox(width: 5),
          Text(label,
              style: const TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _NoteBlock extends StatelessWidget {
  const _NoteBlock({
    required this.note,
    required this.fromDoctor,
    this.followUpAt,
  });
  final String note;
  final bool fromDoctor;
  final DateTime? followUpAt;

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.info.withOpacity(isDark ? 0.16 : 0.08),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.info.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.sticky_note_2_rounded,
                  size: 16, color: AppColors.info),
              const SizedBox(width: 6),
              Text(
                fromDoctor ? 'Note from your doctor' : 'Note from your trainer',
                style: const TextStyle(
                    color: AppColors.info,
                    fontWeight: FontWeight.w700,
                    fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(note, style: Theme.of(context).textTheme.bodyMedium),
          if (followUpAt != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                const Icon(Icons.event_available_rounded,
                    size: 15, color: AppColors.info),
                const SizedBox(width: 6),
                Text(
                  'Follow-up on ${DateFormat('EEE, d MMM yyyy').format(followUpAt!)}',
                  style: const TextStyle(
                      color: AppColors.info, fontWeight: FontWeight.w700),
                ),
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
    final Color c = switch (status) {
      AppointmentStatus.confirmed => AppColors.success,
      AppointmentStatus.requested => AppColors.orange,
      AppointmentStatus.rescheduled => AppColors.info,
      AppointmentStatus.completed => AppColors.primary,
      AppointmentStatus.cancelled => AppColors.error,
      AppointmentStatus.noShow => AppColors.error,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: c.withOpacity(0.14),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(status.label,
          style: TextStyle(
              color: c, fontSize: 11, fontWeight: FontWeight.w700)),
    );
  }
}
