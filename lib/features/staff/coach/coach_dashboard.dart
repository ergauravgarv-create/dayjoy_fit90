import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../data/models/appointment.dart';
import '../../../data/models/participant.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/section_header.dart';
import '../../../shared/widgets/stat_tile.dart';
import '../../../state/repository_providers.dart';
import '../../../state/staff_providers.dart';
import '../consult_note_sheet.dart';
import '../widgets/staff_widgets.dart';

/// Anchors the "Appointment requests" section so the new-booking banner can
/// scroll straight to it. Stable across rebuilds (only one dashboard is live).
final GlobalKey _coachRequestsKey = GlobalKey();

class CoachDashboard extends ConsumerWidget {
  const CoachDashboard({super.key});

  Future<void> _setStatus(WidgetRef ref, String id, AppointmentStatus s) =>
      ref.read(staffRepositoryProvider).updateAppointmentStatus(id, s);

  void _scrollToRequests() {
    final ctx = _coachRequestsKey.currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
        alignment: 0.05,
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roster = ref.watch(rosterProvider);
    final appts = ref.watch(coachAppointmentsProvider);
    final l = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l.coachDashboard),
        actions: const [StaffSignOutAction()],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.xxl),
        children: [
          StaffHeaderCard(
            name: AppConstants.coachName,
            role: l.roleFitnessCoach,
            icon: Icons.fitness_center_rounded,
          ),
          const SizedBox(height: AppSpacing.lg),

          // New booking alert (clears once all requests are handled).
          NewBookingsBanner(
            requests: (appts.valueOrNull ?? const [])
                .where((a) => a.status == AppointmentStatus.requested)
                .toList(),
            onTap: _scrollToRequests,
          ),

          // KPIs
          Row(
            children: [
              Expanded(
                child: StatTile(
                  icon: Icons.groups_rounded,
                  value: '${roster.valueOrNull?.length ?? 0}',
                  label: l.kpiParticipants,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: StatTile(
                  icon: Icons.event_available_rounded,
                  value: '${_count(appts, AppointmentStatus.confirmed)}',
                  label: l.kpiSessionsToday,
                  color: AppColors.info,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: StatTile(
                  icon: Icons.mark_email_unread_rounded,
                  value: '${_count(appts, AppointmentStatus.requested)}',
                  label: l.kpiRequests,
                  color: AppColors.accent,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),

          // Appointment requests
          SectionHeader(key: _coachRequestsKey, title: l.secAppointmentRequests),
          const SizedBox(height: AppSpacing.md),
          appts.when(
            loading: () => const _Loading(),
            error: (e, _) => Text('$e'),
            data: (list) {
              final requests = list
                  .where((a) => a.status == AppointmentStatus.requested)
                  .toList();
              if (requests.isEmpty) {
                return _EmptyCard(text: l.noPendingRequests);
              }
              return Column(
                children: [
                  for (final a in requests)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: AppointmentCard(
                        appointment: a,
                        onConfirm: () =>
                            _setStatus(ref, a.id, AppointmentStatus.confirmed),
                        onDecline: () =>
                            _setStatus(ref, a.id, AppointmentStatus.cancelled),
                      ),
                    ),
                ],
              );
            },
          ),
          const SizedBox(height: AppSpacing.xl),

          // Today's schedule
          SectionHeader(title: l.secTodaySchedule),
          const SizedBox(height: AppSpacing.md),
          appts.when(
            loading: () => const _Loading(),
            error: (e, _) => Text('$e'),
            data: (list) {
              final confirmed = list
                  .where((a) => a.status == AppointmentStatus.confirmed)
                  .toList();
              if (confirmed.isEmpty) {
                return _EmptyCard(text: l.nothingScheduledYet);
              }
              return Column(
                children: [
                  for (final a in confirmed)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: AppointmentCard(
                        appointment: a,
                        onComplete: () =>
                            _setStatus(ref, a.id, AppointmentStatus.completed),
                        onNoShow: () =>
                            _setStatus(ref, a.id, AppointmentStatus.noShow),
                        onAddNote: () =>
                            showConsultationNoteSheet(context, ref, a),
                      ),
                    ),
                ],
              );
            },
          ),
          const SizedBox(height: AppSpacing.xl),

          // Roster
          SectionHeader(title: l.secYourParticipants),
          const SizedBox(height: AppSpacing.md),
          roster.when(
            loading: () => const _Loading(),
            error: (e, _) => Text('$e'),
            data: (list) => Column(
              children: [
                for (final p in list)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: RosterTile(
                      participant: p,
                      onTap: () => _showParticipantSheet(context, p),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  int _count(AsyncValue<List<Appointment>> a, AppointmentStatus s) =>
      a.valueOrNull?.where((x) => x.status == s).length ?? 0;

  void _showParticipantSheet(BuildContext context, Participant p) {
    final l = AppLocalizations.of(context);
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (_) => Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(p.name, style: Theme.of(context).textTheme.titleLarge),
            Text('${p.city} · ${p.streak}',
                style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: AppSpacing.lg),
            _action(context, l, Icons.assignment_rounded, l.coachAssignPlan),
            _action(context, l, Icons.chat_rounded, l.coachMessage),
            _action(context, l, Icons.note_add_rounded, l.coachAddNote),
            _action(context, l, Icons.insights_rounded, l.coachViewProgress),
            const SizedBox(height: AppSpacing.md),
          ],
        ),
      ),
    );
  }

  Widget _action(
      BuildContext context, AppLocalizations l, IconData icon, String label) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primary),
      title: Text(label),
      onTap: () {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l.comingSoon(label))));
      },
    );
  }
}

class _Loading extends StatelessWidget {
  const _Loading();
  @override
  Widget build(BuildContext context) => const Padding(
        padding: EdgeInsets.all(AppSpacing.lg),
        child: Center(child: CircularProgressIndicator()),
      );
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard({required this.text});
  final String text;
  @override
  Widget build(BuildContext context) => GlassCard(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.sm),
            child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
          ),
        ),
      );
}
