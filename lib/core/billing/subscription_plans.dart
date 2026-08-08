import 'package:flutter/foundation.dart';

/// Positioning badge for a plan.
enum PlanTag { none, mostPopular, bestValue }

/// The approved Dayjoy Fit90 subscription plans. Prices are GST-inclusive
/// (18% GST) whole-rupee customer prices. This file is the single source of
/// truth for pricing, the referral incentive and the internal BV/allocation
/// model — matching the approved commercial tables to the paisa.
@immutable
class SubscriptionPlan {
  const SubscriptionPlan({
    required this.months,
    required this.priceInr,
    required this.effectiveMonthly,
    required this.roundedMonthly,
    required this.discountPct,
    required this.tag,
    this.title,
  });

  /// Duration in months.
  final int months;

  /// GST-inclusive customer price in whole rupees.
  final int priceInr;

  /// price ÷ months (2-dp), e.g. ₹899.67 for the 3-month plan.
  final double effectiveMonthly;

  /// Customer-facing rounded monthly price (e.g. ₹900).
  final int roundedMonthly;

  /// Approximate discount vs. the 1-month plan (percent).
  final double discountPct;

  final PlanTag tag;

  /// Optional marketing title (e.g. the 3-month "Transformation Plan").
  final String? title;

  String get id => '${months}m';

  String get durationLabel => months == 1 ? '1 month' : '$months months';

  /// The full internal economics (GST, referral, allocations, BV) for this plan.
  PlanEconomics get economics => PlanEconomics.forPrice(priceInr.toDouble());
}

/// The approved plan list, in display order.
const List<SubscriptionPlan> kPlans = [
  SubscriptionPlan(
    months: 1,
    priceInr: 999,
    effectiveMonthly: 999,
    roundedMonthly: 999,
    discountPct: 0,
    tag: PlanTag.none,
    title: 'Fit90 Kickstart',
  ),
  SubscriptionPlan(
    months: 3,
    priceInr: 2699,
    effectiveMonthly: 899.67,
    roundedMonthly: 900,
    discountPct: 10,
    tag: PlanTag.mostPopular,
    title: 'Fit90 Transform',
  ),
  SubscriptionPlan(
    months: 6,
    priceInr: 4999,
    effectiveMonthly: 833.17,
    roundedMonthly: 833,
    discountPct: 16.6,
    tag: PlanTag.none,
    title: 'Fit90 Momentum',
  ),
  SubscriptionPlan(
    months: 9,
    priceInr: 7199,
    effectiveMonthly: 799.89,
    roundedMonthly: 800,
    discountPct: 20,
    tag: PlanTag.none,
    title: 'Fit90 Pro',
  ),
  SubscriptionPlan(
    months: 12,
    priceInr: 8999,
    effectiveMonthly: 749.92,
    roundedMonthly: 750,
    discountPct: 25,
    tag: PlanTag.bestValue,
    title: 'Fit90 Elite',
  ),
];

SubscriptionPlan? planById(String id) {
  for (final p in kPlans) {
    if (p.id == id) return p;
  }
  return null;
}

/// The approved commercial rates. Keep every downstream calculation pointing
/// here so a policy change is a single-file edit.
class BillingRates {
  static const double gst = 0.18; // 18% GST
  static const double referral = 0.05; // 5% of GST-inclusive price
  static const double management = 0.10; // 10% of company balance
  static const double developer = 0.05; // 5% of company balance
  static const double admin = 0.05; // 5% of company balance
  static const double bvAllocation = 0.80; // 80% of company balance
  static const double bvDivisor = 105.0; // BV = base × 100 ÷ 105
  static const double googlePlayFee = 0.0; // 0%
}

/// Full per-transaction economics computed from **unrounded** values, exactly
/// as the approved model specifies. Round only for display.
@immutable
class PlanEconomics {
  const PlanEconomics({
    required this.priceInclGst,
    required this.taxableValue,
    required this.gstAmount,
    required this.googlePlayFee,
    required this.referralAmount,
    required this.companyBalance,
    required this.managementAmount,
    required this.developerAmount,
    required this.adminAmount,
    required this.bvBase,
    required this.bvPoints,
  });

  final double priceInclGst;
  final double taxableValue; // price ÷ 1.18
  final double gstAmount; // price − taxable
  final double googlePlayFee; // 0%
  final double referralAmount; // price × 5%
  final double companyBalance; // taxable − referral
  final double managementAmount; // company × 10%
  final double developerAmount; // company × 5%
  final double adminAmount; // company × 5%
  final double bvBase; // company × 80%
  final double bvPoints; // bvBase × 100 ÷ 105

  factory PlanEconomics.forPrice(double priceInclGst) {
    final taxable = priceInclGst / (1 + BillingRates.gst);
    final gst = priceInclGst - taxable;
    final referral = priceInclGst * BillingRates.referral;
    final company = taxable - referral;
    final bvBase = company * BillingRates.bvAllocation;
    return PlanEconomics(
      priceInclGst: priceInclGst,
      taxableValue: taxable,
      gstAmount: gst,
      googlePlayFee: priceInclGst * BillingRates.googlePlayFee,
      referralAmount: referral,
      companyBalance: company,
      managementAmount: company * BillingRates.management,
      developerAmount: company * BillingRates.developer,
      adminAmount: company * BillingRates.admin,
      bvBase: bvBase,
      bvPoints: bvBase * 100 / BillingRates.bvDivisor,
    );
  }
}

/// ₹ with thousands separators and 2 decimals (customer-facing).
String formatInr(num value, {int decimals = 2}) {
  final fixed = value.toStringAsFixed(decimals);
  final parts = fixed.split('.');
  final intPart = parts[0].replaceAllMapped(
    RegExp(r'(\d)(?=(\d{3})+$)'),
    (m) => '${m[1]},',
  );
  return parts.length > 1 ? '₹$intPart.${parts[1]}' : '₹$intPart';
}
