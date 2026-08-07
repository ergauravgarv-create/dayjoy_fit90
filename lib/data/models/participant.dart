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

  /// WHO BMI category: Underweight / Normal / Overweight / Obese.
  String get bmiCategory {
    final double b = bmi;
    if (b <= 0) return 'Unknown';
    if (b < 18.5) return 'Underweight';
    if (b < 25) return 'Normal';
    if (b < 30) return 'Overweight';
    return 'Obese';
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

  // ---- Nutrition targets, derived from the profile ----

  /// Multiplier applied to BMR based on how active the person is.
  double get _activityFactor => switch (physicalActivityLevel) {
        'Sedentary' => 1.2,
        'Light' => 1.375,
        'Active' => 1.725,
        'Very active' => 1.9,
        _ => 1.55, // Moderate / unknown
      };

  /// Resting energy via the Mifflin–St Jeor equation.
  double get _bmr {
    final base = (10 * currentWeightKg) + (6.25 * heightCm) - (5 * age);
    return switch (gender) {
      'Male' => base + 5,
      'Female' => base - 161,
      _ => base - 78, // midpoint for "Other"
    };
  }

  /// Calories to maintain current weight (TDEE).
  int get maintenanceCalories => (_bmr * _activityFactor).round();

  /// Daily calorie target. When aiming to lose weight we apply a ~500 kcal
  /// deficit (about 0.5 kg/week), floored to a safe minimum so it never
  /// recommends under-eating.
  int get dailyCalorieGoal {
    final int floor = gender == 'Male' ? 1500 : 1200;
    if (targetWeightKg < currentWeightKg) {
      final int deficit = maintenanceCalories - 500;
      return deficit < floor ? floor : deficit;
    }
    // Maintaining or gaining.
    return maintenanceCalories;
  }

  /// Daily protein target (grams): ~1.6 g per kg of body weight to protect
  /// muscle during weight loss, kept within a sensible range.
  int get dailyProteinGoal => (1.6 * currentWeightKg).round().clamp(45, 180);

  Participant copyWith({
    double? currentWeightKg,
    double? targetWeightKg,
    double? waistCm,
    String? photoUrl,
    int? streak,
    int? totalPoints,
    String? foodPreference,
    String? physicalActivityLevel,
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
      targetWeightKg: targetWeightKg ?? this.targetWeightKg,
      city: city,
      distributorName: distributorName,
      sponsorId: sponsorId,
      role: role,
      foodPreference: foodPreference ?? this.foodPreference,
      waistCm: waistCm ?? this.waistCm,
      startDate: startDate,
      streak: streak ?? this.streak,
      totalPoints: totalPoints ?? this.totalPoints,
      physicalActivityLevel:
          physicalActivityLevel ?? this.physicalActivityLevel,
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
