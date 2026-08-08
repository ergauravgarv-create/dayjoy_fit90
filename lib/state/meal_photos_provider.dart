import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/meals/meal_data.dart';
import 'meal_provider.dart';
import 'prefs_provider.dart';

/// Decode a stored meal-photos JSON string into a {MealType: base64} map.
Map<MealType, String> decodeMealPhotos(String? raw) {
  if (raw == null || raw.isEmpty) return const {};
  try {
    final map = jsonDecode(raw) as Map<String, dynamic>;
    return {
      for (final e in map.entries)
        MealType.values[int.parse(e.key)]: e.value as String,
    };
  } catch (_) {
    return const {};
  }
}

/// A meal photo per slot (breakfast/lunch/dinner/snack) for the current day,
/// stored as base64 on-device under a per-day key so it survives restarts and
/// each day starts fresh.
final mealPhotosProvider =
    NotifierProvider<MealPhotosController, Map<MealType, String>>(
        MealPhotosController.new);

String mealPhotosKey(DateTime d) {
  final m = d.month.toString().padLeft(2, '0');
  final day = d.day.toString().padLeft(2, '0');
  return 'meal_photos_${d.year}-$m-$day';
}

class MealPhotosController extends Notifier<Map<MealType, String>> {
  String get _key => mealPhotosKey(DateTime.now());

  @override
  Map<MealType, String> build() =>
      decodeMealPhotos(ref.watch(sharedPreferencesProvider).getString(_key));

  void setPhoto(MealType type, String base64Data) {
    state = {...state, type: base64Data};
    _persist();
  }

  void removePhoto(MealType type) {
    final next = Map<MealType, String>.from(state)..remove(type);
    state = next;
    _persist();
  }

  void _persist() {
    ref.read(sharedPreferencesProvider).setString(
        _key,
        jsonEncode({
          for (final e in state.entries) e.key.index.toString(): e.value,
        }));
  }
}

/// One day of the food diary: its logged meals and any meal photos.
class DiaryDay {
  const DiaryDay(
      {required this.date, required this.logs, required this.photos});
  final DateTime date;
  final List<MealLog> logs;
  final Map<MealType, String> photos;

  int get kcal => logs.fold(0, (s, l) => s + l.kcal);
  List<MealLog> logsFor(MealType t) =>
      logs.where((l) => l.type == t).toList();
  bool get isEmpty => logs.isEmpty && photos.isEmpty;
}

/// The last 7 days of the food diary (newest first), reading past days from
/// storage and today's from the live providers. Only days with meals or photos
/// are included.
final foodDiaryProvider = Provider<List<DiaryDay>>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  // Rebuild when today's diary or photos change.
  ref.watch(mealLogProvider);
  ref.watch(mealPhotosProvider);

  final now = DateTime.now();
  final base = DateTime(now.year, now.month, now.day);
  final days = <DiaryDay>[];
  for (int i = 0; i < 7; i++) {
    final d = base.subtract(Duration(days: i));
    final logs = decodeMealLogs(prefs.getString(mealLogKey(d)));
    final photos = decodeMealPhotos(prefs.getString(mealPhotosKey(d)));
    final day = DiaryDay(date: d, logs: logs, photos: photos);
    if (!day.isEmpty) days.add(day);
  }
  return days;
});

