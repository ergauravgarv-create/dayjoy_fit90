import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants/app_constants.dart';
import 'measurements_provider.dart';
import 'mindfulness_provider.dart';
import 'prefs_provider.dart';
import 'progress_photos_provider.dart';
import 'water_provider.dart';

// ===========================================================================
// Community feed
// ===========================================================================

class FeedPost {
  const FeedPost({
    required this.id,
    required this.author,
    required this.city,
    required this.text,
    required this.createdAt,
    this.photo,
    this.baseCheers = 0,
    this.isMine = false,
  });

  final String id;
  final String author;
  final String city;
  final String text;
  final int createdAt; // millis since epoch
  final String? photo; // base64, optional
  final int baseCheers;
  final bool isMine;

  Map<String, dynamic> toJson() => {
        'id': id,
        'author': author,
        'city': city,
        'text': text,
        'createdAt': createdAt,
        'photo': photo,
      };

  factory FeedPost.fromJson(Map<String, dynamic> j) => FeedPost(
        id: j['id'] as String,
        author: j['author'] as String? ?? 'You',
        city: j['city'] as String? ?? '',
        text: j['text'] as String? ?? '',
        createdAt: (j['createdAt'] as num?)?.toInt() ?? 0,
        photo: j['photo'] as String?,
        isMine: true,
      );
}

/// A few seeded wins from other participants so the feed is never empty.
const List<FeedPost> _kSeedPosts = [
  FeedPost(
    id: 'seed1',
    author: 'Priya S.',
    city: 'Ahmedabad',
    text: 'Hit my 10,000 steps every day this week! 🎉 The evening walks are '
        'becoming my favourite part of the day.',
    createdAt: 1,
    baseCheers: 24,
  ),
  FeedPost(
    id: 'seed2',
    author: 'Rahul M.',
    city: 'Surat',
    text: 'Down 4 kg in 3 weeks 💪 Sticking to the diet plan and logging every '
        'meal really works. Keep going everyone!',
    createdAt: 2,
    baseCheers: 41,
  ),
  FeedPost(
    id: 'seed3',
    author: 'Anjali T.',
    city: 'Rajkot',
    text: 'Completed my first full Surya Namaskar warm-up without stopping. '
        'Small wins add up! 🧘',
    createdAt: 3,
    baseCheers: 18,
  ),
  FeedPost(
    id: 'seed4',
    author: 'Vikram P.',
    city: 'Vadodara',
    text: '30 days streak done ✅ Water goal every single day. My energy is '
        'completely different now.',
    createdAt: 4,
    baseCheers: 33,
  ),
];

/// The signed-in user's own posts, persisted on-device.
final userPostsProvider =
    NotifierProvider<UserPostsController, List<FeedPost>>(
        UserPostsController.new);

class UserPostsController extends Notifier<List<FeedPost>> {
  static const String _key = 'community_posts';

  @override
  List<FeedPost> build() {
    final raw = ref.watch(sharedPreferencesProvider).getString(_key);
    if (raw == null || raw.isEmpty) return const [];
    try {
      return (jsonDecode(raw) as List)
          .map((e) => FeedPost.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return const [];
    }
  }

  void addPost({
    required String author,
    required String city,
    required String text,
    String? photo,
    required int nowMillis,
  }) {
    final post = FeedPost(
      id: 'me_$nowMillis',
      author: author,
      city: city,
      text: text,
      photo: photo,
      createdAt: nowMillis,
      isMine: true,
    );
    state = [post, ...state];
    _persist();
  }

  void remove(String id) {
    state = state.where((p) => p.id != id).toList();
    _persist();
  }

  void _persist() {
    ref
        .read(sharedPreferencesProvider)
        .setString(_key, jsonEncode(state.map((p) => p.toJson()).toList()));
  }
}

/// The merged feed: the user's posts first, then the seeded ones (newest first).
final feedProvider = Provider<List<FeedPost>>((ref) {
  final mine = ref.watch(userPostsProvider);
  final all = [...mine, ..._kSeedPosts];
  all.sort((a, b) => b.createdAt.compareTo(a.createdAt));
  return all;
});

/// Post ids the user has cheered, persisted on-device.
final cheersProvider =
    NotifierProvider<CheersController, Set<String>>(CheersController.new);

class CheersController extends Notifier<Set<String>> {
  static const String _key = 'community_cheers';

  @override
  Set<String> build() {
    final raw = ref.watch(sharedPreferencesProvider).getString(_key);
    if (raw == null || raw.isEmpty) return <String>{};
    try {
      return (jsonDecode(raw) as List).map((e) => e as String).toSet();
    } catch (_) {
      return <String>{};
    }
  }

