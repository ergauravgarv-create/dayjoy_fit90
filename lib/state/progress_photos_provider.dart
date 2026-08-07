import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'prefs_provider.dart';

/// A saved progress photo (stored as resized base64 on-device for the demo;
/// moves to Firebase Storage with the backend).
class ProgressPhoto {
  const ProgressPhoto({
    required this.id,
    required this.label,
    required this.data,
    required this.addedAt,
  });

  final int id;
  final String label; // Front / Side / Other
  final String data; // base64-encoded image bytes
  final DateTime addedAt;

  Map<String, dynamic> toJson() => {
        'id': id,
        'label': label,
        'data': data,
        'addedAt': addedAt.millisecondsSinceEpoch,
      };

  factory ProgressPhoto.fromJson(Map<String, dynamic> j) => ProgressPhoto(
        id: (j['id'] as num).toInt(),
        label: j['label'] as String? ?? 'Photo',
        data: j['data'] as String? ?? '',
        addedAt: DateTime.fromMillisecondsSinceEpoch(
            (j['addedAt'] as num?)?.toInt() ?? 0),
      );
}

/// The participant's progress photos, oldest first, persisted on-device.
final progressPhotosProvider =
    NotifierProvider<ProgressPhotosController, List<ProgressPhoto>>(
        ProgressPhotosController.new);

class ProgressPhotosController extends Notifier<List<ProgressPhoto>> {
  static const String _key = 'progress_photos';

  @override
  List<ProgressPhoto> build() {
    final raw = ref.watch(sharedPreferencesProvider).getString(_key);
    if (raw == null || raw.isEmpty) return const [];
    try {
      final list = (jsonDecode(raw) as List)
          .map((e) => ProgressPhoto.fromJson(e as Map<String, dynamic>))
          .toList()
        ..sort((a, b) => a.addedAt.compareTo(b.addedAt));
      return list;
    } catch (_) {
      return const [];
    }
  }

  void add(String label, String base64Data) {
    final photo = ProgressPhoto(
      id: DateTime.now().millisecondsSinceEpoch,
      label: label,
      data: base64Data,
      addedAt: DateTime.now(),
    );
    state = [...state, photo]..sort((a, b) => a.addedAt.compareTo(b.addedAt));
    _persist();
  }

  void remove(int id) {
    state = state.where((p) => p.id != id).toList();
    _persist();
  }

  void _persist() {
    ref.read(sharedPreferencesProvider).setString(
        _key, jsonEncode(state.map((p) => p.toJson()).toList()));
  }
}
