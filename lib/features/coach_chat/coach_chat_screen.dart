import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../state/coach_chat_provider.dart';

class CoachChatScreen extends ConsumerStatefulWidget {
  const CoachChatScreen({super.key});

  @override
  ConsumerState<CoachChatScreen> createState() => _CoachChatScreenState();
}

class _CoachChatScreenState extends ConsumerState<CoachChatScreen> {
  final TextEditingController _ctrl = TextEditingController();
  final ScrollController _scroll = ScrollController();

  @override
  void dispose() {
    _ctrl.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _jumpToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.jumpTo(_scroll.position.maxScrollExtent);
      }
    });
  }

  void _send() {
    final text = _ctrl.text;
    if (text.trim().isEmpty) return;
    ref.read(coachChatProvider.notifier).sendText(text,
        nowMillis: DateTime.now().millisecondsSinceEpoch);
    _ctrl.clear();
  }

  Future<void> _sendPhoto() async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final x = await ImagePicker().pickImage(
          source: ImageSource.gallery, maxWidth: 1080, imageQuality: 70);
      if (x != null) {
        final bytes = await x.readAsBytes();
        ref.read(coachChatProvider.notifier).sendPhoto(base64Encode(bytes),
            nowMillis: DateTime.now().millisecondsSinceEpoch);
      }
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Could not attach a photo.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final messages = ref.watch(coachChatProvider);
    _jumpToBottom();
    final TextTheme text = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: AppColors.primary.withOpacity(0.15),
              child: Text(AppConstants.coachName.characters.first,
                  style: const TextStyle(
                      color: AppColors.primary, fontWeight: FontWeight.w800)),
            ),
            const SizedBox(width: AppSpacing.sm),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(AppConstants.coachName, style: text.titleMedium),
                Text('Your Dayjoy consultant',
                    style: text.bodySmall
                        ?.copyWith(color: AppColors.textSecondary)),
              ],
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            color: AppColors.info.withOpacity(0.10),
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
            child: Row(
              children: [
                const Icon(Icons.info_outline_rounded,
                    size: 16, color: AppColors.info),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Demo chat — in the live app your assigned consultant '
                    'replies here.',
                    style: text.bodySmall
                        ?.copyWith(color: AppColors.textSecondary),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              controller: _scroll,
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.md),
              itemCount: messages.length,
              itemBuilder: (context, i) => _Bubble(message: messages[i]),
            ),
          ),
          SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.sm, AppSpacing.sm, AppSpacing.sm, AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.surface,
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, -2)),
                ],
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.photo_library_rounded),
                    color: AppColors.primary,
                    onPressed: _sendPhoto,
                  ),
                  Expanded(
                    child: TextField(
                      controller: _ctrl,
                      minLines: 1,
                      maxLines: 4,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: const InputDecoration(
                        hintText: 'Message your consultant…',
                        border: InputBorder.none,
                      ),
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.send_rounded),
                    color: AppColors.primary,
                    onPressed: _send,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.message});
  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final bool me = message.fromMe;
    final TextTheme text = Theme.of(context).textTheme;
    final bool seed = message.at < 1000000; // seeded opener → hide timestamp

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        mainAxisAlignment:
            me ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.75),
              padding: message.photo != null
                  ? const EdgeInsets.all(4)
                  : const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md, vertical: AppSpacing.sm),
              decoration: BoxDecoration(
                gradient: me ? AppColors.brandGradient : null,
                color: me ? null : AppColors.surfaceMuted,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(me ? 16 : 4),
                  bottomRight: Radius.circular(me ? 4 : 16),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (message.photo != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.memory(base64Decode(message.photo!),
                          width: 200, fit: BoxFit.cover),
                    ),
                  if (message.text != null)
                    Padding(
                      padding: message.photo != null
                          ? const EdgeInsets.all(6)
                          : EdgeInsets.zero,
                      child: Text(message.text!,
                          style: text.bodyMedium?.copyWith(
                              color: me ? Colors.white : null)),
                    ),
                  if (!seed)
                    Padding(
                      padding: const EdgeInsets.only(top: 3),
                      child: Text(
                        DateFormat('h:mm a').format(
                            DateTime.fromMillisecondsSinceEpoch(message.at)),
                        style: text.bodySmall?.copyWith(
                            fontSize: 10,
                            color: me
                                ? Colors.white70
                                : AppColors.textSecondary),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
