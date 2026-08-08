import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../shared/widgets/glass_card.dart';
import '../../state/subscription_provider.dart';
import '../subscription/paywall.dart';
import 'explore_items.dart';

class ExploreScreen extends ConsumerStatefulWidget {
  const ExploreScreen({super.key});

  @override
  ConsumerState<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends ConsumerState<ExploreScreen> {
  String _query = '';

  void _open(ExploreItem item) {
    // Premium tools require an active subscription; free users see a paywall.
    if (item.premium && !ensurePremium(context, ref, item.title)) return;
    Navigator.of(context)
        .push(MaterialPageRoute<void>(builder: (_) => item.builder()));
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final bool searching = _query.trim().isNotEmpty;
    final bool premium = ref.watch(isPremiumProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Explore')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.sm),
            child: TextField(
              onChanged: (v) => setState(() => _query = v),
              decoration: InputDecoration(
                hintText: 'Search tools…',
                prefixIcon: const Icon(Icons.search_rounded),
                filled: true,
                fillColor: AppColors.surfaceMuted,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  borderSide: BorderSide.none,
                ),
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
              ),
            ),
          ),
          Expanded(
            child: searching
                ? _buildSearchResults(text, premium)
                : _buildSections(text, premium),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults(TextTheme text, bool premium) {
    final matches =
        allExploreItems.where((i) => i.matches(_query)).toList();
    if (matches.isEmpty) {
      return Center(
        child: Text('No tools match "$_query"', style: text.bodyMedium),
      );
    }
    return GridView.count(
      crossAxisCount: 2,
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.xxl),
      mainAxisSpacing: AppSpacing.md,
      crossAxisSpacing: AppSpacing.md,
      childAspectRatio: 1.55,
      children: [
        for (final i in matches)
          _Tile(
              item: i,
              locked: i.premium && !premium,
              onTap: () => _open(i)),
      ],
    );
  }

  Widget _buildSections(TextTheme text, bool premium) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.xxl),
      children: [
        for (final entry in exploreSections.entries) ...[
          Padding(
            padding: const EdgeInsets.only(
                bottom: AppSpacing.md, top: AppSpacing.sm),
            child: Text(entry.key, style: text.titleMedium),
          ),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: AppSpacing.md,
            crossAxisSpacing: AppSpacing.md,
            childAspectRatio: 1.55,
            children: [
              for (final i in entry.value)
                _Tile(
                    item: i,
                    locked: i.premium && !premium,
                    onTap: () => _open(i)),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
      ],
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({required this.item, required this.onTap, this.locked = false});
  final ExploreItem item;
  final VoidCallback onTap;
  final bool locked;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return GlassCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: item.color.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Icon(item.icon, color: item.color, size: 22),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(item.title,
                  style: text.titleSmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
              Text(item.subtitle,
                  style:
                      text.bodySmall?.copyWith(color: AppColors.textSecondary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
            ],
          ),
          if (locked)
            const Positioned(top: 0, right: 0, child: PremiumLockBadge()),
        ],
      ),
    );
  }
}
