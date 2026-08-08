import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../data/models/appointment.dart';
import '../../shared/widgets/app_snack.dart';
import '../../state/repository_providers.dart';

/// Opens a sheet for the doctor/trainer to write (or edit) their post-call note
/// and prescription for [appt]. Saved on the appointment; the participant sees
/// it under that booking.
Future<void> showConsultationNoteSheet(
  BuildContext context,
  WidgetRef ref,
  Appointment appt,
) {
  final controller = TextEditingController(text: appt.providerNote ?? '');
  final bool isDoctor = appt.providerRole == ProviderKind.doctor;
  DateTime? followUp = appt.followUpAt;

  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: AppColors.surfaceOf(context),
    builder: (sheetContext) {
      return StatefulBuilder(
        builder: (sheetContext, setSheetState) {
          Future<void> pickFollowUp() async {
            final now = DateTime.now();
            final picked = await showDatePicker(
              context: sheetContext,
              initialDate: followUp ?? now.add(const Duration(days: 14)),
              firstDate: now,
              lastDate: now.add(const Duration(days: 365)),
              helpText: 'Recommend a follow-up date',
            );
            if (picked != null) setSheetState(() => followUp = picked);
          }

          return Padding(
            padding: EdgeInsets.only(
              left: AppSpacing.lg,
              right: AppSpacing.lg,
              top: AppSpacing.sm,
              bottom:
                  MediaQuery.of(sheetContext).viewInsets.bottom + AppSpacing.lg,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isDoctor ? 'Note & prescription' : 'Session note',
                  style: Theme.of(sheetContext).textTheme.titleLarge,
                ),
                const SizedBox(height: 4),
                Text(
                  'For ${appt.participantName} · ${appt.type}',
                  style: Theme.of(sheetContext).textTheme.bodySmall,
                ),
                const SizedBox(height: AppSpacing.lg),
                TextField(
                  controller: controller,
                  maxLines: 6,
                  minLines: 4,
                  autofocus: true,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    hintText: isDoctor
                        ? 'Advice, diet tweaks, medicines/supplements, follow-up…'
                        : 'Workout focus, form cues, next session plan…',
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                // Optional follow-up date.
                Text('Recommend a follow-up (optional)',
                    style: Theme.of(sheetContext).textTheme.labelLarge),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: pickFollowUp,
                        icon: const Icon(Icons.event_rounded, size: 18),
                        label: Text(
                          followUp == null
                              ? 'Pick a date'
                              : DateFormat('EEE, d MMM yyyy').format(followUp!),
                        ),
                      ),
                    ),
                    if (followUp != null) ...[
                      const SizedBox(width: AppSpacing.sm),
                      IconButton(
                        tooltip: 'Clear',
                        onPressed: () => setSheetState(() => followUp = null),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),

                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () async {
                      final text = controller.text.trim();
                      if (text.isEmpty) {
                        showAppSnack(sheetContext, 'Please write a note first.',
                            type: AppSnackType.info);
                        return;
                      }
                      await ref
                          .read(staffRepositoryProvider)
                          .addConsultationNote(appt.id, text,
                              followUpAt: followUp);
                      if (sheetContext.mounted) {
                        Navigator.of(sheetContext).pop();
                      }
                      if (context.mounted) {
                        showAppSnack(
                            context, 'Note shared with the participant.',
                            type: AppSnackType.success);
                      }
                    },
                    icon: const Icon(Icons.send_rounded, size: 18),
                    label: const Text('Save & share'),
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
