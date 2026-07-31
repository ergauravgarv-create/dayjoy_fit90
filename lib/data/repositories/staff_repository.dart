import '../models/appointment.dart';
import '../models/participant.dart';

/// Coach & doctor data access. In Firebase mode this reads `participants`
/// (scoped by rules) and `appointments` where `providerId == me`.
abstract interface class StaffRepository {
  /// Participants visible to this staff member.
  Stream<List<Participant>> watchRoster();

  /// Appointments addressed to this provider kind (coach/doctor).
  Stream<List<Appointment>> watchAppointments(ProviderKind role);

  Future<void> updateAppointmentStatus(String id, AppointmentStatus status);

  /// Add a private note / plan for a participant (coach plan or doctor note).
  Future<void> addNote(String participantId, String note);
}
