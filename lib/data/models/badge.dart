/// A badge the participant has earned. Mirrors
/// `participants/{uid}/badges/{badgeId}`.
class AwardedBadge {
  const AwardedBadge({
    required this.id,
    required this.label,
    required this.awardedAt,
  });

  final String id;
  final String label;
  final DateTime awardedAt;

  Map<String, dynamic> toJson() => {
        'id': id,
        'label': label,
        'awardedAt': awardedAt.toIso8601String(),
      };

  factory AwardedBadge.fromJson(Map<String, dynamic> j) => AwardedBadge(
        id: j['id'] as String,
        label: j['label'] as String? ?? j['id'] as String,
        awardedAt: j['awardedAt'] is String
            ? DateTime.parse(j['awardedAt'] as String)
            : DateTime.now(),
      );
}
