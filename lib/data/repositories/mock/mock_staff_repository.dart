import 'dart:async';

import '../../mock/mock_data.dart';
import '../../models/appointment.dart';
import '../../models/participant.dart';
import '../staff_repository.dart';

class MockStaffRepository implements StaffRepository {
  final StreamController<List<Appointment>> _appts =
      StreamController<List<Appointment>>.broadcast();

  List<Appointment> _for(ProviderKind role) =>
      MockData.appointments.where((a) => a.providerRole == role).toList();

  @override
  Stream<List<Participant>> watchRoster() =>
      Stream<List<Participant>>.value(MockData.roster);

  @override
  Stream<List<Appointment>> watchAppointments(ProviderKind role) {
    scheduleMicrotask(() => _appts.add(_for(role)));
    return _appts.stream.map((_) => _for(role));
  }

  @override
  Future<void> updateAppointmentStatus(String id, AppointmentStatus status) async {
    final i = MockData.appointments.indexWhere((a) => a.id == id);
    if (i >= 0) {
      MockData.appointments[i] = MockData.appointments[i].copyWith(status: status);
      _appts.add(MockData.appointments);
    }
  }

  @override
  Future<void> addNote(String participantId, String note) async {
    // No-op in the mock; Firebase writes participants/{id}/consultations.
  }
}
