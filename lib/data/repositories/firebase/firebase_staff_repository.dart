// REAL IMPLEMENTATION — enable with cloud_firestore. Not compiled in mock mode.
//
// Reads the participant roster and this provider's appointments. In production,
// scope watchRoster() to the participants actually assigned to this staff
// member (e.g. an `assignedCoachId` field) rather than the whole collection.
//
// ignore_for_file: depend_on_referenced_packages, uri_does_not_exist
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/appointment.dart';
import '../../models/participant.dart';
import '../staff_repository.dart';

class FirebaseStaffRepository implements StaffRepository {
  final FirebaseFirestore _fs = FirebaseFirestore.instance;

  Participant _participant(DocumentSnapshot<Map<String, dynamic>> d) {
    final data = {...(d.data() ?? {}), 'id': d.id};
    if (data['startDate'] is Timestamp) {
      data['startDate'] = (data['startDate'] as Timestamp).toDate().toIso8601String();
    }
    return Participant.fromJson(data);
  }

  Appointment _appointment(DocumentSnapshot<Map<String, dynamic>> d) {
    final m = d.data() ?? {};
    return Appointment(
      id: d.id,
      participantId: m['participantId'] as String? ?? '',
      participantName: m['participantName'] as String? ?? '',
      participantCity: m['participantCity'] as String?,
      providerRole: (m['providerRole'] as String?) == 'doctor'
          ? ProviderKind.doctor
          : ProviderKind.coach,
      type: m['type'] as String? ?? 'Session',
      requestedAt:
          (m['requestedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      scheduledAt: (m['scheduledAt'] as Timestamp?)?.toDate(),
      status: AppointmentStatus.values.byName(
          (m['status'] as String?) ?? AppointmentStatus.requested.name),
      notes: m['notes'] as String?,
    );
  }

  @override
  Stream<List<Participant>> watchRoster() =>
      _fs.collection('participants').snapshots().map(
            (q) => q.docs.map(_participant).toList(),
          );

  @override
  Stream<List<Appointment>> watchAppointments(ProviderKind role) => _fs
      .collection('appointments')
      .where('providerRole', isEqualTo: role.name)
      .orderBy('requestedAt', descending: true)
      .snapshots()
      .map((q) => q.docs.map(_appointment).toList());

  @override
  Future<void> updateAppointmentStatus(String id, AppointmentStatus status) =>
      _fs.collection('appointments').doc(id).set(
        {'status': status.name},
        SetOptions(merge: true),
      );

  @override
  Future<void> addNote(String participantId, String note) => _fs
          .collection('participants')
          .doc(participantId)
          .collection('consultations')
          .add({
        'notes': note,
        'createdAt': FieldValue.serverTimestamp(),
      });
}
