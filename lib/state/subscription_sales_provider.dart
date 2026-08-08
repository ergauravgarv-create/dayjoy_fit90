import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/billing/subscription_plans.dart';

/// Active subscriber counts per plan id. Mock data for now — swap this
/// provider's source for the backend/API later and every total updates.
final subscriptionSalesProvider = Provider<Map<String, int>>((ref) => const {
      '1m': 120,
      '3m': 85,
      '6m': 40,
      '9m': 18,
      '12m': 12,
    });

/// Aggregated revenue & BV totals across all active subscriptions, computed
/// from the approved economics model (GST, 5% referral, allocations, BV).
class RevenueTotals {
  const RevenueTotals({
    required this.subscribers,
    required this.revenueInclGst,
    required this.gstCollected,
    required this.taxable,
    required this.referralPayout,
    required this.companyBalance,
    required this.management,
    required this.developer,
    required this.admin,
    required this.bvBase,
    required this.bvPoints,
    required this.perPlan,
  });

  final int subscribers;
  final double revenueInclGst;
  final double gstCollected;
  final double taxable;
  final double referralPayout;
  final double companyBalance;
  final double management;
  final double developer;
  final double admin;
  final double bvBase;
  final double bvPoints;

  /// Per-plan breakdown rows, in plan display order.
  final List<PlanRevenue> perPlan;
}

class PlanRevenue {
  const PlanRevenue({
    required this.plan,
    required this.count,
    required this.revenueInclGst,
    required this.referralPayout,
    required this.bvPoints,
  });

  final SubscriptionPlan plan;
  final int count;
  final double revenueInclGst;
  final double referralPayout;
  final double bvPoints;
}

final revenueTotalsProvider = Provider<RevenueTotals>((ref) {
  final sales = ref.watch(subscriptionSalesProvider);

  int subs = 0;
  double revenue = 0,
      gst = 0,
      taxable = 0,
      referral = 0,
      company = 0,
      mgmt = 0,
      dev = 0,
      admin = 0,
      bvBase = 0,
      bv = 0;
  final rows = <PlanRevenue>[];

  for (final plan in kPlans) {
    final int count = sales[plan.id] ?? 0;
    final e = plan.economics;
    subs += count;
    revenue += e.priceInclGst * count;
    gst += e.gstAmount * count;
    taxable += e.taxableValue * count;
    referral += e.referralAmount * count;
    company += e.companyBalance * count;
    mgmt += e.managementAmount * count;
    dev += e.developerAmount * count;
    admin += e.adminAmount * count;
    bvBase += e.bvBase * count;
    bv += e.bvPoints * count;
    rows.add(PlanRevenue(
      plan: plan,
      count: count,
      revenueInclGst: e.priceInclGst * count,
      referralPayout: e.referralAmount * count,
      bvPoints: e.bvPoints * count,
    ));
  }

  return RevenueTotals(
    subscribers: subs,
    revenueInclGst: revenue,
    gstCollected: gst,
    taxable: taxable,
    referralPayout: referral,
    companyBalance: company,
    management: mgmt,
    developer: dev,
    admin: admin,
    bvBase: bvBase,
    bvPoints: bv,
    perPlan: rows,
  );
});
