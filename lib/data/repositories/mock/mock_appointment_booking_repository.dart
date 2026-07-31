import '../../mock/mock_data.dart';
import '../../models/appointment.dart';
import '../appointment_booking_repository.dart';

class MockAppointmentBookingRepository implements AppointmentBookingRepository {
  @override
  Future<void> book(Appointment appointment) async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    // Insert at the top so it shows first in the coach/doctor dashboards too.
    MockData.appointments.insert(0, appointment);
  }
}
