import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../data/models/admin_models.dart';
import '../../../data/models/health_enums.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/section_header.dart';
import '../../../shared/widgets/stat_tile.dart';
import '../../../state/repository_providers.dart';
import '../../../state/staff_providers.dart';
import '../widgets/staff_widgets.dart';

class AdminDashboard extends ConsumerStatefulWidget {
  const AdminDashboard({super.key});

  @override
  ConsumerState<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends ConsumerState<AdminDashboard> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final tabs = [l.tabOverview, l.tabParticipants, l.tabSubmissions, l.tabReports];
    return Scaffold(
      appBar: AppBar(
        title: Text(l.adminTitle),
        actions: const [StaffSignOutAction()],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.xxl),
        children: [
          StaffHeaderCard(
            name: 'Dayjoy Fit90',
            role: l.roleAdministrator,
            icon: Icons.admin_panel_settings_rounded,
          ),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: tabs.length,
              separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
              itemBuilder: (context, i) => ChoiceChip(
                label: Text(tabs[i]),
                selected: _tab == i,
                labelStyle: TextStyle(
                  color: _tab == i ? Colors.white : AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
                onSelected: (_) => setState(() => _tab = i),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          switch (_tab) {
            0 => const _OverviewTab(),
            1 => const _ParticipantsTab(),
            2 => const _SubmissionsTab(),
            _ => const _ReportsTab(),
          },
        ],
      ),
    );
  }
}

// ===== Overview ============================================================

class _OverviewTab extends ConsumerWidget {
  const _OverviewTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(adminStatsProvider);
    final l = AppLocalizations.of(context);
    return stats.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Text('$e'),
      data: (s) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: AppSpacing.md,
            crossAxisSpacing: AppSpacing.md,
            childAspectRatio: 1.4,
            children: [
              StatTile(
                icon: Icons.groups_rounded,
                value: '${s.totalParticipants}',
                label: l.kpiParticipants,
                color: AppColors.primary,
              ),
              StatTile(
                icon: Icons.bolt_rounded,
                value: '${s.activeToday}',
                label: l.kpiActiveToday,
                color: AppColors.secondary,
              ),
              StatTile(
                icon: Icons.upload_file_rounded,
                value: '${s.submissionsToday}',
                label: l.kpiSubmissionsToday,
                color: AppColors.info,
              ),
              StatTile(
                icon: Icons.percent_rounded,
                value: '${(s.avgCompletion * 100).round()}%',
                label: l.kpiAvgCompletion,
                color: AppColors.accent,
              ),
              StatTile(
                icon: Icons.pending_actions_rounded,
                value: '${s.pendingVerifications}',
                label: l.kpiPendingReviews,
                color: AppColors.warning,
              ),
              StatTile(
                icon: Icons.trending_down_rounded,
                value: '${s.totalWeightLostKg.toStringAsFixed(0)} kg',
                label: l.kpiTotalLost,
                color: AppColors.success,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          SectionHeader(title: l.completionLast7),
          const SizedBox(height: AppSpacing.md),
          GlassCard(child: _CompletionBars(values: s.completionSeries)),
        ],
      ),
    );
  }
}

class _CompletionBars extends StatelessWidget {
  const _CompletionBars({required this.values});
  final List<double> values;

