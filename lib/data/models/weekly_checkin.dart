/// A weekly progress check-in. Mirrors
/// `participants/{uid}/weeklyCheckins/{week-NN}`.
class WeeklyCheckIn {
  const WeeklyCheckIn({
    required this.weekNumber,
    required this.weightKg,
    required this.waistCm,
    this.frontPhotoUrl,
    this.sidePhotoUrl,
    this.energy = 3,
    this.sleep = 3,
    this.digestion = 3,
    this.mood = 3,
    this.challenges,
    this.notes,
    required this.createdAt,
  });

  final int weekNumber;
  final double weightKg;
  final double waistCm;
  final String? frontPhotoUrl;
  final String? sidePhotoUrl;

  /// Wellness ratings, 1 (low) .. 5 (great).
  final int energy;
  final int sleep;
  final int digestion;
  final int mood;

  final String? challenges;
  final String? notes;
  final DateTime createdAt;

  String get weekId => 'week-${weekNumber.toString().padLeft(2, '0')}';

  Map<String, dynamic> toJson() => {
        'weekNumber': weekNumber,
        'weightKg': weightKg,
        'waistCm': waistCm,
        'frontPhoto': frontPhotoUrl,
        'sidePhoto': sidePhotoUrl,
        'energyLevel': energy,
        'sleepQuality': sleep,
        'digestion': digestion,
        'mood': mood,
        'challenges': challenges,
        'notes': notes,
        'createdAt': createdAt.toIso8601String(),
      };

  factory WeeklyCheckIn.fromJson(Map<String, dynamic> j) => WeeklyCheckIn(
        weekNumber: (j['weekNumber'] as num?)?.toInt() ?? 1,
        weightKg: (j['weightKg'] as num).toDouble(),
        waistCm: (j['waistCm'] as num).toDouble(),
        frontPhotoUrl: j['frontPhoto'] as String?,
        sidePhotoUrl: j['sidePhoto'] as String?,
        energy: (j['energyLevel'] as num?)?.toInt() ?? 3,
        sleep: (j['sleepQuality'] as num?)?.toInt() ?? 3,
        digestion: (j['digestion'] as num?)?.toInt() ?? 3,
        mood: (j['mood'] as num?)?.toInt() ?? 3,
        challenges: j['challenges'] as String?,
        notes: j['notes'] as String?,
        createdAt: j['createdAt'] == null
            ? DateTime.now()
            : DateTime.parse(j['createdAt'] as String),
      );
}
