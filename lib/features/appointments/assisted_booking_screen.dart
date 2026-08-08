import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../data/models/appointment.dart';
import '../../data/models/participant.dart';
import '../../shared/widgets/app_snack.dart';
import '../../shared/widgets/glass_card.dart';
import '../../shared/widgets/section_header.dart';
import '../../state/repository_providers.dart';
import '../../state/staff_providers.dart';
import 'consult_slots.dart';
import 'reschedule_sheet.dart';

const List<String> _doctorTypes = [
  'Diet Plan',
  'Indigestion',
  'Constipation',
  'Hormonal Issues',
  'Sleep Problems',
  'Weight Issues',
  'General Health',
];
const List<String> _trainerTypes = [
  'Yoga',
  'Walking',
  'Running',
  'Gym',
  'Zumba',
  'Mobility',
  'Home Workout',
];

/// Care-team (customer relationship team) assisted booking: a staff member
/// books a doctor/trainer consultation on a participant's behalf. Booking is
/// support only — the CRT cannot diagnose, prescribe or give clinical advice.
class AssistedBookingScreen extends ConsumerStatefulWidget {
  const AssistedBookingScreen({super.key, required this.participant});

  final Participant participant;

  @override
  ConsumerState<AssistedBookingScreen> createState() =>
      _AssistedBookingScreenState();
}

class _AssistedBookingScreenState extends ConsumerState<AssistedBookingScreen> {
  ProviderKind _role = ProviderKind.doctor;
  ConsultMode _mode = ConsultMode.videoCall;
  String? _type;
  late DateTime _date = DateTime.now();
  ({String label, int hour})? _slot;
  final _notes = TextEditingController();
  bool _submitting = false;

  bool get _isDoctor => _role == ProviderKind.doctor;
  List<String> get _types => _isDoctor ? _doctorTypes : _trainerTypes;

  @override
  void dispose() {
    _notes.dispose();
    super.dispose();
  }

  Future<void> _submit(List<Appointment> theirs) async {
    if (_type == null || _slot == null) {
      showAppSnack(context, 'Choose a type and a time slot.',
          type: AppSnackType.info);
      return;
    }
    // One pending appointment per provider for this participant.
    final hasOpen = theirs.any((a) =>
        a.providerRole == _role &&
        (a.status == AppointmentStatus.requested ||
            a.status == AppointmentStatus.confirmed ||
            a.status == AppointmentStatus.rescheduled));
    if (hasOpen) {
      showAppSnack(
        context,
        '${widget.participant.name} already has a pending '
        '${_isDoctor ? 'doctor' : 'trainer'} appointment.',
        type: AppSnackType.info,
      );
      return;
    }

    setState(() => _submitting = true);
    final scheduled =
        DateTime(_date.year, _date.month, _date.day, _slot!.hour);
    final room = 'DayjoyFit90${_isDoctor ? 'Doctor' : 'Trainer'}'
        '${scheduled.millisecondsSinceEpoch}';
    final appt = Appointment(
      id: 'a-${scheduled.millisecondsSinceEpoch}',
      participantId: widget.participant.id,
      participantName: widget.participant.name,
      participantCity: widget.participant.city,
      providerRole: _role,
      type: _type!,
      requestedAt: DateTime.now(),
      scheduledAt: scheduled,
      status: AppointmentStatus.requested,
      mode: _mode,
      meetingRoom: room,
      notes: _notes.text.trim().isEmpty
          ? 'Booked by Care team'
          : 'Care team: ${_notes.text.trim()}',
    );
    await ref.read(appointmentBookingRepositoryProvider).book(appt);
    if (!mounted) return;
    setState(() => _submitting = false);
    showAppSnack(context,
        'Booked for ${widget.participant.name} — awaiting provider confirmation.',
        type: AppSnackType.success);
    Navigator.of(context).pop();
  }