  @override
  Widget build(BuildContext context) {
    const labels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    return SizedBox(
      height: 140,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (int i = 0; i < values.length; i++)
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text('${(values[i] * 100).round()}',
                      style: Theme.of(context).textTheme.bodySmall),
                  const SizedBox(height: 4),
                  Container(
                    height: 90 * values[i].clamp(0.0, 1.0),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      gradient: AppColors.brandGradient,
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(6)),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(labels[i % labels.length],
                      style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ===== Participants ========================================================

class _ParticipantsTab extends ConsumerStatefulWidget {
  const _ParticipantsTab();
  @override
  ConsumerState<_ParticipantsTab> createState() => _ParticipantsTabState();
}

class _ParticipantsTabState extends ConsumerState<_ParticipantsTab> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final participants = ref.watch(adminParticipantsProvider);
    final l = AppLocalizations.of(context);
    return Column(
      children: [
        TextField(
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.search_rounded),
            hintText: l.searchParticipants,
          ),
          onChanged: (v) => setState(() => _query = v.toLowerCase()),
        ),
        const SizedBox(height: AppSpacing.lg),
        participants.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Text('$e'),
          data: (list) {
            final filtered = list
                .where((p) =>
                    p.name.toLowerCase().contains(_query) ||
                    p.city.toLowerCase().contains(_query))
                .toList();
            return Column(
              children: [
                for (final p in filtered)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: RosterTile(participant: p),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

// ===== Submissions =========================================================

class _SubmissionsTab extends ConsumerWidget {
  const _SubmissionsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final queue = ref.watch(verificationQueueProvider);
    final l = AppLocalizations.of(context);
    return queue.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Text('$e'),
      data: (list) {
        if (list.isEmpty) {
          return GlassCard(child: Text(l.queueClear));
        }
        return Column(
          children: [
            for (final s in list)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: _SubmissionCard(
                  review: s,
                  onApprove: () => ref
                      .read(adminRepositoryProvider)
                      .setSubmissionApproved(s.id, true),
                  onReject: () => ref
                      .read(adminRepositoryProvider)
                      .setSubmissionApproved(s.id, false),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _SubmissionCard extends StatelessWidget {
  const _SubmissionCard({
    required this.review,
    required this.onApprove,
    required this.onReject,
  });

  final SubmissionReview review;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  String _methodLabel(AppLocalizations l) => switch (review.method) {
        VerificationMethod.automaticHealthSync => l.modeAuto,
        VerificationMethod.screenshot => l.modeScreenshot,
        VerificationMethod.manualEntry => l.modeManual,
      };

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final l = AppLocalizations.of(context);
    final bool decided = review.status != AdminVerificationStatus.pending;

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${review.participantName} · ${review.taskTitle}',
                        style: text.titleMedium),
                    Text(
                      '${_methodLabel(l)} · ${DateFormat('h:mm a').format(review.submittedAt)}',
                      style: text.bodySmall,
                    ),
                  ],
                ),
              ),
              if (decided)
                Icon(
                  review.status == AdminVerificationStatus.approved
                      ? Icons.check_circle_rounded
                      : Icons.cancel_rounded,
                  color: review.status == AdminVerificationStatus.approved
                      ? AppColors.success
                      : AppColors.error,
                ),
            ],
          ),
          if (review.flaggedDuplicate || review.isLate) ...[
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              children: [
                if (review.flaggedDuplicate)
                  _Flag(label: l.flagDuplicate, color: AppColors.error),
                if (review.isLate)
                  _Flag(label: l.flagLate, color: AppColors.warning),
              ],
            ),
          ],
          if (!decided) ...[
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onReject,
                    child: Text(l.actionReject),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: FilledButton(
                    onPressed: onApprove,
                    child: Text(l.actionApprove),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _Flag extends StatelessWidget {
  const _Flag({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
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

// ===== Reports =============================================================

class _ReportsTab extends ConsumerWidget {
  const _ReportsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    Future<void> export() async {
      final messenger = ScaffoldMessenger.of(context);
      messenger.showSnackBar(SnackBar(content: Text(l.generatingExport)));
      final url = await ref.read(adminRepositoryProvider).exportParticipantsCsv();
      messenger.showSnackBar(SnackBar(content: Text(l.exportReady(url))));
    }

    final reports = <(IconData, String)>[
      (Icons.today_rounded, l.reportDailyCompletion),
      (Icons.person_rounded, l.reportParticipant),
      (Icons.store_rounded, l.reportDistributor),
      (Icons.location_city_rounded, l.reportCity),
      (Icons.monitor_weight_rounded, l.reportWeightProgress),
      (Icons.warning_amber_rounded, l.reportMissedActivities),
      (Icons.medical_information_rounded, l.reportConsultation),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: export,
                icon: const Icon(Icons.grid_on_rounded),
                label: Text(l.exportExcel),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: export,
                icon: const Icon(Icons.picture_as_pdf_rounded),
                label: Text(l.exportPdf),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),
        SectionHeader(title: l.reportsSection),
        const SizedBox(height: AppSpacing.md),
        GlassCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              for (int i = 0; i < reports.length; i++) ...[
                ListTile(
                  leading: Icon(reports[i].$1, color: AppColors.primary),
                  title: Text(reports[i].$2),
                  trailing:
                      const Icon(Icons.download_rounded, size: 20),
                  onTap: export,
                ),
                if (i < reports.length - 1)
                  const Divider(height: 1, indent: 56, endIndent: 16),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