  void toggle(String id) {
    state = state.contains(id)
        ? (state.difference({id}))
        : ({...state, id});
    ref
        .read(sharedPreferencesProvider)
        .setString(_key, jsonEncode(state.toList()));
  }
}

// ===========================================================================
// Weekly mini-challenges (real progress from existing app state)
// ===========================================================================

class Challenge {
  const Challenge({
    required this.id,
    required this.title,
    required this.description,
    required this.target,
    required this.bonusPoints,
    required this.icon,
    required this.color,
  });

  final String id;
  final String title;
  final String description;
  final int target;
  final int bonusPoints;
  final IconData icon;
  final Color color;
}

const List<Challenge> kChallenges = [
  Challenge(
    id: 'hydration',
    title: 'Hydration Hero',
    description: 'Hit your water goal on 5 days this week',
    target: 5,
    bonusPoints: 50,
    icon: Icons.water_drop_rounded,
    color: Color(0xFF3B82F6),
  ),
  Challenge(
    id: 'mindful',
    title: 'Mindful Week',
    description: 'Complete 3 mindfulness sessions this week',
    target: 3,
    bonusPoints: 30,
    icon: Icons.self_improvement_rounded,
    color: Color(0xFF7C5CFC),
  ),
  Challenge(
    id: 'checkin',
    title: 'Check-in Champ',
    description: 'Log 2 body measurements this week',
    target: 2,
    bonusPoints: 20,
    icon: Icons.monitor_weight_rounded,
    color: Color(0xFF1FBF75),
  ),
  Challenge(
    id: 'photos',
    title: 'Snapshot Streak',
    description: 'Add 2 progress photos this week',
    target: 2,
    bonusPoints: 20,
    icon: Icons.photo_camera_rounded,
    color: Color(0xFFFA6E35),
  ),
];

String _dayKey(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

/// Current progress for each challenge id, derived from live app state.
final challengeProgressProvider = Provider<Map<String, int>>((ref) {
  // Water: days this week that met the glass goal.
  final week = ref.watch(weeklyWaterProvider);
  final hydration =
      week.where((g) => g >= AppConstants.waterTaskGlasses).length;

  // Mindfulness: mindful days within the last 7 calendar days.
  final mindfulDays = ref.watch(mindfulnessProvider);
  final now = DateTime.now();
  int mindful = 0;
  for (int i = 0; i < 7; i++) {
    if (mindfulDays.contains(_dayKey(now.subtract(Duration(days: i))))) {
      mindful++;
    }
  }

  // Measurements & photos logged in the last 7 days.
  final weekAgo = now.subtract(const Duration(days: 7));
  final checkin = ref
      .watch(measurementsProvider)
      .where((m) => m.date.isAfter(weekAgo))
      .length;
  final photos = ref
      .watch(progressPhotosProvider)
      .where((p) => p.addedAt.isAfter(weekAgo))
      .length;

  return {
    'hydration': hydration,
    'mindful': mindful,
    'checkin': checkin,
    'photos': photos,
  };
});

/// Challenge ids whose bonus the user has claimed → when they were claimed,
/// persisted on-device.
final claimedChallengesProvider =
    NotifierProvider<ClaimedChallengesController, Map<String, DateTime>>(
        ClaimedChallengesController.new);

class ClaimedChallengesController extends Notifier<Map<String, DateTime>> {
  static const String _key = 'challenges_claimed';

  @override
  Map<String, DateTime> build() {
    final raw = ref.watch(sharedPreferencesProvider).getString(_key);
    if (raw == null || raw.isEmpty) return const {};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map) {
        return decoded.map((k, v) => MapEntry(
            k as String,
            DateTime.fromMillisecondsSinceEpoch((v as num).toInt())));
      }
      // Migrate the old List<String> format.
      final now = DateTime.now();
      return {for (final e in decoded as List) e as String: now};
    } catch (_) {
      return const {};
    }
  }

  void claim(String id) {
    if (state.containsKey(id)) return;
    state = {...state, id: DateTime.now()};
    ref.read(sharedPreferencesProvider).setString(
        _key,
        jsonEncode(
            state.map((k, v) => MapEntry(k, v.millisecondsSinceEpoch))));
  }
}

/// Total bonus points earned from claimed challenges.
final bonusPointsProvider = Provider<int>((ref) {
  final claimed = ref.watch(claimedChallengesProvider);
  return kChallenges
      .where((c) => claimed.containsKey(c.id))
      .fold(0, (sum, c) => sum + c.bonusPoints);
});
