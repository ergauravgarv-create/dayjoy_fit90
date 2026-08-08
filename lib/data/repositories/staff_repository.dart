import '../models/appointment.dart';
import '../models/participant.dart';

/// Coach & doctor data access. In Firebase mode this reads `participants`
/// (scoped by rules) and `appointments` where `providerId == me`.
abstract interface class StaffRepository {
  /// Participants visible to this staff member.
  Stream<List<Participant>> watchRoster();

  /// Appointments addressed to this provider kind (coach/doctor).
  Stream<List<Appointment>> watchAppointments(ProviderKind role);

  /// A single participant's own appointments (both doctor and trainer). Used by
  /// the participant app to show their consultations and confirmed-call alerts.
  Stream<List<Appointment>> watchParticipantAppointments(String participantId);

  Future<void> updateAppointmentStatus(String id, AppointmentStatus status);

  /// Move an appointment to a new time. Resets it to a pending request so the
  /// provider re-confirms the new slot.
  Future<void> rescheduleAppointment(String id, DateTime newScheduledAt);

  /// Save the provider's post-call note / prescription on an appointment, with
  /// an optional recommended follow-up date. The participant sees both under
  /// that booking.
  Future<void> addConsultationNote(String id, String note,
      {DateTime? followUpAt});

  /// Add a private note / plan for a participant (coach plan or doctor note).
  Future<void> addNote(String participantId, String note);
}
