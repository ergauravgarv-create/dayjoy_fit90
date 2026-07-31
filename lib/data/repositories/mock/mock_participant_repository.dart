import '../../mock/mock_data.dart';
import '../../models/participant.dart';
import '../participant_repository.dart';

class MockParticipantRepository implements ParticipantRepository {
  Participant _p = MockData.participant;

  @override
  Stream<Participant?> watch(String uid) => Stream<Participant?>.value(_p);

  @override
  Future<Participant?> fetch(String uid) async => _p;

  @override
  Participant? currentSnapshot(String uid) => _p;

  @override
  Future<void> upsert(Participant participant) async {
    _p = participant;
    MockData.participant = participant;
  }

  @override
  Future<void> updateWeight(String uid, double kg) async {
    _p = _p.copyWith(currentWeightKg: kg);
    MockData.participant = _p;
  }

  @override
  Future<void> registerFcmToken(String uid, String token) async {}

  @override
  Future<void> deleteAccount(String uid) async {}
}
