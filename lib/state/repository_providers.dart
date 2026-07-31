import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/env/app_config.dart';
import '../data/repositories/admin_repository.dart';
import '../data/repositories/auth_repository.dart';
import '../data/repositories/badge_repository.dart';
import '../data/repositories/checklist_repository.dart';
import '../data/repositories/leaderboard_repository.dart';
import '../data/repositories/notification_repository.dart';
import '../data/repositories/participant_repository.dart';
import '../data/repositories/staff_repository.dart';
import '../data/repositories/weekly_checkin_repository.dart';
import '../data/repositories/weekly_report_repository.dart';
import '../data/repositories/mock/mock_admin_repository.dart';
import '../data/repositories/mock/mock_auth_repository.dart';
import '../data/repositories/mock/mock_badge_repository.dart';
import '../data/repositories/mock/mock_checklist_repository.dart';
import '../data/repositories/mock/mock_leaderboard_repository.dart';
import '../data/repositories/mock/mock_notification_repository.dart';
import '../data/repositories/mock/mock_participant_repository.dart';
import '../data/repositories/mock/mock_staff_repository.dart';
import '../data/repositories/mock/mock_weekly_checkin_repository.dart';
import '../data/repositories/mock/mock_weekly_report_repository.dart';
import '../services/messaging/fcm_service.dart';

// ---------------------------------------------------------------------------
// GOING LIVE: enable the firebase_* deps, set AppConfig.backend =
// BackendMode.firebase, then uncomment these imports + the `firebase` branches
// below. The rest of the app is unchanged — it only talks to the interfaces.
// ---------------------------------------------------------------------------
// import '../data/repositories/firebase/firebase_auth_repository.dart';
// import '../data/repositories/firebase/firebase_checklist_repository.dart';
// import '../data/repositories/firebase/firebase_leaderboard_repository.dart';
// import '../data/repositories/firebase/firebase_participant_repository.dart';
// import '../data/repositories/firebase/firebase_staff_repository.dart';
// import '../data/repositories/firebase/firebase_admin_repository.dart';
// import '../data/repositories/firebase/firebase_weekly_checkin_repository.dart';
// import '../data/repositories/firebase/firebase_weekly_report_repository.dart';
// import '../data/repositories/firebase/firebase_badge_repository.dart';
// import '../data/repositories/firebase/firebase_notification_repository.dart';
// import '../services/messaging/firebase_fcm_service.dart';

/// The single composition root. Every repository is selected here based on
/// [AppConfig.backend]; nothing else in the app knows which backend is active.

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  if (AppConfig.isFirebase) {
    // return FirebaseAuthRepository();
  }
  return MockAuthRepository();
});

final participantRepositoryProvider = Provider<ParticipantRepository>((ref) {
  if (AppConfig.isFirebase) {
    // return FirebaseParticipantRepository();
  }
  return MockParticipantRepository();
});

final checklistRepositoryProvider = Provider<ChecklistRepository>((ref) {
  if (AppConfig.isFirebase) {
    // return FirebaseChecklistRepository();
  }
  return MockChecklistRepository();
});

final leaderboardRepositoryProvider = Provider<LeaderboardRepository>((ref) {
  if (AppConfig.isFirebase) {
    // return FirebaseLeaderboardRepository(currentUid: ref.watch(authUidProvider));
  }
  return MockLeaderboardRepository();
});

final fcmServiceProvider = Provider<FcmService>((ref) {
  if (AppConfig.isFirebase) {
    // return FirebaseFcmService();
  }
  return MockFcmService();
});

final staffRepositoryProvider = Provider<StaffRepository>((ref) {
  if (AppConfig.isFirebase) {
    // return FirebaseStaffRepository();
  }
  return MockStaffRepository();
});

final adminRepositoryProvider = Provider<AdminRepository>((ref) {
  if (AppConfig.isFirebase) {
    // return FirebaseAdminRepository();
  }
  return MockAdminRepository();
});

final weeklyCheckinRepositoryProvider = Provider<WeeklyCheckInRepository>((ref) {
  if (AppConfig.isFirebase) {
    // return FirebaseWeeklyCheckInRepository();
  }
  return MockWeeklyCheckInRepository();
});

final badgeRepositoryProvider = Provider<BadgeRepository>((ref) {
  if (AppConfig.isFirebase) {
    // return FirebaseBadgeRepository();
  }
  return MockBadgeRepository();
});

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  if (AppConfig.isFirebase) {
    // return FirebaseNotificationRepository();
  }
  return MockNotificationRepository();
});

final weeklyReportRepositoryProvider = Provider<WeeklyReportRepository>((ref) {
  if (AppConfig.isFirebase) {
    // return FirebaseWeeklyReportRepository();
  }
  return MockWeeklyReportRepository();
});
