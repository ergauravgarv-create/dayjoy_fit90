import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../state/repository_providers.dart';

/// Admin composer for a broadcast announcement sent to every participant's
/// notification inbox.
class BroadcastScreen extends ConsumerStatefulWidget {
  const BroadcastScreen({super.key});

  @override
  ConsumerState<BroadcastScreen> createState() => _BroadcastScreenState();
}

class _BroadcastScreenState extends ConsumerState<BroadcastScreen> {
  final _title = TextEditingController();
  final _body = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final title = _title.text.trim();
    final body = _body.text.trim();
    if (title.isEmpty || body.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add a title and a message first.')),
      );
      return;
    }

    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Send to all participants?'),
        content: Text(
            'Every participant will get this announcement in their inbox:\n\n'
            '"$title"'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Send')),
        ],
      ),
    );
    if (confirm != true) return;

    setState(() => _sending = true);
    await ref
        .read(notificationRepositoryProvider)
        .addBroadcast(title: title, body: body);
    if (!mounted) return;
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Announcement sent to all participants ✓')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final bool hasContent =
        _title.text.trim().isNotEmpty && _body.text.trim().isNotEmpty;

    return Scaffold(
      appBar: AppBar(title: const Text('New announcement')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, 40),
        children: [
          GlassCard(
            child: Row(
              children: [
                const Icon(Icons.campaign_rounded, color: AppColors.primary),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                      'This message goes to every participant\'s notification '
                      'inbox.',
                      style: text.bodyMedium),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          TextField(
            controller: _title,
            textCapitalization: TextCapitalization.sentences,
            onChanged: (_) => setState(() {}),
            maxLength: 60,
            decoration: const InputDecoration(
              labelText: 'Title',
              hintText: 'e.g. Live yoga session tomorrow 7 AM',
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: _body,
            textCapitalization: TextCapitalization.sentences,
            onChanged: (_) => setState(() {}),
            maxLines: 4,
            maxLength: 300,
            decoration: const InputDecoration(
              labelText: 'Message',
              hintText: 'Write your announcement…',
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Live preview of the inbox card
          Text('Preview', style: text.titleSmall),
          const SizedBox(height: AppSpacing.sm),
          GlassCard(
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppColors.primary.withOpacity(0.15),
                  child: const Icon(Icons.campaign_rounded,
                      color: AppColors.primary),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                          _title.text.trim().isEmpty
                              ? 'Title preview'
                              : _title.text.trim(),
                          style: text.titleSmall),
                      const SizedBox(height: 2),
                      Text(
                          _body.text.trim().isEmpty
                              ? 'Your message will appear here.'
                              : _body.text.trim(),
                          style: text.bodySmall),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          FilledButton.icon(
            onPressed: (_sending || !hasContent) ? null : _send,
            icon: _sending
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.send_rounded),
            label: Text(_sending ? 'Sending…' : 'Send to all participants'),
          ),
        ],
      ),
    );
  }
}
