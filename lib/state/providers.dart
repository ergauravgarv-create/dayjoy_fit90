import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants/app_constants.dart';
import '../core/env/app_config.dart';
import '../data/mock/mock_data.dart';
import '../data/models/daily_task.dart';
import '../data/models/leaderboard_entry.dart';
import '../data/models/participant.dart';
import '../data/repositories/auth_repository.dart';
import 'repository_providers.dart';
import 'water_provider.dart';

/// -------------------------------------------------------------------------
/// App state. The provider *surface* here is identical for mock and Firebase
/// backends — only the repositories behind them change (see
/// repository_providers.dart). Screens never know which backend is live.
/// -------------------------------------------------------------------------

// ===== Auth ================================================================

enum AuthStatus { idle, sendingCode, codeSent, verifying, authenticated, error }

class AuthState {
  const AuthState({
    this.status = AuthStatus.idle,
    this.uid,
    this.phone,
    this.verificationId,
    this.error,
    this.role = UserRole.participant,
    this.needsRegistration = false,
  });

  final AuthStatus status;
  final String? uid;
  final String? phone;
  final String? verificationId;
  final String? error;
  final UserRole role;

  /// True when a participant has authenticated but has no profile document yet.
  final bool needsRegistration;

  AuthState copyWith({
    AuthStatus? status,
    String? uid,
    String? phone,
    String? verificationId,
    String? error,
    UserRole? role,
    bool? needsRegistration,
  }) =>
      AuthState(
        status: status ?? this.status,
        uid: uid ?? this.uid,
        phone: phone ?? this.phone,
        verificationId: verificationId ?? this.verificationId,
        error: error,
        role: role ?? this.role,
        needsRegistration: needsRegistration ?? this.needsRegistration,
      );
}

/// Demo-only: which role the mock login signs in as. Ignored in Firebase mode
/// (role comes from the auth token claim).
final demoRoleProvider =
    NotifierProvider<DemoRoleNotifier, UserRole>(DemoRoleNotifier.new);

class DemoRoleNotifier extends Notifier<UserRole> {
  @override
  UserRole build() => UserRole.participant;
  void set(UserRole role) => state = role;
}

/// The active user's role (drives dashboard routing).
final currentRoleProvider =
    Provider<UserRole>((ref) => ref.watch(authControllerProvider).role);

final authControllerProvider =
    NotifierProvider<AuthController, AuthState>(AuthController.new);

class AuthController extends Notifier<AuthState> {
  @override
  AuthState build() => const AuthState();

  AuthRepository get _auth => ref.read(authRepositoryProvider);

  Future<void> sendOtp(String phoneE164) async {
    state = state.copyWith(status: AuthStatus.sendingCode, phone: phoneE164);
    await _auth.sendOtp(
      phoneE164,
      onCodeSent: (vid) => state =
          state.copyWith(status: AuthStatus.codeSent, verificationId: vid),
      onError: (e) => state = state.copyWith(status: AuthStatus.error, error: e),
    );
  }

  Future<bool> verifyOtp(String smsCode) async {
    final vid = state.verificationId;
    if (vid == null) return false;
    state = state.copyWith(status: AuthStatus.verifying);
    try {
      final user = await _auth.verifyOtp(verificationId: vid, smsCode: smsCode);
      await _postSignIn(user);
      return true;
    } catch (e) {
      state = state.copyWith(status: AuthStatus.error, error: e.toString());
      return false;
    }
  }

  Future<void> _postSignIn(AuthUser user) async {
    // In mock mode the role is chosen via the demo picker; in Firebase mode it
    // comes from the auth token claim on the user.
    final UserRole role =
        AppConfig.isMock ? ref.read(demoRoleProvider) : user.role;

    // Only participants have a participant profile / FCM registration here.
    bool needsRegistration = false;
    if (role == UserRole.participant) {
      final profile =
          await ref.read(participantRepositoryProvider).fetch(user.uid);
      needsRegistration = profile == null;
      final fcm = ref.read(fcmServiceProvider);
      await fcm.requestPermission();
      final token = await fcm.getToken();
      if (token != null) {
        await ref
            .read(participantRepositoryProvider)
            .registerFcmToken(user.uid, token);
      }
    }

    state = state.copyWith(
      status: AuthStatus.authenticated,
      uid: user.uid,
      phone: user.phone,
      role: role,
      needsRegistration: needsRegistration,
    );
  }

  /// Called after the registration form creates the profile.
  void markRegistered() =>
      state = state.copyWith(needsRegistration: false);

  Future<void> signOut() async {
    await _auth.signOut();
    state = const AuthState();
  }
}

