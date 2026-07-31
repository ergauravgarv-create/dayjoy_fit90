import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/admin_models.dart';
import '../data/models/appointment.dart';
import '../data/models/participant.dart';
import 'repository_providers.dart';

/// Live data for the coach / doctor / admin dashboards.

final rosterProvider = StreamProvider.autoDispose<List<Participant>>(
    (ref) => ref.watch(staffRepositoryProvider).watchRoster());

final coachAppointmentsProvider =
    StreamProvider.autoDispose<List<Appointment>>((ref) =>
        ref.watch(staffRepositoryProvider).watchAppointments(ProviderKind.coach));

final doctorAppointmentsProvider =
    StreamProvider.autoDispose<List<Appointment>>((ref) => ref
        .watch(staffRepositoryProvider)
        .watchAppointments(ProviderKind.doctor));

final adminStatsProvider = StreamProvider.autoDispose<AdminStats>(
    (ref) => ref.watch(adminRepositoryProvider).watchStats());

final adminParticipantsProvider = StreamProvider.autoDispose<List<Participant>>(
    (ref) => ref.watch(adminRepositoryProvider).watchParticipants());

final verificationQueueProvider =
    StreamProvider.autoDispose<List<SubmissionReview>>((ref) =>
        ref.watch(adminRepositoryProvider).watchVerificationQueue());
