import '../models/admin_models.dart';
import '../models/appointment.dart';
import '../models/health_enums.dart';
import '../models/leaderboard_entry.dart';
import '../models/participant.dart';
import '../models/weekly_report.dart';

/// Seed data used by the mock repositories so the app is fully explorable
/// before any backend is wired up.
abstract final class MockData {
  static Participant participant = Participant(
    id: 'demo-user',
    name: 'Aarav Sharma',
    mobile: '+91 98765 43210',
    email: 'aarav@example.com',
    age: 32,
    gender: 'Male',
    heightCm: 174,
    startWeightKg: 88.0,
    currentWeightKg: 81.4,
    targetWeightKg: 72.0,
    city: 'Pune',
    distributorName: 'Wellness Hub',
    sponsorId: 'DJ-10432',
    waistCm: 92,
    startDate: DateTime.now().subtract(const Duration(days: 23)),
    streak: 12,
    totalPoints: 1840,
  );

  static int currentStreak = 12;
  static int totalPoints = 1840;

  /// 12 weeks of weight readings (kg), oldest first.
  static List<double> weightSeries = const [
    88.0, 87.1, 86.0, 85.2, 84.3, 83.5, 82.6, 81.9, 81.4,
  ];

  static List<LeaderboardEntry> leaderboard = const [
    LeaderboardEntry(
      rank: 1,
      name: 'Priya Menon',
      city: 'Kochi',
      points: 2280,
      streak: 24,
      weightLostKg: 9.2,
    ),
    LeaderboardEntry(
      rank: 2,
      name: 'Rohan Gupta',
      city: 'Delhi',
      points: 2150,
      streak: 22,
      weightLostKg: 8.1,
    ),
    LeaderboardEntry(
      rank: 3,
      name: 'Aarav Sharma',
      city: 'Pune',
      points: 1840,
      streak: 12,
      weightLostKg: 6.6,
      isCurrentUser: true,
    ),
    LeaderboardEntry(
      rank: 4,
      name: 'Sneha Rao',
      city: 'Bengaluru',
      points: 1790,
      streak: 15,
      weightLostKg: 7.4,
    ),
    LeaderboardEntry(
      rank: 5,
      name: 'Vikram Iyer',
      city: 'Chennai',
      points: 1620,
      streak: 9,
      weightLostKg: 5.9,
    ),
    LeaderboardEntry(
      rank: 6,
      name: 'Neha Kulkarni',
      city: 'Pune',
      points: 1510,
      streak: 11,
      weightLostKg: 5.2,
    ),
    LeaderboardEntry(
      rank: 7,
      name: 'Kabir Joshi',
      city: 'Pune',
      points: 1420,
      streak: 8,
      weightLostKg: 4.8,
    ),
  ];

  // ------------------------------------------------------------------------
  // Staff & admin seed data
  // ------------------------------------------------------------------------

  /// The roster of participants staff/admin see. Values chosen to exercise the
  /// dashboards (varied activity, cities, distributors).
  static List<Participant> roster = [
    participant,
    Participant(
      id: 'p2',
      name: 'Priya Menon',
      mobile: '+91 90000 00002',
      age: 29,
      gender: 'Female',
      heightCm: 162,
      startWeightKg: 74,
      currentWeightKg: 64.8,
      targetWeightKg: 60,
      city: 'Kochi',
      distributorName: 'Coastal Wellness',
      streak: 24,
      totalPoints: 2280,
      startDate: DateTime.now().subtract(const Duration(days: 40)),
    ),
    Participant(
      id: 'p3',
      name: 'Rohan Gupta',
      mobile: '+91 90000 00003',
      age: 35,
      gender: 'Male',
      heightCm: 178,
      startWeightKg: 96,
      currentWeightKg: 87.9,
      targetWeightKg: 80,
      city: 'Delhi',
      distributorName: 'Capital Fit',
      streak: 22,
      totalPoints: 2150,
      startDate: DateTime.now().subtract(const Duration(days: 38)),
    ),
    Participant(
      id: 'p4',
      name: 'Sneha Rao',
      mobile: '+91 90000 00004',
      age: 41,
      gender: 'Female',
      heightCm: 158,
      startWeightKg: 71,
      currentWeightKg: 63.6,
      targetWeightKg: 58,
      city: 'Bengaluru',
      distributorName: 'Wellness Hub',
      streak: 15,
      totalPoints: 1790,
      startDate: DateTime.now().subtract(const Duration(days: 30)),
    ),
    Participant(
      id: 'p5',
      name: 'Vikram Iyer',
      mobile: '+91 90000 00005',
      age: 47,
      gender: 'Male',
      heightCm: 170,
      startWeightKg: 88,
      currentWeightKg: 82.1,
      targetWeightKg: 74,
      city: 'Chennai',
      distributorName: 'Coastal Wellness',
      streak: 9,
      totalPoints: 1620,
      startDate: DateTime.now().subtract(const Duration(days: 20)),
    ),
    Participant(
      id: 'p6',
      name: 'Neha Kulkarni',
      mobile: '+91 90000 00006',
      age: 33,
      gender: 'Female',
      heightCm: 165,
      startWeightKg: 78,
      currentWeightKg: 72.8,
      targetWeightKg: 66,
      city: 'Pune',
      distributorName: 'Wellness Hub',
      streak: 11,
      totalPoints: 1510,
      startDate: DateTime.now().subtract(const Duration(days: 18)),
    ),
  ];

