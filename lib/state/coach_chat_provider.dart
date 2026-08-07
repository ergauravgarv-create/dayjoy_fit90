import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants/app_constants.dart';
import 'prefs_provider.dart';

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.fromMe,
    required this.at,
    this.text,
    this.photo,
  });

  final String id;
  final bool fromMe;
  final int at; // millis since epoch
  final String? text;
  final String? photo; // base64

  Map<String, dynamic> toJson() => {
        'id': id,
        'fromMe': fromMe,
        'at': at,
        'text': text,
        'photo': photo,
      };

  factory ChatMessage.fromJson(Map<String, dynamic> j) => ChatMessage(
        id: j['id'] as String,
        fromMe: j['fromMe'] == true,
        at: (j['at'] as num?)?.toInt() ?? 0,
        text: j['text'] as String?,
        photo: j['photo'] as String?,
      );
}

/// Seeded opening messages from the consultant (shown until the participant
/// starts the conversation, after which the whole thread is persisted).
List<ChatMessage> _seed() => [
      ChatMessage(
        id: 'seed1',
        fromMe: false,
        at: 1,
        text: 'Hi! I\'m ${AppConstants.coachName}, your Dayjoy consultant. '
            'I\'m here to support your 90-day journey. 🙌',
      ),
      const ChatMessage(
        id: 'seed2',
        fromMe: false,
        at: 2,
        text: 'Log your meals and weekly check-ins, and message me any time '
            'with questions. For a detailed diet review, book a consult from '
            'your profile.',
      ),
    ];

/// Canned demo replies. Generic and encouraging — the live app routes these to
/// your real consultant.
const List<String> _replies = [
  'Thanks for sharing! Keep logging consistently and I\'ll review your '
      'progress before our next check-in. 💪',
  'Great question. Aim for ~1.6 g protein per kg and plenty of water — I\'ll '
      'fine-tune your plan in our consult.',
  'Nice work staying on track! Small, steady habits win over 90 days. Keep it '
      'up. 🌟',
  'Noted 👍 If this is a medical concern, please book a consult so I can advise '
      'you properly.',
];

final coachChatProvider =
    NotifierProvider<CoachChatController, List<ChatMessage>>(
        CoachChatController.new);

class CoachChatController extends Notifier<List<ChatMessage>> {
  static const String _key = 'coach_chat';

  @override
  List<ChatMessage> build() {
    final raw = ref.watch(sharedPreferencesProvider).getString(_key);
    if (raw == null || raw.isEmpty) return _seed();
    try {
      final list = (jsonDecode(raw) as List)
          .map((e) => ChatMessage.fromJson(e as Map<String, dynamic>))
          .toList();
      return list.isEmpty ? _seed() : list;
    } catch (_) {
      return _seed();
    }
  }

  void _append(ChatMessage m) {
    state = [...state, m];
    ref
        .read(sharedPreferencesProvider)
        .setString(_key, jsonEncode(state.map((e) => e.toJson()).toList()));
  }

  void sendText(String text, {required int nowMillis}) {
    final t = text.trim();
    if (t.isEmpty) return;
    _append(ChatMessage(id: 'm_$nowMillis', fromMe: true, at: nowMillis, text: t));
    _scheduleReply(nowMillis);
  }

  void sendPhoto(String base64, {required int nowMillis}) {
    _append(
        ChatMessage(id: 'p_$nowMillis', fromMe: true, at: nowMillis, photo: base64));
    _scheduleReply(nowMillis);
  }

  /// Adds a canned consultant reply shortly after (demo behaviour).
  void _scheduleReply(int nowMillis) {
    final int replyCount = state.where((m) => !m.fromMe && m.id != 'seed1' && m.id != 'seed2').length;
    final String body = _replies[replyCount % _replies.length];
    Future<void>.delayed(const Duration(milliseconds: 900), () {
      _append(ChatMessage(
          id: 'r_${nowMillis}_r', fromMe: false, at: nowMillis + 1, text: body));
    });
  }
}