  Widget _existingCard(BuildContext context, Appointment a) {
    final TextTheme text = Theme.of(context).textTheme;
    final bool isDoctor = a.providerRole == ProviderKind.doctor;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: GlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isDoctor
                      ? Icons.medical_services_rounded
                      : Icons.fitness_center_rounded,
                  size: 18,
                  color: AppColors.primary,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    '${isDoctor ? 'Doctor' : 'Trainer'} · ${a.type} · ${a.mode.label}',
                    style: text.bodyMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
                Text(a.status.label,
                    style: text.bodySmall
                        ?.copyWith(color: AppColors.textSecondary)),
              ],
            ),
            if (a.scheduledAt != null) ...[
              const SizedBox(height: 4),
              Text(DateFormat('EEE d MMM, h:mm a').format(a.scheduledAt!),
                  style: text.bodySmall),
            ],
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => showRescheduleSheet(context, ref, a),
                    icon: const Icon(Icons.event_repeat_rounded, size: 18),
                    label: const Text('Reschedule'),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _cancel(a),
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
          ],
        ),
      ),
    );
  }

  Future<void> _cancel(Appointment a) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (dctx) => AlertDialog(
        backgroundColor: AppColors.surfaceOf(dctx),
        title: const Text('Cancel booking?'),
        content: Text(
            'Cancel the ${a.mode.label.toLowerCase()} (${a.type}) for '
            '${widget.participant.name}?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(dctx).pop(false),
              child: const Text('Keep')),
          FilledButton(
            onPressed: () => Navigator.of(dctx).pop(true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Cancel it'),
          ),
        ],
      ),
    );
    if (yes == true) {
      await ref
          .read(staffRepositoryProvider)
          .updateAppointmentStatus(a.id, AppointmentStatus.cancelled);
      if (mounted) {
        showAppSnack(context, 'Booking cancelled.', type: AppSnackType.info);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final days = List.generate(14, (i) => DateTime.now().add(Duration(days: i)));
    final theirsAsync =
        ref.watch(participantAppointmentsProvider(widget.participant.id));
    final theirs = theirsAsync.valueOrNull ?? const <Appointment>[];

    return Scaffold(
      appBar: AppBar(title: const Text('Assisted booking')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.xxl),
        children: [
          const SizedBox(height: AppSpacing.md),
          GlassCard(
            child: Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: AppColors.primary.withOpacity(0.15),
                  child: Text(widget.participant.name.characters.first,
                      style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700)),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Booking for ${widget.participant.name}',
                          style: text.titleMedium),
                      Text(widget.participant.city, style: text.bodySmall),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // CRT boundary note.
          GlassCard(
            child: Row(
              children: [
                const Icon(Icons.info_outline_rounded, color: AppColors.info),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    'Care team assists with booking only — it cannot diagnose, '
                    'prescribe or give clinical advice. The doctor or trainer '
                    'confirms and conducts the consultation.',
                    style: text.bodySmall,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          // Existing open bookings — reschedule or cancel on their behalf.
          Builder(builder: (context) {
            final open = theirs
                .where((a) =>
                    a.status == AppointmentStatus.requested ||
                    a.status == AppointmentStatus.confirmed ||
                    a.status == AppointmentStatus.rescheduled)
                .toList();
            if (open.isEmpty) return const SizedBox.shrink();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionHeader(title: 'Current bookings'),
                const SizedBox(height: AppSpacing.md),
                for (final a in open) _existingCard(context, a),
                const SizedBox(height: AppSpacing.xl),
              ],
            );
          }),

          const SectionHeader(title: 'Provider'),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: _Choice(
                  label: 'Doctor',
                  icon: Icons.medical_services_rounded,
                  selected: _isDoctor,
                  onTap: () => setState(() {
                    _role = ProviderKind.doctor;
                    _type = null;
                  }),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _Choice(
                  label: 'Trainer',
                  icon: Icons.fitness_center_rounded,
                  selected: !_isDoctor,
                  onTap: () => setState(() {
                    _role = ProviderKind.coach;
                    _type = null;
                  }),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),

          const SectionHeader(title: 'Consultation mode'),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: _Choice(
                  label: 'Video call',
                  icon: Icons.videocam_rounded,
                  selected: _mode == ConsultMode.videoCall,
                  onTap: () => setState(() => _mode = ConsultMode.videoCall),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _Choice(
                  label: 'Voice call',
                  icon: Icons.call_rounded,
                  selected: _mode == ConsultMode.audioCall,
                  onTap: () => setState(() => _mode = ConsultMode.audioCall),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),

          SectionHeader(title: _isDoctor ? 'Consultation reason' : 'Session type'),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.xs,
            children: [
              for (final t in _types)
                ChoiceChip(
                  label: Text(t),
                  selected: _type == t,
                  labelStyle: TextStyle(
                    color: _type == t ? Colors.white : AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                  onSelected: (_) => setState(() => _type = t),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),

          const SectionHeader(title: 'Date'),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            height: 82,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: days.length,
              separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
              itemBuilder: (_, i) {
                final d = days[i];
                final bool sel = d.day == _date.day &&
                    d.month == _date.month &&
                    d.year == _date.year;
                return GestureDetector(
                  onTap: () => setState(() => _date = d),
                  child: Container(
                    width: 60,
                    decoration: BoxDecoration(
                      gradient: sel ? AppColors.brandGradient : null,
                      color: sel ? null : AppColors.surfaceMuted,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(DateFormat('EEE').format(d),
                            style: TextStyle(
                                color: sel
                                    ? Colors.white70
                                    : AppColors.textSecondary,
                                fontSize: 12)),
                        const SizedBox(height: 4),
                        Text('${d.day}',
                            style: TextStyle(
                                color: sel
                                    ? Colors.white
                                    : AppColors.textPrimary,
                                fontSize: 20,
                                fontWeight: FontWeight.w800)),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          const SectionHeader(title: 'Time slot'),
          const SizedBox(height: 4),
          Text('Consultations run 10 AM–6 PM IST on operating days.',
              style: text.bodySmall?.copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.xs,
            children: [
              for (final s in kConsultSlots)
                ChoiceChip(
                  label: Text(s.label),
                  selected: _slot?.label == s.label,
                  labelStyle: TextStyle(
                    color: _slot?.label == s.label
                        ? Colors.white
                        : AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                  onSelected: (_) => setState(() => _slot = s),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),

          const SectionHeader(title: 'Preliminary info (optional)'),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _notes,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: 'Symptoms/goal the participant shared…',
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          FilledButton(
            onPressed: _submitting ? null : () => _submit(theirs),
            child: _submitting
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : const Text('Book on participant’s behalf'),
          ),
        ],
      ),
    );
  }
}

class _Choice extends StatelessWidget {
  const _Choice({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
        decoration: BoxDecoration(
          gradient: selected ? AppColors.brandGradient : null,
          color: selected
              ? null
              : (isDark ? AppColors.surfaceMutedDark : AppColors.surfaceMuted),
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Column(
          children: [
            Icon(icon,
                color: selected ? Colors.white : AppColors.primary, size: 26),
            const SizedBox(height: 6),
            Text(label,
                style: TextStyle(
                    color: selected ? Colors.white : null,
                    fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}