  static List<Appointment> appointments = [
    Appointment(
      id: 'a1',
      participantId: 'p3',
      participantName: 'Rohan Gupta',
      participantCity: 'Delhi',
      providerRole: ProviderKind.coach,
      type: 'Gym Program',
      requestedAt: DateTime.now().subtract(const Duration(hours: 3)),
      status: AppointmentStatus.requested,
    ),
    Appointment(
      id: 'a2',
      participantId: 'p4',
      participantName: 'Sneha Rao',
      participantCity: 'Bengaluru',
      providerRole: ProviderKind.coach,
      type: 'Yoga',
      requestedAt: DateTime.now().subtract(const Duration(hours: 6)),
      scheduledAt: DateTime.now().add(const Duration(hours: 4)),
      status: AppointmentStatus.confirmed,
    ),
    Appointment(
      id: 'a3',
      participantId: 'p2',
      participantName: 'Priya Menon',
      participantCity: 'Kochi',
      providerRole: ProviderKind.doctor,
      type: 'Diet Plan',
      requestedAt: DateTime.now().subtract(const Duration(hours: 2)),
      status: AppointmentStatus.requested,
    ),
    Appointment(
      id: 'a4',
      participantId: 'p5',
      participantName: 'Vikram Iyer',
      participantCity: 'Chennai',
      providerRole: ProviderKind.doctor,
      type: 'Sleep Problems',
      requestedAt: DateTime.now().subtract(const Duration(days: 1)),
      scheduledAt: DateTime.now().add(const Duration(hours: 2)),
      status: AppointmentStatus.confirmed,
    ),
  ];

  static List<SubmissionReview> verificationQueue = [
    SubmissionReview(
      id: 's1',
      participantName: 'Vikram Iyer',
      taskTitle: 'Daily Steps',
      method: VerificationMethod.screenshot,
      submittedAt: DateTime.now().subtract(const Duration(minutes: 40)),
      isLate: true,
    ),
    SubmissionReview(
      id: 's2',
      participantName: 'Rohan Gupta',
      taskTitle: 'Morning Yoga',
      method: VerificationMethod.manualEntry,
      submittedAt: DateTime.now().subtract(const Duration(minutes: 90)),
      flaggedDuplicate: true,
    ),
    SubmissionReview(
      id: 's3',
      participantName: 'Neha Kulkarni',
      taskTitle: 'Daily Steps',
      method: VerificationMethod.screenshot,
      submittedAt: DateTime.now().subtract(const Duration(hours: 3)),
    ),
  ];

  /// Generated weekly reports (as the Cloud Function would produce them),
  /// oldest → newest. Weights track the participant's start (88) → current.
  static List<WeeklyReport> weeklyReports = const [
    WeeklyReport(
      weekNumber: 1,
      startDate: '2026-07-08',
      endDate: '2026-07-14',
      daysCompleted: 6,
      daysInWeek: 7,
      completionRate: 0.86,
      totalSteps: 58200,
      activeCalories: 2760,
      workoutMinutes: 168,
      startWeightKg: 88.0,
      endWeightKg: 86.0,
      weightChangeKg: -2.0,
      bmi: 28.4,
      bmiChange: -0.7,
      pointsEarned: 600,
    ),
    WeeklyReport(
      weekNumber: 2,
      startDate: '2026-07-15',
      endDate: '2026-07-21',
      daysCompleted: 7,
      daysInWeek: 7,
      completionRate: 1.0,
      totalSteps: 63400,
      activeCalories: 3080,
      workoutMinutes: 192,
      startWeightKg: 86.0,
      endWeightKg: 84.3,
      weightChangeKg: -1.7,
      bmi: 27.8,
      bmiChange: -0.6,
      pointsEarned: 700,
    ),
    WeeklyReport(
      weekNumber: 3,
      startDate: '2026-07-22',
      endDate: '2026-07-28',
      daysCompleted: 6,
      daysInWeek: 7,
      completionRate: 0.86,
      totalSteps: 61240,
      activeCalories: 3180,
      workoutMinutes: 186,
      startWeightKg: 84.3,
      endWeightKg: 81.4,
      weightChangeKg: -2.9,
      bmi: 26.9,
      bmiChange: -0.9,
      pointsEarned: 600,
    ),
  ];

  static AdminStats adminStats = const AdminStats(
    totalParticipants: 248,
    activeToday: 191,
    submissionsToday: 812,
    avgCompletion: 0.78,
    pendingVerifications: 3,
    totalWeightLostKg: 1163.5,
    appointmentsToday: 14,
    completionSeries: [0.62, 0.68, 0.71, 0.66, 0.74, 0.8, 0.78],
  );
}
