import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../data/models/appointment.dart';
import '../../shared/widgets/glass_card.dart';
import '../subscription/paywall.dart';
import 'book_appointment_screen.dart';
import 'my_appointments_screen.dart';

/// Entry point for consultations: pick a doctor or trainer to book a video/voice
/// call, or view your existing consultations.
class BookConsultChooserScreen extends ConsumerWidget {
  const BookConsultChooserScreen({super.key});

  void _book(BuildContext context, WidgetRef ref, ProviderKind role) {
    // Booking a consultation is premium — closes every path into booking.
    final name = role == ProviderKind.doctor
        ? 'Doctor consultation'
        : 'Trainer consultation';
    if (!ensurePremium(context, ref, name)) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => BookAppointmentScreen(providerRole: role),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final TextTheme text = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Consult a specialist')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.xxl),
        children: [
          Text('Book a private video or voice call — it happens right here in '
              'the app.', style: text.bodyMedium),
          const SizedBox(height: AppSpacing.lg),
          _ProviderCard(
            icon: Icons.medical_services_rounded,
            accent: AppColors.info,
            name: AppConstants.doctorName,
            role: 'Consulting Doctor',
            blurb: 'Diet, health issues, sleep, weight & more',
            onTap: () => _book(context, ref, ProviderKind.doctor),
          ),
          const SizedBox(height: AppSpacing.md),
          _ProviderCard(
            icon: Icons.fitness_center_rounded,
            accent: AppColors.taskFitness,
            name: AppConstants.coachName,
            role: 'Fitness Trainer',
            blurb: 'Workouts, form, yoga & routine guidance',
            onTap: () => _book(context, ref, ProviderKind.coach),
          ),
          const SizedBox(height: AppSpacing.xl),
          OutlinedButton.icon(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                  builder: (_) => const MyAppointmentsScreen()),
            ),
            icon: const Icon(Icons.event_note_rounded),
            label: const Text('My consultations'),
          ),
        ],
      ),
    );
  }
}

class _ProviderCard extends StatelessWidget {
  const _ProviderCard({
    required this.icon,
    required this.accent,
    required this.name,
    required this.role,
    required this.blurb,
    required this.onTap,
  });

  final IconData icon;
  final Color accent;
  final String name;
  final String role;
  final String blurb;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return GlassCard(
      onTap: onTap,
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: accent.withOpacity(0.15),
            child: Icon(icon, color: accent, size: 28),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: text.titleMedium),
                Text(role,
                    style: text.bodySmall
                        ?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(blurb, style: text.bodySmall),
              ],
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.videocam_rounded,
                  size: 18, color: AppColors.textSecondary),
              const SizedBox(width: 4),
              Icon(Icons.call_rounded,
                  size: 18, color: AppColors.textSecondary),
              const SizedBox(width: AppSpacing.sm),
              const Icon(Icons.chevron_right_rounded,
                  color: AppColors.textSecondary),
            ],
          ),
        ],
      ),
    );
  }
}
