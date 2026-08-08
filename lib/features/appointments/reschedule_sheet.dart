import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../data/models/appointment.dart';
import '../../shared/widgets/app_snack.dart';
import '../../state/repository_providers.dart';
import 'consult_slots.dart';


/// Lets the participant pick a new date + time slot for [appt]. Reschedules it
/// to a pending request so the provider re-confirms.
Future<void> showRescheduleSheet(
  BuildContext context,
  WidgetRef ref,
  Appointment appt,
) {
  DateTime date = DateTime.now();
  ({String label, int hour})? slot;

  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: AppColors.surfaceOf(context),
    builder: (sheetContext) {
      final days =
          List.generate(14, (i) => DateTime.now().add(Duration(days: i)));
      return StatefulBuilder(
        builder: (sheetContext, setSheetState) {
          return Padding(
            padding: EdgeInsets.only(
              left: AppSpacing.lg,
              right: AppSpacing.lg,
              top: AppSpacing.sm,
              bottom: AppSpacing.lg,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Reschedule',
                    style: Theme.of(sheetContext).textTheme.titleLarge),
                const SizedBox(height: 4),
                Text('${appt.type} · ${appt.mode.label}',
                    style: Theme.of(sheetContext).textTheme.bodySmall),
                const SizedBox(height: AppSpacing.lg),

                Text('New date',
                    style: Theme.of(sheetContext).textTheme.labelLarge),
                const SizedBox(height: AppSpacing.sm),
                SizedBox(
                  height: 82,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: days.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(width: AppSpacing.sm),
                    itemBuilder: (_, i) {
                      final d = days[i];
                      final bool sel = d.day == date.day &&
                          d.month == date.month &&
                          d.year == date.year;
                      return GestureDetector(
                        onTap: () => setSheetState(() => date = d),
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
                const SizedBox(height: AppSpacing.lg),

                Text('New time slot',
                    style: Theme.of(sheetContext).textTheme.labelLarge),
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.xs,
                  children: [
                    for (final s in kConsultSlots)
                      ChoiceChip(
                        label: Text(s.label),
                        selected: slot?.label == s.label,
                        labelStyle: TextStyle(
                          color: slot?.label == s.label
                              ? Colors.white
                              : AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                        onSelected: (_) => setSheetState(() => slot = s),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),

                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () async {
                      if (slot == null) {
                        showAppSnack(sheetContext, 'Please pick a time slot.',
                            type: AppSnackType.info);
                        return;
                      }
                      final when = DateTime(
                          date.year, date.month, date.day, slot!.hour);
                      await ref
                          .read(staffRepositoryProvider)
                          .rescheduleAppointment(appt.id, when);
                      if (sheetContext.mounted) {
                        Navigator.of(sheetContext).pop();
                      }
                      if (context.mounted) {
                        showAppSnack(context,
                            'Rescheduled — waiting for confirmation.',
                            type: AppSnackType.success);
                      }
                    },
                    icon: const Icon(Icons.event_repeat_rounded, size: 18),
                    label: const Text('Confirm new time'),
                  ),
                ),
              ],
            ),
          );
        },
      );
    },
  );
}
