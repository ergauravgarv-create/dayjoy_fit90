import '../../core/constants/app_constants.dart';

/// Participant profile. Mirrors the Firestore `participants/{uid}` document.
/// Plain immutable model with JSON mappers (no codegen) so the skeleton runs
/// without build_runner.
class Participant {
  const Participant({
    required this.id,
    required this.name,
    required this.mobile,
    this.email,
    this.photoUrl,
    required this.age,
    required this.gender,
    required this.heightCm,
    required this.startWeightKg,
    required this.currentWeightKg,
    required this.targetWeightKg,
    required this.city,
    this.distributorName,
    this.sponsorId,
    this.role = UserRole.participant,
    this.foodPreference = 'Vegetarian',
    this.waistCm,
    this.startDate,
    this.streak = 0,
    this.totalPoints = 0,
    this.physicalActivityLevel,
    this.healthConditions,
  });

  final String id;
  final String name;
  final String mobile;
  final String? email;
  final String? photoUrl;
  final int age;
  final String gender;
  final double heightCm;
  final double startWeightKg;
  final double currentWeightKg;
  final double targetWeightKg;
  final String city;
  final String? distributorName;
  final String? sponsorId;
  final UserRole role;
  final String foodPreference;
  final double? waistCm;
  final DateTime? startDate;
  final int streak;
  final int totalPoints;
  final String? physicalActivityLevel;

  /// Non-sensitive summary only. Detailed medical history belongs in the
  /// `participants/{uid}/medical` subcollection (doctor + admin access).
  final String? healthConditions;

  /// Body Mass Index from current weight & height.
  double get bmi {
    final double m = heightCm / 100.0;
    if (m <= 0) return 0;
    return currentWeightKg / (m * m);
  }

  double get weightLostKg =>
      (startWeightKg - currentWeightKg).clamp(0.0, 999.0);

  double get totalToLoseKg =>
      (startWeightKg - targetWeightKg).clamp(0.0001, 999.0);

  /// 0..1 progress toward target weight.
  double get goalProgress => (weightLostKg / totalToLoseKg).clamp(0.0, 1.0);

  int get currentDay {
    if (startDate == null) return 1;
    final int d = DateTime.now().difference(startDate!).inDays + 1;
    return d.clamp(1, AppConstants.challengeDurationDays);
  }

  int get remainingDays =>
      (AppConstants.challengeDurationDays - currentDay).clamp(0, 90);

  Participant copyWith({
    double? currentWeightKg,
    double? waistCm,
    String? photoUrl,
    int? streak,
    int? totalPoints,
  }) {
    return Participant(
      id: id,
      name: name,
      mobile: mobile,
      email: email,
      photoUrl: photoUrl ?? this.photoUrl,
      age: age,
      gender: gender,
      heightCm: heightCm,
      startWeightKg: startWeightKg,
      currentWeightKg: currentWeightKg ?? this.currentWeightKg,
      targetWeightKg: targetWeightKg,
      city: city,
      distributorName: distributorName,
      sponsorId: sponsorId,
      role: role,
      foodPreference: foodPreference,
      waistCm: waistCm ?? this.waistCm,
      startDate: startDate,
      streak: streak ?? this.streak,
      totalPoints: totalPoints ?? this.totalPoints,
      physicalActivityLevel: physicalActivityLevel,
      healthConditions: healthConditions,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'mobile': mobile,
        'email': email,
        'photoUrl': photoUrl,
        'age': age,
        'gender': gender,
        'heightCm': heightCm,
        'startWeightKg': startWeightKg,
        'currentWeightKg': currentWeightKg,
        'targetWeightKg': targetWeightKg,
        'city': city,
        'distributorName': distributorName,
        'sponsorId': sponsorId,
        'role': role.name,
        'foodPreference': foodPreference,
        'waistCm': waistCm,
        'startDate': startDate?.toIso8601String(),
        'streak': streak,
        'totalPoints': totalPoints,
        'physicalActivityLevel': physicalActivityLevel,
        'healthConditions': healthConditions,
      };

  factory Participant.fromJson(Map<String, dynamic> json) => Participant(
        id: json['id'] as String,
        name: json['name'] as String,
        mobile: json['mobile'] as String,
        email: json['email'] as String?,
        photoUrl: json['photoUrl'] as String?,
        age: (json['age'] as num).toInt(),
        gender: json['gender'] as String,
        heightCm: (json['heightCm'] as num).toDouble(),
        startWeightKg: (json['startWeightKg'] as num).toDouble(),
        currentWeightKg: (json['currentWeightKg'] as num).toDouble(),
        targetWeightKg: (json['targetWeightKg'] as num).toDouble(),
        city: json['city'] as String,
        distributorName: json['distributorName'] as String?,
        sponsorId: json['sponsorId'] as String?,
        role: UserRole.values.byName(
            (json['role'] as String?) ?? UserRole.participant.name),
        foodPreference: (json['foodPreference'] as String?) ?? 'Vegetarian',
        waistCm: (json['waistCm'] as num?)?.toDouble(),
        startDate: json['startDate'] == null
            ? null
            : DateTime.parse(json['startDate'] as String),
        streak: (json['streak'] as num?)?.toInt() ?? 0,
        totalPoints: (json['totalPoints'] as num?)?.toInt() ?? 0,
        physicalActivityLevel: json['physicalActivityLevel'] as String?,
        healthConditions: json['healthConditions'] as String?,
      );
}
