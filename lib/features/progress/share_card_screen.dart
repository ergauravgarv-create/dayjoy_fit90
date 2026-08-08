import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../data/models/participant.dart';
import '../../state/progress_photos_provider.dart';
import '../../state/providers.dart';

/// Renders a branded before/after + stats card and shares it as a PNG via the
/// system share sheet.
class ShareCardScreen extends ConsumerStatefulWidget {
  const ShareCardScreen({super.key});

  @override
  ConsumerState<ShareCardScreen> createState() => _ShareCardScreenState();
}

class _ShareCardScreenState extends ConsumerState<ShareCardScreen> {
  final GlobalKey _cardKey = GlobalKey();
  bool _busy = false;

  Future<void> _share() async {
    setState(() => _busy = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final boundary = _cardKey.currentContext!.findRenderObject()
          as RenderRepaintBoundary;
      // Ensure it's painted before capture.
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
              mimeType: 'image/png', name: 'dayjoy-fit90-progress.png')
        ],
        text: 'My 90-day transformation journey with Dayjoy Fit90! 💪',
      );
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Could not share the card on this device.')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final participant = ref.watch(participantProvider);
    final photos = ref.watch(progressPhotosProvider);
    if (participant == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Share your progress')),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Center(
                child: RepaintBoundary(
                  key: _cardKey,
                  child: _ProgressCard(
                    participant: participant,
                    beforeData: photos.isNotEmpty ? photos.first.data : null,
                    afterData: photos.length >= 2 ? photos.last.data : null,
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.md),
              child: Column(
                children: [
                  if (photos.length < 2)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: Text(
                        'Add before & after photos in Progress for a photo card. '
                        'You can still share your stats now.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary),
                        textAlign: TextAlign.center,
                      ),
                    ),
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
                      label: Text(_busy ? 'Preparing…' : 'Share progress card'),
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

class _ProgressCard extends StatelessWidget {
  const _ProgressCard({
    required this.participant,
    required this.beforeData,
    required this.afterData,
  });
  final Participant participant;
  final String? beforeData;
  final String? afterData;

  @override
  Widget build(BuildContext context) {
    final double lost = participant.weightLostKg;
    final int day = participant.currentDay;

    return Container(
      width: 340,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.10),
              blurRadius: 20,
              offset: const Offset(0, 8)),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Branded header
          Container(
            decoration: const BoxDecoration(gradient: AppColors.brandGradient),
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg, vertical: AppSpacing.md),
            child: Row(
              children: [
                const Text('Dayjoy',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 20,
                        letterSpacing: 1)),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.22),
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  child: const Text('Fit90',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 13)),
                ),
                const Spacer(),
                const Icon(Icons.emoji_events_rounded,
                    color: Colors.white, size: 22),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                        child: _photo(beforeData, 'BEFORE',
                            'Day 1', participant.startWeightKg, false)),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                        child: _photo(afterData, 'NOW', 'Day $day',
                            participant.currentWeightKg, true)),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                // Big stat
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                  decoration: BoxDecoration(
                    gradient: AppColors.goldGradient,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Column(
                    children: [
                      Text('−${lost.toStringAsFixed(1)} kg',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 34,
                              fontWeight: FontWeight.w900)),
                      Text('in $day days',
                          style: TextStyle(
                              color: Colors.white.withOpacity(0.95),
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(participant.name,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w800)),
                const Text('90-Day Transformation Journey',
                    style: TextStyle(color: AppColors.textSecondary)),
                const SizedBox(height: AppSpacing.md),
                const Divider(height: 1),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.favorite_rounded,
                        color: AppColors.primary, size: 14),
                    const SizedBox(width: 6),
                    Text('Powered by Dayjoy Fit90',
                        style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _photo(String? data, String tag, String sub, double kg, bool hi) {
    return Column(
      children: [
        AspectRatio(
          aspectRatio: 3 / 4,
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.surfaceMuted,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: hi ? Border.all(color: AppColors.primary, width: 2) : null,
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (data != null)
                  Image.memory(base64Decode(data), fit: BoxFit.cover)
                else
                  const Center(
                    child: Icon(Icons.person_rounded,
                        size: 46, color: AppColors.textSecondary),
                  ),
                Positioned(
                  top: 6,
                  left: 6,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: (hi ? AppColors.primary : Colors.black87),
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                    child: Text(tag,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w800)),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(sub, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        Text('${kg.toStringAsFixed(1)} kg',
            style: TextStyle(
                fontWeight: FontWeight.w800,
                color: hi ? AppColors.primary : null)),
      ],
    );
  }
}
