/// Which kind of provider an appointment is with.
enum ProviderKind { coach, doctor }

enum AppointmentStatus { requested, confirmed, rescheduled, completed, cancelled }

extension AppointmentStatusX on AppointmentStatus {
  String get label => switch (this) {
        AppointmentStatus.requested => 'Requested',
        AppointmentStatus.confirmed => 'Confirmed',
        AppointmentStatus.rescheduled => 'Rescheduled',
        AppointmentStatus.completed => 'Completed',
        AppointmentStatus.cancelled => 'Cancelled',
      };
}

/// A coach or doctor appointment. Mirrors the Firestore `appointments/{id}`
/// document.
class Appointment {
  const Appointment({
    required this.id,
    required this.participantId,
    required this.participantName,
    required this.providerRole,
    required this.type,
    required this.requestedAt,
    this.scheduledAt,
    this.status = AppointmentStatus.requested,
    this.notes,
    this.participantCity,
  });

  final String id;
  final String participantId;
  final String participantName;
  final ProviderKind providerRole;
  final String type; // e.g. "Yoga", "Diet Plan"
  final DateTime requestedAt;
  final DateTime? scheduledAt;
  final AppointmentStatus status;
  final String? notes;
  final String? participantCity;

  Appointment copyWith({
    AppointmentStatus? status,
    DateTime? scheduledAt,
    String? notes,
  }) =>
      Appointment(
        id: id,
        participantId: participantId,
        participantName: participantName,
        providerRole: providerRole,
        type: type,
        requestedAt: requestedAt,
        scheduledAt: scheduledAt ?? this.scheduledAt,
        status: status ?? this.status,
        notes: notes ?? this.notes,
        participantCity: participantCity,
      );
}
