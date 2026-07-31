/// A single access-audit event for sensitive health data.
class HealthAuditEvent {
  const HealthAuditEvent({
    required this.at,
    required this.actorId,
    required this.action,
    required this.participantId,
    this.detail,
  });

  final DateTime at;
  final String actorId; // who accessed (participant self, coach, doctor, admin)
  final String action; // e.g. "read.steps", "sync", "revoke", "delete"
  final String participantId; // whose data
  final String? detail;

  Map<String, dynamic> toJson() => {
        'at': at.toIso8601String(),
        'actorId': actorId,
        'action': action,
        'participantId': participantId,
        'detail': detail,
      };
}

/// Append-only audit log for every access to participant health information.
/// Required for the privacy/role-based-access guarantees: only authorised
/// staff may read health data, and every read is logged.
abstract interface class HealthAuditService {
  Future<void> log(HealthAuditEvent event);
  Future<List<HealthAuditEvent>> forParticipant(String participantId);
}

class InMemoryHealthAuditService implements HealthAuditService {
  final List<HealthAuditEvent> _events = [];

  @override
  Future<void> log(HealthAuditEvent event) async => _events.add(event);

  @override
  Future<List<HealthAuditEvent>> forParticipant(String participantId) async =>
      _events.where((e) => e.participantId == participantId).toList();
}