/// The signed-in uid (null when signed out).
final authUidProvider = Provider<String?>((ref) {
  final s = ref.watch(authControllerProvider);
  return s.status == AuthStatus.authenticated ? s.uid : null;
});

// ===== Participant =========================================================

final participantProvider =
    NotifierProvider<ParticipantNotifier, Participant?>(ParticipantNotifier.new);

class ParticipantNotifier extends Notifier<Participant?> {
  @override
  Participant? build() {
    final uid = ref.watch(authUidProvider);
    final repo = ref.watch(participantRepositoryProvider);
    if (uid == null) return null;
    final sub = repo.watch(uid).listen((p) {
      if (p != null) state = p;
    });
    ref.onDispose(sub.cancel);
    return repo.currentSnapshot(uid);
  }

  Future<void> updateWeight(double kg) async {
    final uid = ref.read(authUidProvider);
    if (uid == null) return;
    await ref.read(participantRepositoryProvider).updateWeight(uid, kg);
    state = state?.copyWith(currentWeightKg: kg);
  }
}

// ===== Daily checklist =====================================================

final checklistProvider =
    NotifierProvider<ChecklistNotifier, DailyChecklist>(ChecklistNotifier.new);

class ChecklistNotifier extends Notifier<DailyChecklist> {
  @override
  DailyChecklist build() {
    final uid = ref.watch(authUidProvider);
    final repo = ref.watch(checklistRepositoryProvider);
    final day = ref.watch(participantProvider)?.currentDay ?? 1;
    if (uid == null) return DailyChecklist.freshFor(day, DateTime.now());
    final sub = repo.watchToday(uid, day).listen((c) => state = c);
    ref.onDispose(sub.cancel);
    return repo.currentSnapshot(uid, day) ??
        DailyChecklist.freshFor(day, DateTime.now());
  }

  /// Optimistically toggles the task locally and persists it. Returns true when
  /// this toggle completed the final task of the day (drives the celebration).
  bool setTask(
    DailyTaskType type,
    bool completed, {
    String? proofUrl,
    int? verifiedSteps,
    String? verificationMethod,
  }) {
    final wasComplete = state.allComplete;
    state = state.toggle(type, completed);

    final uid = ref.read(authUidProvider);
    if (uid != null) {
      // Fire-and-forget persist; the stream reconciles authoritative state.
      unawaited(ref.read(checklistRepositoryProvider).setTask(
            uid,
            state.day,
            type,
            completed: completed,
            proofUrl: proofUrl,
            verifiedSteps: verifiedSteps,
            verificationMethod: verificationMethod,
          ));
    }
    return !wasComplete && state.allComplete;
  }
}

// ===== Leaderboard =========================================================

final leaderboardProvider =
    NotifierProvider<LeaderboardNotifier, List<LeaderboardEntry>>(
        LeaderboardNotifier.new);

class LeaderboardNotifier extends Notifier<List<LeaderboardEntry>> {
  @override
  List<LeaderboardEntry> build() {
    final repo = ref.watch(leaderboardRepositoryProvider);
    final sub = repo.watch('overall').listen((l) => state = l);
    ref.onDispose(sub.cancel);
    return repo.currentSnapshot('overall') ?? const [];
  }
}

// ===== Derived / misc ======================================================

final streakProvider =
    Provider<int>((ref) => ref.watch(participantProvider)?.streak ?? 0);

/// Whether today's water goal (≥ 12 glasses) has been met — worth its own
/// daily points and counted as one of the day's tasks.
final waterTaskDoneProvider = Provider<bool>(
    (ref) => ref.watch(waterProvider) >= AppConstants.waterTaskGlasses);

/// Day completion (0..1) across the 5 activity tasks **plus** the water task.
final completionProvider = Provider<double>((ref) {
  final c = ref.watch(checklistProvider);
  final waterDone = ref.watch(waterTaskDoneProvider) ? 1 : 0;
  final total = c.tasks.length + 1; // + water
  return total == 0 ? 0.0 : (c.completedCount + waterDone) / total;
});

/// Points earned today: activity tasks + the water task (caps at 100).
final todayPointsProvider = Provider<int>((ref) {
  final base = ref.watch(checklistProvider).pointsEarned;
  final water =
      ref.watch(waterTaskDoneProvider) ? AppConstants.waterTaskPoints : 0;
  return base + water;
});

final weightSeriesProvider =
    Provider<List<double>>((ref) => MockData.weightSeries);

final dailyQuoteProvider = Provider<String>((ref) {
  final int idx = DateTime.now().day % AppConstants.motivationalQuotes.length;
  return AppConstants.motivationalQuotes[idx];
});

/// Today's synced step count. Replace with the health engine's value in a later
/// wiring pass; kept here so existing screens compile unchanged.
final stepsProvider = Provider<int>((ref) => 8450);
