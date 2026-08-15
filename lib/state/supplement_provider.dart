import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'prefs_provider.dart';
import 'supplement_chart_data.dart';

// kSupplementConditions, kProductDosage & kChartRules come from
// supplement_chart_data.dart (built from the Dayjoy recommendation chart).

/// A suggested/approved supplement line.
class SupplementItem {
  SupplementItem({required this.product, required this.dosage});
  String product;
  String dosage;

  Map<String, dynamic> toJson() => {'product': product, 'dosage': dosage};
  factory SupplementItem.fromJson(Map<String, dynamic> j) => SupplementItem(
      product: j['product'] as String, dosage: j['dosage'] as String? ?? '');
}

/// A supplement consultation: the participant's flagged issues + optional report
/// photo, the (editable) suggested products, foods, and the doctor's decision.
class SupplementRequest {
  SupplementRequest({
    required this.id,
    required this.conditions,
    required this.items,
    required this.eat,
    required this.avoid,
    this.reportPhoto,
    this.status = 'pending',
    this.doctorNote = '',
    this.kind = 'health', // 'health' | 'skin'
    this.aiConcerns = const [],
    this.comment,
    this.bodyArea, // for skin: where on the body (Face, Hands, …)
    required this.createdAt,
    this.approvedAt,
  });

  final String id;
  final String kind;
  final List<String> conditions;

  /// Skin concerns the AI screening flagged from the photo (subset of
  /// [conditions]); the rest were added by the user.
  final List<String> aiConcerns;

  /// The user's free-text note to the doctor.
  final String? comment;

  /// For skin requests: the body area the photo is of (Face, Hands, Legs, …).
  final String? bodyArea;

  List<SupplementItem> items;
  List<String> eat;
  List<String> avoid;
  final String? reportPhoto; // base64
  String status; // 'pending' | 'approved'
  String doctorNote;
  final int createdAt;
  int? approvedAt;

  bool get isApproved => status == 'approved';

  Map<String, dynamic> toJson() => {
        'id': id,
        'kind': kind,
        'conditions': conditions,
        'aiConcerns': aiConcerns,
        'comment': comment,
        'bodyArea': bodyArea,
        'items': items.map((e) => e.toJson()).toList(),
        'eat': eat,
        'avoid': avoid,
        'reportPhoto': reportPhoto,
        'status': status,
        'doctorNote': doctorNote,
        'createdAt': createdAt,
        'approvedAt': approvedAt,
      };

  factory SupplementRequest.fromJson(Map<String, dynamic> j) =>
      SupplementRequest(
        id: j['id'] as String,
        kind: j['kind'] as String? ?? 'health',
        conditions:
            (j['conditions'] as List?)?.map((e) => e as String).toList() ??
                const [],
        aiConcerns:
            (j['aiConcerns'] as List?)?.map((e) => e as String).toList() ??
                const [],
        comment: j['comment'] as String?,
        bodyArea: j['bodyArea'] as String?,
        items: (j['items'] as List?)
                ?.map((e) => SupplementItem.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        eat: (j['eat'] as List?)?.map((e) => e as String).toList() ?? [],
        avoid: (j['avoid'] as List?)?.map((e) => e as String).toList() ?? [],
        reportPhoto: j['reportPhoto'] as String?,
        status: j['status'] as String? ?? 'pending',
        doctorNote: j['doctorNote'] as String? ?? '',
        createdAt: (j['createdAt'] as num?)?.toInt() ?? 0,
        approvedAt: (j['approvedAt'] as num?)?.toInt(),
      );
}

/// Build a de-duplicated suggestion from the selected conditions using the
/// Dayjoy recommendation chart. Recommends the first 3–4 products per issue,
/// capping the union at 6 so the plan stays focused (the doctor edits it).
({List<SupplementItem> items, List<String> eat, List<String> avoid})
    suggestFor(List<String> conditions) {
  final products = <String>[];
  final eat = <String>[];
  final avoid = <String>[];
  for (final c in conditions) {
    final r = kChartRules[c];
    if (r == null) continue;
    for (final p in r.products) {
      if (!products.contains(p)) products.add(p);
    }
    for (final e in r.eat) {
      if (!eat.contains(e)) eat.add(e);
    }
    for (final a in r.avoid) {
      if (!avoid.contains(a)) avoid.add(a);
    }
  }
  final items = products
      .take(6)
      .map((p) => SupplementItem(product: p, dosage: dosageFor(p)))
      .toList();
  return (items: items, eat: eat, avoid: avoid);
}

/// Benefits (from the chart) for the selected conditions — shown to the user.
List<String> benefitsFor(List<String> conditions) {
  final out = <String>[];
  for (final c in conditions) {
    final r = kChartRules[c];
    if (r == null) continue;
    for (final b in r.benefits) {
      if (!out.contains(b)) out.add(b);
    }
  }
  return out;
}

/// Build a Dayjoy skincare routine (cleanse–tone–moisturize) + supplement
/// support from the selected facial concerns.
({List<SupplementItem> items, List<String> eat, List<String> avoid})
    suggestForSkin(List<String> concerns) {
  final products = <String>[];
  for (final c in concerns) {
    final list = kSkinRules[c];
    if (list == null) continue;
    for (final p in list) {
      if (!products.contains(p)) products.add(p);
    }
  }
  final items = products
      .take(7)
      .map((p) => SupplementItem(product: p, dosage: dosageFor(p)))
      .toList();
  return (items: items, eat: [...kSkincareEat], avoid: [...kSkincareAvoid]);
}

/// All supplement consultations (shared between the participant & doctor
/// screens in this demo), persisted on-device.
final supplementRequestsProvider =
    NotifierProvider<SupplementRequestsController, List<SupplementRequest>>(
        SupplementRequestsController.new);

class SupplementRequestsController
    extends Notifier<List<SupplementRequest>> {
  static const String _key = 'supplement_requests';

  @override
  List<SupplementRequest> build() {
    final raw = ref.watch(sharedPreferencesProvider).getString(_key);
    if (raw == null || raw.isEmpty) return const [];
    try {
      return (jsonDecode(raw) as List)
          .map((e) => SupplementRequest.fromJson(e as Map<String, dynamic>))
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } catch (_) {
      return const [];
    }
  }

  void add(SupplementRequest req) {
    state = [req, ...state];
    _persist();
  }

  /// Replace a request (used when the doctor saves edits / approves).
  void replace(SupplementRequest req) {
    state = [for (final r in state) if (r.id == req.id) req else r];
    _persist();
  }

  void remove(String id) {
    state = state.where((r) => r.id != id).toList();
    _persist();
  }

  void _persist() {
    ref
        .read(sharedPreferencesProvider)
        .setString(_key, jsonEncode(state.map((r) => r.toJson()).toList()));
  }
}

/// Pending requests (for the doctor's queue).
final pendingSupplementRequestsProvider = Provider<List<SupplementRequest>>(
    (ref) => ref
        .watch(supplementRequestsProvider)
        .where((r) => r.status == 'pending')
        .toList());
