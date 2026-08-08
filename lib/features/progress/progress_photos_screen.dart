import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../shared/widgets/glass_card.dart';
import '../../state/progress_photos_provider.dart';
import 'photo_compare_screen.dart';

class ProgressPhotosScreen extends ConsumerStatefulWidget {
  const ProgressPhotosScreen({super.key});

  @override
  ConsumerState<ProgressPhotosScreen> createState() =>
      _ProgressPhotosScreenState();
}

class _ProgressPhotosScreenState extends ConsumerState<ProgressPhotosScreen> {
  bool _busy = false;

  Future<void> _pick(ImageSource source, String label) async {
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busy = true);
    try {
      final XFile? x = await ImagePicker()
          .pickImage(source: source, maxWidth: 1080, imageQuality: 70);
      if (x != null) {
        final bytes = await x.readAsBytes();
        ref
            .read(progressPhotosProvider.notifier)
            .add(label, base64Encode(bytes));
      }
    } catch (e) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Could not add photo on this device.')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _addSheet() {
    String label = 'Front';
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: AppColors.surfaceOf(context),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Add a progress photo',
                  style: Theme.of(ctx).textTheme.titleLarge),
              const SizedBox(height: AppSpacing.md),
              Text('View', style: Theme.of(ctx).textTheme.bodySmall),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.sm,
                children: [
                  for (final l in const ['Front', 'Side', 'Back', 'Other'])
                    ChoiceChip(
                      label: Text(l),
                      selected: label == l,
                      labelStyle: TextStyle(
                        color: label == l
                            ? Colors.white
                            : AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                      onSelected: (_) => setSheet(() => label = l),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      icon: const Icon(Icons.photo_camera_rounded),
                      label: const Text('Camera'),
                      onPressed: () {
                        Navigator.pop(ctx);
                        _pick(ImageSource.camera, label);
                      },
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.photo_library_rounded),
                      label: const Text('Gallery'),
                      onPressed: () {
                        Navigator.pop(ctx);
                        _pick(ImageSource.gallery, label);
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final photos = ref.watch(progressPhotosProvider);
    final TextTheme text = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Progress Photos')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _busy ? null : _addSheet,
        icon: _busy
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white))
            : const Icon(Icons.add_a_photo_rounded),
        label: const Text('Add photo'),
      ),
      body: photos.isEmpty
          ? _EmptyState(text: text)
          : ListView(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, 90),
              children: [
                if (photos.length >= 2) ...[
                  Text('Before & after', style: text.titleMedium),
                  const SizedBox(height: AppSpacing.md),
                  GlassCard(
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                                child: _Frame(
                                    photo: photos.first, caption: 'First')),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                                child: _Frame(
                                    photo: photos.last,
                                    caption: 'Latest',
                                    highlight: true)),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.md),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: () => Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                  builder: (_) => const PhotoCompareScreen()),
                            ),
                            icon: const Icon(Icons.compare_rounded, size: 20),
                            label: const Text('Compare & share'),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                ],
                Text('All photos (${photos.length})',
                    style: text.titleMedium),
                const SizedBox(height: AppSpacing.md),
                GridView.count(
                  crossAxisCount: 3,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: AppSpacing.sm,
                  crossAxisSpacing: AppSpacing.sm,
                  childAspectRatio: 0.72,
                  children: [
                    for (final p in photos.reversed)
                      _Thumb(
                        photo: p,
                        onDelete: () => ref
                            .read(progressPhotosProvider.notifier)
                            .remove(p.id),
                      ),
                  ],
                ),
              ],
            ),
    );
  }
}

class _Frame extends StatelessWidget {
  const _Frame(
      {required this.photo, required this.caption, this.highlight = false});
  final ProgressPhoto photo;
  final String caption;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return Column(
      children: [
        AspectRatio(
          aspectRatio: 3 / 4,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: highlight
                  ? Border.all(color: AppColors.primary, width: 2)
                  : null,
            ),
            clipBehavior: Clip.antiAlias,
            child: Image.memory(base64Decode(photo.data), fit: BoxFit.cover),
          ),
        ),
        const SizedBox(height: 4),
        Text(caption,
            style: text.bodySmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: highlight ? AppColors.primary : null)),
        Text('${photo.label} · ${_date(photo.addedAt)}',
            style: text.bodySmall?.copyWith(color: AppColors.textSecondary)),
      ],
    );
  }
}

class _Thumb extends StatelessWidget {
  const _Thumb({required this.photo, required this.onDelete});
  final ProgressPhoto photo;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.md),
            child: Image.memory(base64Decode(photo.data), fit: BoxFit.cover),
          ),
        ),
        Positioned(
          left: 4,
          bottom: 4,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(photo.label,
                style: const TextStyle(color: Colors.white, fontSize: 10)),
          ),
        ),
        Positioned(
          right: 2,
          top: 2,
          child: GestureDetector(
            onTap: onDelete,
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: const BoxDecoration(
                  color: Colors.black54, shape: BoxShape.circle),
              child: const Icon(Icons.close_rounded,
                  size: 15, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.text});
  final TextTheme text;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.photo_camera_back_rounded,
                size: 64, color: AppColors.primary),
            const SizedBox(height: AppSpacing.lg),
            Text('Capture your transformation', style: text.titleLarge),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Add a photo every week or two. Your first and latest will show as '
              'a before/after here.',
              style: text.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

String _date(DateTime d) => '${d.day}/${d.month}/${d.year}';
