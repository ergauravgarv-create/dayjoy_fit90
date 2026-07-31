/// Kinds of consent tracked explicitly and separately. Health data and
/// location are NEVER bundled with generic app consent — each is its own opt-in
/// per the privacy requirements.
enum ConsentType { healthData, camera, location, dataProcessing }

class ConsentRecord {
  const ConsentRecord({
    required this.type,
    required this.granted,
    required this.updatedAt,
    this.policyVersion = '1.0',
  });

  final ConsentType type;
  final bool granted;
  final DateTime updatedAt;
  final String policyVersion;

  Map<String, dynamic> toJson() => {
        'type': type.name,
        'granted': granted,
        'updatedAt': updatedAt.toIso8601String(),
        'policyVersion': policyVersion,
      };
}

/// Records and exposes the user's explicit consents. In production, persist
/// these to Firestore (`participants/{id}/consents`) and require a fresh grant
/// when [policyVersion] changes.
abstract interface class ConsentManagementService {
  Future<bool> hasConsent(ConsentType type);
  Future<void> setConsent(ConsentType type, bool granted);
  Future<List<ConsentRecord>> all();
}

class InMemoryConsentService implements ConsentManagementService {
  final Map<ConsentType, ConsentRecord> _records = {};

  @override
  Future<bool> hasConsent(ConsentType type) async =>
      _records[type]?.granted ?? false;

  @override
  Future<void> setConsent(ConsentType type, bool granted) async {
    _records[type] = ConsentRecord(
      type: type,
      granted: granted,
      updatedAt: DateTime.now(),
    );
  }

  @override
  Future<List<ConsentRecord>> all() async => _records.values.toList();
}
