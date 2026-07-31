import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../data/models/appointment.dart';
import '../../shared/widgets/glass_card.dart';
import '../../shared/widgets/section_header.dart';
import '../../state/providers.dart';
import '../../state/repository_providers.dart';

/// Time slots offered for booking.
const List<({String label, int hour})> _slots = [
  (label: '9:00 AM', hour: 9),
  (label: '10:00 AM', hour: 10),
  (label: '11:00 AM', hour: 11),
  (label: '4:00 PM', hour: 16),
  (label: '5:00 PM', hour: 17),
  (label: '6:00 PM', hour: 18),
  (label: '7:00 PM', hour: 19),
];

const List<String> _coachTypes = [
  'Yoga',
  'Walking',
  'Running',
  'Gym',
  'Zumba',
  'Mobility',
  'Home Workout',
];

const List<String> _doctorTypes = [
  'Diet Plan',
  'Indigestion',
  'Constipation',
  'Hormonal Issues',
  'Sleep Problems',
  'Weight Issues',
  'General Health',
];

/// Participant appointment-booking form: choose a session/consultation type,
/// a date, a time slot, add optional notes, and send the request.
class BookAppointmentScreen extends ConsumerStatefulWidget {
  const BookAppointmentScreen({super.key, required this.providerRole});

  final ProviderKind providerRole;

  @override
  ConsumerState<BookAppointmentScreen> createState() =>
      _BookAppointmentScreenState();
}

class _BookAppointmentScreenState extends ConsumerState<BookAppointmentScreen> {
  String? _type;
  late DateTime _date = DateTime.now();
  ({String label, int hour})? _slot;
  final TextEditingController _notes = TextEditingController();
  bool _submitting = false;

  bool get _isCoach => widget.providerRole == ProviderKind.coach;
  List<String> get _types => _isCoach ? _coachTypes : _doctorTypes;
  String get _providerName =>
      _isCoach ? AppConstants.coachName : AppConstants.doctorName;

  @override
  void dispose() {
    _notes.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_type == null || _slot == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Please choose a type and a time slot.')));
      return;
    }
    setState(() => _submitting = true);

    final participant = ref.read(participantProvider);
    final uid = ref.read(authUidProvider) ?? 'demo-user';
    final scheduled =
        DateTime(_date.year, _date.month, _date.day, _slot!.hour);

    final appointment = Appointment(
      id: 'a-${scheduled.millisecondsSinceEpoch}',
      participantId: uid,
      participantName: participant?.name ?? 'Participant',
      participantCity: participant?.city,
      providerRole: widget.providerRole,
      type: _type!,
      requestedAt: DateTime.now(),
      scheduledAt: scheduled,
      status: AppointmentStatus.requested,
    );

    await ref.read(appointmentBookingRepositoryProvider).book(appointment);
    if (!mounted) return;
    setState(() => _submitting = false);
    await _showConfirmation(scheduled);
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _showConfirmation(DateTime scheduled) {
    final when =
        '${DateFormat('EEE, d MMM').format(scheduled)} at ${_slot!.label}';
    return showDialog<void>(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: GlassCard(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 76,
                height: 76,
                decoration: const BoxDecoration(
                    gradient: AppColors.brandGradient, shape: BoxShape.circle),
                child: const Icon(Icons.event_available_rounded,
                    color: Colors.white, size: 40),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text('Request sent! 🎉',
                  style: Theme.of(context).textTheme.headlineSmall,
                  textAlign: TextAlign.center),
              const SizedBox(height: AppSpacing.sm),
              Text(
                '$_providerName will confirm your $_type on $when.',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xl),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Done'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final days = List.generate(14, (i) => DateTime.now().add(Duration(days: i)));

    return Scaffold(
      appBar: AppBar(title: Text('Book with $_providerName')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.xxl),
        children: [
          const SizedBox(height: AppSpacing.md),

          // Provider card
          GlassCard(
            child: Row(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor:
                      (_isCoach ? AppColors.taskFitness : AppColors.info)
                          .withOpacity(0.15),
                  child: Icon(
                    _isCoach
                        ? Icons.fitness_center_rounded
                        : Icons.medical_services_rounded,
                    color: _isCoach ? AppColors.taskFitness : AppColors.info,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_providerName, style: text.titleMedium),
                    Text(_isCoach ? 'Fitness Coach' : 'Consulting Doctor',
                        style: text.bodySmall),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          // Type
          SectionHeader(
              title: _isCoach ? 'Session type' : 'Consultation reason'),
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
                    color:
                        _type == t ? Colors.white : AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                  onSelected: (_) => setState(() => _type = t),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),

          // Date
          const SectionHeader(title: 'Select date'),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            height: 82,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: days.length,
              separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
              itemBuilder: (context, i) {
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
                                color:
                                    sel ? Colors.white : AppColors.textPrimary,
                                fontSize: 20,
                                fontWeight: FontWeight.w800)),
                        const SizedBox(height: 2),
                        Text(DateFormat('MMM').format(d),
                            style: TextStyle(
                                color: sel
                                    ? Colors.white70
                                    : AppColors.textSecondary,
                                fontSize: 11)),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          // Time slot
          const SectionHeader(title: 'Select time slot'),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.xs,
            children: [
              for (final s in _slots)
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

          // Notes
          const SectionHeader(title: 'Notes (optional)'),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _notes,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: 'Anything the coach/doctor should know…',
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          FilledButton(
            onPressed: _submitting ? null : _submit,
            child: _submitting
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : const Text('Confirm booking'),
          ),
        ],
      ),
    );
  }
}
