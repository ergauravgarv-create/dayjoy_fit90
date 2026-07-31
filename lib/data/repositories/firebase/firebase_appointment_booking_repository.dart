// REAL IMPLEMENTATION — enable with cloud_firestore. Not compiled in mock mode.
//
// ignore_for_file: depend_on_referenced_packages, uri_does_not_exist
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/appointment.dart';
import '../appointment_booking_repository.dart';

class FirebaseAppointmentBookingRepository
    implements AppointmentBookingRepository {
  final FirebaseFirestore _fs = FirebaseFirestore.instance;

  @override
  Future<void> book(Appointment a) async {
    await _fs.collection('appointments').add({
      'participantId': a.participantId,
      'participantName': a.participantName,
      'participantCity': a.participantCity,
      // In production, resolve the actual provider uid for the chosen role.
      'providerId': a.providerRole.name,
      'providerRole': a.providerRole.name,
      'providerName': a.providerRole == ProviderKind.coach
          ? 'Ms. Sonali'
          : 'Dr. Prachita',
      'type': a.type,
      'requestedAt': FieldValue.serverTimestamp(),
      'scheduledAt': a.scheduledAt == null
          ? null
          : Timestamp.fromDate(a.scheduledAt!),
      'status': 'requested',
    });
  }
}
