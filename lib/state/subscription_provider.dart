import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/billing/subscription_plans.dart';
import 'prefs_provider.dart';
import 'reminders_provider.dart';

/// Notification id for the device-level renewal reminder (away from the daily
/// reminders at 1000+ and follow-up reminders at 900000+).
const int _renewalNotifId = 950001;

/// The participant's active subscription (if any).
/// How an auto-renewal is paid.
enum RenewMethod { card, wallet }

class ActiveSubscription {
  const ActiveSubscription({
    required this.planId,
    required this.startedAt,
    required this.expiresAt,
    this.autoRenew = false,
    this.renewMethod = RenewMethod.card,
  });

  final String planId;
  final DateTime startedAt;
  final DateTime expiresAt;
  final bool autoRenew;
  final RenewMethod renewMethod;

  SubscriptionPlan? get plan => planById(planId);
  bool get isActive => DateTime.now().isBefore(expiresAt);
  int get daysLeft => expiresAt.difference(DateTime.now()).inDays.clamp(0, 100000);

  ActiveSubscription copyWith({bool? autoRenew, RenewMethod? renewMethod}) =>
      ActiveSubscription(
        planId: planId,
        startedAt: startedAt,
        expiresAt: expiresAt,
        autoRenew: autoRenew ?? this.autoRenew,
        renewMethod: renewMethod ?? this.renewMethod,
      );

  Map<String, dynamic> toJson() => {
        'planId': planId,
        'startedAt': startedAt.toIso8601String(),
        'expiresAt': expiresAt.toIso8601String(),
        'autoRenew': autoRenew,
        'renewMethod': renewMethod.name,
      };

  factory ActiveSubscription.fromJson(Map<String, dynamic> j) =>
      ActiveSubscription(
        planId: j['planId'] as String? ?? '1m',
        startedAt: DateTime.tryParse(j['startedAt'] as String? ?? '') ??
            DateTime.now(),
        expiresAt: DateTime.tryParse(j['expiresAt'] as String? ?? '') ??
            DateTime.now(),
        autoRenew: j['autoRenew'] == true,
        renewMethod: RenewMethod.values.firstWhere(
            (m) => m.name == j['renewMethod'],
            orElse: () => RenewMethod.card),
      );
}

final subscriptionProvider =
    NotifierProvider<SubscriptionController, ActiveSubscription?>(
        SubscriptionController.new);

class SubscriptionController extends Notifier<ActiveSubscription?> {
  static const String _key = 'active_subscription';

  @override
  ActiveSubscription? build() {
    final raw = ref.watch(sharedPreferencesProvider).getString(_key);
    if (raw == null || raw.isEmpty) return null;
    try {
      return ActiveSubscription.fromJson(
          jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  /// Activate a plan. NOTE: real billing must go through Google Play / the
  /// Dayjoy backend; this local activation is for the app flow only.
  void activate(SubscriptionPlan plan) {
    final now = DateTime.now();
    // Existing time is preserved when renewing/upgrading (stacks the duration).
    final base = (state != null && state!.isActive) ? state!.expiresAt : now;
    final sub = ActiveSubscription(
      planId: plan.id,
      startedAt: now,
      expiresAt: DateTime(base.year, base.month + plan.months, base.day,
          base.hour, base.minute),
      // Preserve the auto-renew preference across renewals/upgrades.
      autoRenew: state?.autoRenew ?? false,
      renewMethod: state?.renewMethod ?? RenewMethod.card,
    );
    state = sub;
    ref.read(sharedPreferencesProvider).setString(_key, jsonEncode(sub.toJson()));
    _scheduleRenewalReminder(sub);
  }

  void setAutoRenew(bool enabled) {
    final s = state;
    if (s == null) return;
    state = s.copyWith(autoRenew: enabled);
    ref.read(sharedPreferencesProvider).setString(_key, jsonEncode(state!.toJson()));
  }

  void setRenewMethod(RenewMethod method) {
    final s = state;
    if (s == null) return;
    state = s.copyWith(renewMethod: method);
    ref.read(sharedPreferencesProvider).setString(_key, jsonEncode(state!.toJson()));
  }

  void cancel() {
    state = null;
    ref.read(sharedPreferencesProvider).remove(_key);
    ref.read(notificationServiceProvider).cancel(_renewalNotifId);
  }

  /// Schedules a device notification ~3 days before the plan expires so the
  /// user is reminded to renew even when the app is closed.
  Future<void> _scheduleRenewalReminder(ActiveSubscription sub) async {
    final service = ref.read(notificationServiceProvider);
    await service.requestPermission();
    final e = sub.expiresAt;
    final when = DateTime(e.year, e.month, e.day, 9)
        .subtract(const Duration(days: 3));
    await service.scheduleOnceAt(
      id: _renewalNotifId,
      title: 'Your Fit90 plan is expiring soon',
      body: 'Renew your ${sub.plan?.title ?? 'plan'} to keep premium access — '
          'consultations, diet, workouts and more.',
      when: when,
    );
  }
}

/// Whether premium features are unlocked (an active, unexpired subscription).
final isPremiumProvider = Provider<bool>((ref) {
  final sub = ref.watch(subscriptionProvider);
  return sub != null && sub.isActive;
});
