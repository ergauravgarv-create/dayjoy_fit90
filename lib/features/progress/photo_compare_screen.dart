import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../shared/widgets/app_snack.dart';
import '../../state/progress_photos_provider.dart';
import '../../state/providers.dart';

/// Interactive before/after comparison: drag the handle to wipe between two of
/// your progress photos, then share the split as a branded PNG. The emotional
/// payoff of a 90-day journey, in one screen.
class PhotoCompareScreen extends ConsumerStatefulWidget {
  const PhotoCompareScreen({super.key});

  @override
  ConsumerState<PhotoCompareScreen> createState() => _PhotoCompareScreenState();
}

class _PhotoCompareScreenState extends ConsumerState<PhotoCompareScreen> {
  final GlobalKey _captureKey = GlobalKey();
  double _fraction = 0.5;
  int? _beforeId;
  int? _afterId;
  bool _busy = false;

  ProgressPhoto? _byId(List<ProgressPhoto> photos, int? id) {
    if (id == null) return null;
    for (final p in photos) {
      if (p.id == id) return p;
    }
    return null;
  }

  Future<void> _share() async {
    setState(() => _busy = true);
    try {
      final boundary =
          _captureKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      if (boundary.debugNeedsPaint) {
        await Future<void>.delayed(const Duration(milliseconds: 40));
      }
      final ui.Image image = await boundary.toImage(pixelRatio: 3);
      final ByteData? data =
          await image.toByteData(format: ui.ImageByteFormat.png);
      if (data == null) throw Exception('encode failed');
      final Uint8List bytes = data.buffer.asUint8List();
      await Share.shareXFiles(
        [
          XFile.fromData(bytes,
              mimeType: 'image/png', name: 'dayjoy-fit90-transformation.png')
        ],
        text: 'My 90-day transformation with Dayjoy Fit90! 💪',
      );
    } catch (_) {
      if (mounted) {
        showAppSnack(context, 'Could not share on this device.',
            type: AppSnackType.error);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final photos = ref.watch(progressPhotosProvider);
    final participant = ref.watch(participantProvider);
    final TextTheme text = Theme.of(context).textTheme;

    // Sensible defaults: earliest photo vs. latest photo.
    final ordered = [...photos]..sort((a, b) => a.addedAt.compareTo(b.addedAt));
    _beforeId ??= ordered.isNotEmpty ? ordered.first.id : null;
    _afterId ??= ordered.length >= 2 ? ordered.last.id : _beforeId;

    final before = _byId(photos, _beforeId);
    final after = _byId(photos, _afterId);

    if (before == null || after == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Compare')),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(AppSpacing.xl),
            child: Text(
              'Add at least two progress photos to compare your transformation.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    final int daysApart =
        after.addedAt.difference(before.addedAt).inDays.abs();
    final double lost = participant?.weightLostKg ?? 0;

    return Scaffold(
      appBar: AppBar(title: const Text('Before & after')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.xxl),
        children: [
          Text('Drag the slider to reveal your progress',
              style: text.bodyMedium, textAlign: TextAlign.center),
          const SizedBox(height: AppSpacing.md),

          // The capture area (viewer + branded footer) — this is what gets shared.
          RepaintBoundary(
            key: _captureKey,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.lg),
              child: Column(
                children: [
                  _CompareViewer(
                    beforeData: before.data,
                    afterData: after.data,
                    fraction: _fraction,
                    onChanged: (f) => setState(() => _fraction = f),
                  ),
                  // Branded footer strip
                  Container(
                    width: double.infinity,
                    decoration:
                        const BoxDecoration(gradient: AppColors.brandGradient),
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg, vertical: AppSpacing.md),
                    child: Row(
                      children: [
                        const Text('Dayjoy',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 18,
                                letterSpacing: 1)),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.22),
                            borderRadius: BorderRadius.circular(AppRadius.pill),
                          ),
                          child: const Text('Fit90',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 12)),
                        ),
                        const Spacer(),
                        if (lost > 0)
                          Text('−${lost.toStringAsFixed(1)} kg',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 18)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Quick stats under the viewer.
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _stat(text, '$daysApart',
                  daysApart == 1 ? 'day apart' : 'days apart'),
              _stat(text, '−${lost.toStringAsFixed(1)}', 'kg lost'),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),

          _PhotoPicker(
            label: 'BEFORE',
            photos: ordered,
            selectedId: _beforeId,
            onSelect: (id) => setState(() => _beforeId = id),
          ),
          const SizedBox(height: AppSpacing.lg),
          _PhotoPicker(
            label: 'AFTER',
            photos: ordered,
            selectedId: _afterId,
            onSelect: (id) => setState(() => _afterId = id),
          ),
          const SizedBox(height: AppSpacing.xl),

          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _busy ? null : _share,
              icon: _busy
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.ios_share_rounded),
              label: Text(_busy ? 'Preparing…' : 'Share this comparison'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _stat(TextTheme text, String value, String label) {
    return Column(
      children: [
        Text(value,
            style: text.titleLarge?.copyWith(
                fontWeight: FontWeight.w800, color: AppColors.primary)),
        Text(label, style: text.bodySmall),
      ],
    );
  }
}

/// The draggable wipe viewer. [fraction] 0..1 controls how much of the "before"
/// image is revealed from the left.
class _CompareViewer extends StatelessWidget {
  const _CompareViewer({
    required this.beforeData,
    required this.afterData,
    required this.fraction,
    required this.onChanged,
  });

  final String beforeData;
  final String afterData;
  final double fraction;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final Uint8List beforeBytes = base64Decode(beforeData);
    final Uint8List afterBytes = base64Decode(afterData);

    return AspectRatio(
      aspectRatio: 3 / 4,
      child: LayoutBuilder(
        builder: (context, c) {
          final double w = c.maxWidth;
          void update(double dx) => onChanged((dx / w).clamp(0.0, 1.0));
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: (d) => update(d.localPosition.dx),
            onHorizontalDragUpdate: (d) => update(d.localPosition.dx),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // AFTER fills the frame.
                Image.memory(afterBytes, fit: BoxFit.cover),
                // BEFORE clipped to the left [fraction] of the frame.
                ClipRect(
                  clipper: _RevealClipper(fraction),
                  child: Image.memory(beforeBytes, fit: BoxFit.cover),
                ),
                // Corner tags.
                Positioned(
                  top: 8,
                  left: 8,
                  child: _tag('BEFORE', Colors.black87),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: _tag('AFTER', AppColors.primary),
                ),
                // Divider line.
                Positioned(
                  left: w * fraction - 1.5,
                  top: 0,
                  bottom: 0,
                  child: Container(width: 3, color: Colors.white),
                ),
                // Drag handle.
                Positioned(
                  left: w * fraction - 22,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.25),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.drag_indicator_rounded,
                          color: AppColors.primary, size: 26),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _tag(String label, Color bg) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        child: Text(label,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w800)),
      );
}

class _RevealClipper extends CustomClipper<Rect> {
  const _RevealClipper(this.f);
  final double f;

  @override
  Rect getClip(Size size) => Rect.fromLTWH(0, 0, size.width * f, size.height);

  @override
  bool shouldReclip(_RevealClipper oldClipper) => oldClipper.f != f;
}

/// A horizontal strip of photo thumbnails to choose the before/after picture.
class _PhotoPicker extends StatelessWidget {
  const _PhotoPicker({
    required this.label,
    required this.photos,
    required this.selectedId,
    required this.onSelect,
  });

  final String label;
  final List<ProgressPhoto> photos;
  final int? selectedId;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: text.labelLarge?.copyWith(
                fontWeight: FontWeight.w800, letterSpacing: 0.5)),
        const SizedBox(height: AppSpacing.sm),
        SizedBox(
          height: 82,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: photos.length,
            separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
            itemBuilder: (context, i) {
              final p = photos[i];
              final bool sel = p.id == selectedId;
              return GestureDetector(
                onTap: () => onSelect(p.id),
                child: Container(
                  width: 62,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(
                      color: sel ? AppColors.primary : Colors.transparent,
                      width: 3,
                    ),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Image.memory(base64Decode(p.data), fit: BoxFit.cover),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
