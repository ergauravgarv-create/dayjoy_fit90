import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../shared/widgets/glass_card.dart';
import '../../state/community_provider.dart';
import '../../state/providers.dart';

class CommunityScreen extends ConsumerWidget {
  const CommunityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Community'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Feed'),
              Tab(text: 'Challenges'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _FeedTab(),
            _ChallengesTab(),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Feed
// ---------------------------------------------------------------------------

class _FeedTab extends ConsumerWidget {
  const _FeedTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feed = ref.watch(feedProvider);
    final cheers = ref.watch(cheersProvider);

    return Stack(
      children: [
        ListView(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, 90),
          children: [
            for (final post in feed)
              _PostCard(
                post: post,
                cheered: cheers.contains(post.id),
                onCheer: () =>
                    ref.read(cheersProvider.notifier).toggle(post.id),
                onDelete: post.isMine
                    ? () =>
                        ref.read(userPostsProvider.notifier).remove(post.id)
                    : null,
              ),
          ],
        ),
        Positioned(
          right: AppSpacing.lg,
          bottom: AppSpacing.lg,
          child: FloatingActionButton.extended(
            onPressed: () => _openComposer(context, ref),
            icon: const Icon(Icons.edit_rounded),
            label: const Text('Share a win'),
          ),
        ),
      ],
    );
  }

  Future<void> _openComposer(BuildContext context, WidgetRef ref) async {
    final participant = ref.read(participantProvider);
    if (participant == null) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surfaceOf(context),
      builder: (_) =>
          _Composer(author: participant.name, city: participant.city, ref: ref),
    );
  }
}

class _Composer extends StatefulWidget {
  const _Composer(
      {required this.author, required this.city, required this.ref});
  final String author;
  final String city;
  final WidgetRef ref;

  @override
  State<_Composer> createState() => _ComposerState();
}

class _ComposerState extends State<_Composer> {
  final TextEditingController _ctrl = TextEditingController();
  String? _photo;
  bool _busy = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    setState(() => _busy = true);
    try {
      final x = await ImagePicker()
          .pickImage(source: ImageSource.gallery, maxWidth: 1080, imageQuality: 70);
      if (x != null) {
        final bytes = await x.readAsBytes();
        setState(() => _photo = base64Encode(bytes));
      }
    } catch (_) {
      // Ignore — posting without a photo is fine.
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _post() {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;
    widget.ref.read(userPostsProvider.notifier).addPost(
          author: widget.author,
          city: widget.city,
          text: text,
          photo: _photo,
          nowMillis: DateTime.now().millisecondsSinceEpoch,
        );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.lg + bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Share a win', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _ctrl,
            maxLines: 4,
            maxLength: 280,
            autofocus: true,
            decoration: const InputDecoration(
              hintText: 'What went well today? Inspire the others…',
              border: OutlineInputBorder(),
            ),
          ),
          if (_photo != null) ...[
            const SizedBox(height: AppSpacing.sm),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.md),
              child: Image.memory(base64Decode(_photo!),
                  height: 140, width: double.infinity, fit: BoxFit.cover),
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              OutlinedButton.icon(
                onPressed: _busy ? null : _pickPhoto,
                icon: const Icon(Icons.photo_library_rounded),
                label: Text(_photo == null ? 'Add photo' : 'Change photo'),
              ),
              const Spacer(),
              FilledButton(onPressed: _post, child: const Text('Post')),
            ],
          ),
        ],
      ),
    );
  }
}

