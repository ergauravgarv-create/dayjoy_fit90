import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../data/models/appointment.dart';
import '../../../data/models/participant.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../diet_charts/diet_chart_assessment_screen.dart';
import '../../diet_charts/diet_chart_library_screen.dart';
import '../../meals/edit_diet_plan_screen.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/section_header.dart';
import '../../../shared/widgets/stat_tile.dart';
import '../../../state/repository_providers.dart';
import '../../../state/staff_providers.dart';
import '../../../state/supplement_provider.dart';
import '../../supplements/supplement_review_screen.dart';
import '../consult_note_sheet.dart';
import '../widgets/staff_widgets.dart';

/// Anchors the "Consultation requests" section so the new-booking banner can
/// scroll straight to it. Stable across rebuilds (only one dashboard is live).
final GlobalKey _doctorRequestsKey = GlobalKey();

class DoctorDashboard extends ConsumerWidget {
  const DoctorDashboard({super.key});

  Future<void> _setStatus(WidgetRef ref, String id, AppointmentStatus s) =>
      ref.read(staffRepositoryProvider).updateAppointmentStatus(id, s);

  void _scrollToRequests() {
    final ctx = _doctorRequestsKey.currentContext;
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
    final appts = ref.watch(doctorAppointmentsProvider);
    final pendingSupp = ref.watch(pendingSupplementRequestsProvider);
    final l = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l.doctorDashboard),
        actions: const [StaffSignOutAction()],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.xxl),
        children: [
          StaffHeaderCard(
            name: AppConstants.doctorName,
            role: l.roleConsultingDoctor,
            icon: Icons.medical_services_rounded,
          ),
          const SizedBox(height: AppSpacing.lg),

          // New booking alert (clears once all requests are handled).
          NewBookingsBanner(
            requests: (appts.valueOrNull ?? const [])
                .where((a) => a.status == AppointmentStatus.requested)
                .toList(),
            onTap: _scrollToRequests,
          ),

          Row(
            children: [
              Expanded(
                child: StatTile(
                  icon: Icons.people_alt_rounded,
                  value: '${roster.valueOrNull?.length ?? 0}',
                  label: l.kpiPatients,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: StatTile(
                  icon: Icons.event_available_rounded,
                  value: '${_count(appts, AppointmentStatus.confirmed)}',
                  label: l.kpiConsultsToday,
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

          SectionHeader(
              key: _doctorRequestsKey, title: l.secConsultationRequests),
          const SizedBox(height: AppSpacing.md),
          appts.when(
            loading: () => const _Loading(),
            error: (e, _) => Text('$e'),
            data: (list) {
              final requests = list
                  .where((a) => a.status == AppointmentStatus.requested)
                  .toList();
              if (requests.isEmpty) {
                return _EmptyCard(text: l.noPendingConsults);
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

          const SectionHeader(title: 'Dayjoy supplement requests'),
          const SizedBox(height: AppSpacing.md),
          if (pendingSupp.isEmpty)
            const _EmptyCard(text: 'No supplement consultations pending.')
          else
            Column(
              children: [
                for (final r in pendingSupp)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: GlassCard(
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                            builder: (_) =>
                                SupplementReviewScreen(request: r)),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundColor:
                                AppColors.orange.withOpacity(0.14),
                            child: Icon(
                                r.kind == 'skin'
                                    ? Icons.face_retouching_natural_rounded
                                    : Icons.medication_liquid_rounded,
                                color: AppColors.orange),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(r.conditions.join(', '),
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleSmall,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis),
                                Text(
                                    '${r.kind == 'skin' ? 'Skin routine' : 'Supplement'}'
                                    ' · ${r.items.length} products'
                                    '${r.reportPhoto != null ? ' · ${r.kind == 'skin' ? 'face photo' : 'report'} attached' : ''}',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                            color: AppColors.textSecondary)),
                              ],
                            ),
                          ),
                          const Icon(Icons.rate_review_rounded,
                              color: AppColors.primary),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          const SizedBox(height: AppSpacing.xl),

          SectionHeader(title: l.secTodayConsults),
          const SizedBox(height: AppSpacing.md),
          appts.when(
            loading: () => const _Loading(),
            error: (e, _) => Text('$e'),
            data: (list) {
              final confirmed = list
                  .where((a) => a.status == AppointmentStatus.confirmed)
                  .toList();
              if (confirmed.isEmpty) {
                return _EmptyCard(text: l.nothingScheduled);
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

          SectionHeader(title: l.secPatients),
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
                      onTap: () => _showPatientSheet(context, p),
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

  void _showPatientSheet(BuildContext context, Participant p) {
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
            Text('${p.gender}, ${p.age} · BMI ${p.bmi.toStringAsFixed(1)}',
                style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: AppSpacing.lg),
            _action(context, l, Icons.assignment_turned_in_rounded,
                'Assess & suggest chart',
                onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                          builder: (_) =>
                              DietChartAssessmentScreen(participant: p)),
                    )),
            _action(context, l, Icons.menu_book_rounded, 'Browse chart library',
                onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                          builder: (_) =>
                              DietChartLibraryScreen(participant: p)),
                    )),
            _action(context, l, Icons.restaurant_menu_rounded, l.docCreateDiet,
                onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                          builder: (_) => EditDietPlanScreen(participant: p)),
                    )),
            _action(context, l, Icons.note_add_rounded, l.docAddNote),
            _action(context, l, Icons.folder_shared_rounded, l.docMedicalUploads),
            _action(context, l, Icons.history_rounded, l.docPrevConsults),
            const SizedBox(height: AppSpacing.md),
          ],
        ),
      ),
    );
  }

  Widget _action(
      BuildContext context, AppLocalizations l, IconData icon, String label,
      {VoidCallback? onTap}) {
    return ListTile(
      leading: Icon(icon, color: AppColors.info),
      title: Text(label),
      onTap: () {
        Navigator.of(context).pop(); // close the patient sheet
        if (onTap != null) {
          onTap();
        } else {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(l.comingSoon(label))));
        }
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
