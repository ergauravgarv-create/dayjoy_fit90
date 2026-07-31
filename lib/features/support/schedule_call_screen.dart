import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../shared/widgets/glass_card.dart';
import '../../shared/widgets/section_header.dart';
import '../../state/providers.dart';

const List<({String label, int hour})> _slots = [
  (label: '10:00 AM', hour: 10),
  (label: '11:00 AM', hour: 11),
  (label: '12:00 PM', hour: 12),
  (label: '4:00 PM', hour: 16),
  (label: '5:00 PM', hour: 17),
  (label: '6:00 PM', hour: 18),
  (label: '7:00 PM', hour: 19),
];

/// Request a callback from Dayjoy Care at a preferred date & time.
class ScheduleCallScreen extends ConsumerStatefulWidget {
  const ScheduleCallScreen({super.key});

  @override
  ConsumerState<ScheduleCallScreen> createState() => _ScheduleCallScreenState();
}

class _ScheduleCallScreenState extends ConsumerState<ScheduleCallScreen> {
  late DateTime _date = DateTime.now();
  ({String label, int hour})? _slot;
  final TextEditingController _phone = TextEditingController();
  final TextEditingController _reason = TextEditingController();
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _phone.text = ref.read(participantProvider)?.mobile ?? '';
  }

  @override
  void dispose() {
    _phone.dispose();
    _reason.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_slot == null || _phone.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Please pick a time slot and enter a phone number.')));
      return;
    }
    setState(() => _submitting = true);
    await Future<void>.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    setState(() => _submitting = false);

    final when =
        '${DateFormat('EEE, d MMM').format(_date)} at ${_slot!.label}';
    await showDialog<void>(
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
                child: const Icon(Icons.phone_in_talk_rounded,
                    color: Colors.white, size: 38),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text('Callback scheduled! 📞',
                  style: Theme.of(context).textTheme.headlineSmall,
                  textAlign: TextAlign.center),
              const SizedBox(height: AppSpacing.sm),
              Text('Dayjoy Care will call you on $when.',
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center),
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
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final days = List.generate(14, (i) => DateTime.now().add(Duration(days: i)));
    return Scaffold(
      appBar: AppBar(title: const Text('Schedule a call')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.xxl),
        children: [
          const SizedBox(height: AppSpacing.md),
          const SectionHeader(title: 'Preferred date'),
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
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          const SectionHeader(title: 'Preferred time'),
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

          const SectionHeader(title: 'Your phone number'),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _phone,
            keyboardType: TextInputType.phone,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9+ ]'))
            ],
            decoration: const InputDecoration(hintText: 'Mobile number'),
          ),
          const SizedBox(height: AppSpacing.lg),
          TextField(
            controller: _reason,
            decoration: const InputDecoration(
                labelText: 'Reason (optional)'),
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
                : const Text('Request callback'),
          ),
        ],
      ),
    );
  }
}