class _PostCard extends StatelessWidget {
  const _PostCard(
      {required this.post,
      required this.cheered,
      required this.onCheer,
      this.onDelete});
  final FeedPost post;
  final bool cheered;
  final VoidCallback onCheer;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final int cheerCount = post.baseCheers + (cheered ? 1 : 0);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: GlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppColors.primary.withOpacity(0.15),
                  child: Text(
                    post.author.isNotEmpty ? post.author.characters.first : '?',
                    style: const TextStyle(
                        color: AppColors.primary, fontWeight: FontWeight.w800),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(post.isMine ? '${post.author} (You)' : post.author,
                          style: text.titleSmall),
                      Text(
                          '${post.city.isNotEmpty ? '${post.city} · ' : ''}${_timeAgo(post.createdAt)}',
                          style: text.bodySmall
                              ?.copyWith(color: AppColors.textSecondary)),
                    ],
                  ),
                ),
                if (onDelete != null)
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.delete_outline_rounded, size: 20),
                    color: AppColors.textSecondary,
                    onPressed: onDelete,
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(post.text, style: text.bodyMedium),
            if (post.photo != null) ...[
              const SizedBox(height: AppSpacing.sm),
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.md),
                child: Image.memory(base64Decode(post.photo!),
                    width: double.infinity, height: 180, fit: BoxFit.cover),
              ),
            ],
            const SizedBox(height: AppSpacing.sm),
            InkWell(
              borderRadius: BorderRadius.circular(AppRadius.pill),
              onTap: onCheer,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      cheered
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded,
                      color: cheered ? AppColors.error : AppColors.textSecondary,
                      size: 20,
                    ),
                    const SizedBox(width: 6),
                    Text('$cheerCount',
                        style: text.bodyMedium?.copyWith(
                            color: cheered
                                ? AppColors.error
                                : AppColors.textSecondary,
                            fontWeight: FontWeight.w700)),
                    const SizedBox(width: 4),
                    Text('Cheer',
                        style: text.bodySmall
                            ?.copyWith(color: AppColors.textSecondary)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _timeAgo(int millis) {
  // Seed posts use tiny timestamps; treat pre-2000 as "recently".
  if (millis < 946684800000) return 'recently';
  final diff = DateTime.now().difference(
      DateTime.fromMillisecondsSinceEpoch(millis));
  if (diff.inMinutes < 1) return 'just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  return '${diff.inDays}d ago';
}

// ---------------------------------------------------------------------------
// Challenges
// ---------------------------------------------------------------------------

class _ChallengesTab extends ConsumerWidget {
  const _ChallengesTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = ref.watch(challengeProgressProvider);
    final claimed = ref.watch(claimedChallengesProvider);
    final bonus = ref.watch(bonusPointsProvider);
    final TextTheme text = Theme.of(context).textTheme;

    return ListView(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.xxl),
      children: [
        GlassCard(
          gradient: AppColors.goldGradient,
          child: Row(
            children: [
              const Icon(Icons.workspace_premium_rounded,
                  color: Colors.white, size: 36),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('$bonus bonus points',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w800)),
                    Text('Complete this week’s challenges to earn more',
                        style:
                            TextStyle(color: Colors.white.withOpacity(0.9))),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        Text('This week’s challenges', style: text.titleMedium),
        const SizedBox(height: AppSpacing.md),
        for (final c in kChallenges)
          _ChallengeCard(
            challenge: c,
            current: progress[c.id] ?? 0,
            claimed: claimed.containsKey(c.id),
            onClaim: () {
              ref.read(claimedChallengesProvider.notifier).claim(c.id);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('🎉 +${c.bonusPoints} bonus points!'),
                  backgroundColor: AppColors.success,
                ),
              );
            },
          ),
      ],
    );
  }
}

class _ChallengeCard extends StatelessWidget {
  const _ChallengeCard({
    required this.challenge,
    required this.current,
    required this.claimed,
    required this.onClaim,
  });
  final Challenge challenge;
  final int current;
  final bool claimed;
  final VoidCallback onClaim;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final int capped = current > challenge.target ? challenge.target : current;
    final double pct = challenge.target == 0 ? 0 : capped / challenge.target;
    final bool complete = capped >= challenge.target;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: GlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: challenge.color.withOpacity(0.14),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Icon(challenge.icon, color: challenge.color),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(challenge.title, style: text.titleSmall),
                      Text(challenge.description,
                          style: text.bodySmall
                              ?.copyWith(color: AppColors.textSecondary)),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withOpacity(0.14),
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  child: Text('+${challenge.bonusPoints}',
                      style: text.bodySmall?.copyWith(
                          color: AppColors.accent,
                          fontWeight: FontWeight.w800)),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.pill),
              child: LinearProgressIndicator(
                value: pct,
                minHeight: 8,
                backgroundColor: challenge.color.withOpacity(0.12),
                valueColor: AlwaysStoppedAnimation(challenge.color),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Text('$capped / ${challenge.target}',
                    style: text.bodySmall
                        ?.copyWith(color: AppColors.textSecondary)),
                const Spacer(),
                if (claimed)
                  Row(
                    children: [
                      const Icon(Icons.check_circle_rounded,
                          size: 16, color: AppColors.success),
                      const SizedBox(width: 4),
                      Text('Claimed',
                          style: text.bodySmall?.copyWith(
                              color: AppColors.success,
                              fontWeight: FontWeight.w700)),
                    ],
                  )
                else if (complete)
                  FilledButton(
                    onPressed: onClaim,
                    style: FilledButton.styleFrom(
                        visualDensity: VisualDensity.compact),
                    child: Text('Claim +${challenge.bonusPoints}'),
                  )
                else
                  Text('Keep going',
                      style: text.bodySmall
                          ?.copyWith(color: AppColors.textSecondary)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
