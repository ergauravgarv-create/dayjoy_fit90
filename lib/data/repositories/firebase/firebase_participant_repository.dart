// REAL IMPLEMENTATION — enable with cloud_firestore. Not compiled in mock mode.
//
// ignore_for_file: depend_on_referenced_packages, uri_does_not_exist
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/participant.dart';
import '../participant_repository.dart';

class FirebaseParticipantRepository implements ParticipantRepository {
  final CollectionReference<Map<String, dynamic>> _col =
      FirebaseFirestore.instance.collection('participants');
  final Map<String, Participant> _cache = {};

  Participant _fromDoc(DocumentSnapshot<Map<String, dynamic>> d) {
    final data = {...(d.data() ?? {}), 'id': d.id};
    // Firestore Timestamps → ISO strings the model understands.
    if (data['startDate'] is Timestamp) {
      data['startDate'] = (data['startDate'] as Timestamp).toDate().toIso8601String();
    }
    return Participant.fromJson(data);
  }

  @override
  Stream<Participant?> watch(String uid) => _col.doc(uid).snapshots().map((d) {
        if (!d.exists) return null;
        final p = _fromDoc(d);
        _cache[uid] = p;
        return p;
      });

  @override
  Future<Participant?> fetch(String uid) async {
    final d = await _col.doc(uid).get();
    if (!d.exists) return null;
    final p = _fromDoc(d);
    _cache[uid] = p;
    return p;
  }

  @override
  Participant? currentSnapshot(String uid) => _cache[uid];

  @override
  Future<void> upsert(Participant participant) =>
      _col.doc(participant.id).set(participant.toJson(), SetOptions(merge: true));

  @override
  Future<void> updateWeight(String uid, double kg) =>
      _col.doc(uid).set({'currentWeightKg': kg}, SetOptions(merge: true));

  @override
  Future<void> registerFcmToken(String uid, String token) => _col.doc(uid).set(
        {'fcmTokens': FieldValue.arrayUnion([token])},
        SetOptions(merge: true),
      );

  @override
  Future<void> deleteAccount(String uid) => _col.doc(uid).delete();
}
