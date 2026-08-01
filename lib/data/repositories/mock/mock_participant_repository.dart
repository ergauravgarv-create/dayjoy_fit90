import '../../mock/mock_data.dart';
import '../../models/participant.dart';
import '../participant_repository.dart';

class MockParticipantRepository implements ParticipantRepository {
  // Profiles keyed by user id. Seeded with the demo participant; a new user id
  // (from a new phone number) has no entry, so the app asks them to register.
  final Map<String, Participant> _profiles = {
    MockData.participant.id: MockData.participant,
  };

  @override
  Stream<Participant?> watch(String uid) =>
      Stream<Participant?>.value(_profiles[uid]);

  @override
  Future<Participant?> fetch(String uid) async => _profiles[uid];

  @override
  Participant? currentSnapshot(String uid) => _profiles[uid];

  @override
  Future<void> upsert(Participant participant) async {
    _profiles[participant.id] = participant;
    if (participant.id == MockData.participant.id) {
      MockData.participant = participant;
    }
  }

  @override
  Future<void> updateWeight(String uid, double kg) async {
    final current = _profiles[uid];
    if (current == null) return;
    final updated = current.copyWith(currentWeightKg: kg);
    _profiles[uid] = updated;
    if (uid == MockData.participant.id) MockData.participant = updated;
  }

  @override
  Future<void> registerFcmToken(String uid, String token) async {}

  @override
  Future<void> deleteAccount(String uid) async {
    _profiles.remove(uid);
  }
}
