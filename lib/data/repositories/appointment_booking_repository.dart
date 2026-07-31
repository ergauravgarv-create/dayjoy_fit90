import '../models/appointment.dart';

/// Participant-facing booking: create a new appointment request with a
/// coach or doctor.
abstract interface class AppointmentBookingRepository {
  Future<void> book(Appointment appointment);
}
