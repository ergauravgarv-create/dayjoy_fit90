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
  Stream<List<Appointment>> watchParticipantAppointments(String participantId) {
    List<Appointment> mine() => MockData.appointments
        .where((a) => a.participantId == participantId)
        .toList();
    scheduleMicrotask(() => _appts.add(MockData.appointments));
    return _appts.stream.map((_) => mine());
  }

  @override
  Future<void> updateAppointmentStatus(String id, AppointmentStatus status) async {
    final i = MockData.appointments.indexWhere((a) => a.id == id);
    if (i >= 0) {
      MockData.appointments[i] = MockData.appointments[i].copyWith(
        status: status,
        confirmedAt:
            status == AppointmentStatus.confirmed ? DateTime.now() : null,
      );
      _appts.add(MockData.appointments);
    }
  }

  @override
  Future<void> rescheduleAppointment(String id, DateTime newScheduledAt) async {
    final i = MockData.appointments.indexWhere((a) => a.id == id);
    if (i >= 0) {
      MockData.appointments[i] = MockData.appointments[i].copyWith(
        scheduledAt: newScheduledAt,
        status: AppointmentStatus.requested,
      );
      _appts.add(MockData.appointments);
    }
  }

  @override
  Future<void> addConsultationNote(String id, String note,
      {DateTime? followUpAt}) async {
    final i = MockData.appointments.indexWhere((a) => a.id == id);
    if (i >= 0) {
      MockData.appointments[i] = MockData.appointments[i].copyWith(
        providerNote: note,
        noteAt: DateTime.now(),
        followUpAt: followUpAt,
      );
      _appts.add(MockData.appointments);
    }
  }

  @override
  Future<void> addNote(String participantId, String note) async {
    // No-op in the mock; Firebase writes participants/{id}/consultations.
  }
}
