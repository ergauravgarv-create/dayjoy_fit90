import '../models/participant.dart';

/// Reads & writes the `participants/{uid}` profile.
abstract interface class ParticipantRepository {
  /// Live participant document (null if it doesn't exist yet).
  Stream<Participant?> watch(String uid);

  /// One-shot fetch. Also refreshes the internal cache used by
  /// [currentSnapshot] so screens can read a value synchronously right after.
  Future<Participant?> fetch(String uid);

  /// Best-effort synchronous cache (last fetched/streamed value).
  Participant? currentSnapshot(String uid);

  Future<void> upsert(Participant participant);
  Future<void> updateWeight(String uid, double kg);

  /// Add an FCM device token to the participant so functions can push to them.
  Future<void> registerFcmToken(String uid, String token);

  /// GDPR account deletion.
  Future<void> deleteAccount(String uid);
}
