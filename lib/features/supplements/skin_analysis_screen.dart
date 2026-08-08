import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../shared/widgets/glass_card.dart';
import '../../state/supplement_chart_data.dart';
import '../../state/supplement_provider.dart';
import 'supplement_consult_screen.dart' show showProductInfoSheet;

class SkinAnalysisScreen extends ConsumerStatefulWidget {
  const SkinAnalysisScreen({super.key});

  @override
  ConsumerState<SkinAnalysisScreen> createState() =>
      _SkinAnalysisScreenState();
}

class _SkinAnalysisScreenState extends ConsumerState<SkinAnalysisScreen> {
  String? _facePhoto;
  final Set<String> _concerns = {};
  bool _busy = false;
  bool _analyzing = false;

  Future<void> _capture(ImageSource source) async {
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busy = true);
    try {
      final x = await ImagePicker()
          .pickImage(source: source, maxWidth: 1200, imageQuality: 72);
      if (x != null) {
        final bytes = await x.readAsBytes();
        setState(() => _facePhoto = base64Encode(bytes));
      }
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Could not add the photo.')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _analyze() async {
    if (_facePhoto == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add a face photo first.')),
      );
      return;
    }
    if (_concerns.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Select the skin concerns you notice.')),
      );
      return;
    }
    setState(() => _analyzing = true);
    await Future<void>.delayed(const Duration(milliseconds: 1400));
    if (!mounted) return;
    final s = suggestForSkin(_concerns.toList());
    final now = DateTime.now().millisecondsSinceEpoch;
    ref.read(supplementRequestsProvider.notifier).add(SupplementRequest(
          id: 'skin_$now',
          kind: 'skin',
          conditions: _concerns.toList(),
          items: s.items,
          eat: s.eat,
          avoid: s.avoid,
          reportPhoto: _facePhoto,
          createdAt: now,
        ));
    setState(() {
      _analyzing = false;
      _concerns.clear();
      _facePhoto = null;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Sent to ${AppConstants.doctorName} for review.'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final requests = ref
        .watch(supplementRequestsProvider)
        .where((r) => r.kind == 'skin')
        .toList();
    final TextTheme text = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('AI Skin Analysis')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.xxl),
        children: [
          // Face photo
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.face_retouching_natural_rounded,
                        color: AppColors.taskYoga),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                        child: Text('Your face photo', style: text.titleMedium)),
                  ],
                ),
                if (_facePhoto != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    child: Image.memory(base64Decode(_facePhoto!),
                        height: 200,
                        width: double.infinity,
                        fit: BoxFit.cover),
                  ),
                ],
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed:
                            _busy ? null : () => _capture(ImageSource.camera),
                        icon: const Icon(Icons.photo_camera_rounded),
                        label: const Text('Selfie'),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed:
                            _busy ? null : () => _capture(ImageSource.gallery),
                        icon: const Icon(Icons.photo_library_rounded),
                        label: const Text('Upload'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          Text('What do you notice on your skin?',
              style: text.titleMedium),
          const SizedBox(height: AppSpacing.xs),
          Text('Select all that apply — the assistant builds your '
              'cleanse–tone–moisturize routine from them.',
              style:
                  text.bodySmall?.copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.xs,
            children: [
              for (final c in kSkinConcerns)
                FilterChip(
                  label: Text(c),
                  selected: _concerns.contains(c),
                  selectedColor: AppColors.taskYoga,
                  labelStyle: TextStyle(
                    color: _concerns.contains(c)
                        ? Colors.white
                        : AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                  onSelected: (v) => setState(
                      () => v ? _concerns.add(c) : _concerns.remove(c)),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _analyzing ? null : _analyze,
              icon: _analyzing
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.auto_awesome_rounded),
              label: Text(_analyzing
                  ? 'Analyzing your skin…'
                  : 'Analyze & get my routine'),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'This is a guided skin check — not a medical diagnosis. Your '
            'routine is reviewed and approved by ${AppConstants.doctorName} '
            'before you follow it.',
            style: text.bodySmall?.copyWith(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),

          if (requests.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xl),
            Text('Your skin routines', style: text.titleMedium),
            const SizedBox(height: AppSpacing.md),
            for (final r in requests) _SkinCard(request: r, text: text),
          ],
        ],
      ),
    );
  }
}

class _SkinCard extends StatelessWidget {
  const _SkinCard({required this.request, required this.text});
  final SupplementRequest request;
  final TextTheme text;

  @override
  Widget build(BuildContext context) {
    final bool approved = request.isApproved;
    final Color statusColor =
        approved ? AppColors.success : AppColors.orange;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: GlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                    child: Text(request.conditions.join(', '),
                        style: text.titleSmall)),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.14),
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  child: Text(
                      approved
                          ? 'Approved by ${AppConstants.doctorName}'
                          : 'Pending review',
                      style: text.bodySmall?.copyWith(
                          color: statusColor, fontWeight: FontWeight.w700)),
                ),
              ],
            ),
            Text(
                DateFormat('d MMM, h:mm a').format(
                    DateTime.fromMillisecondsSinceEpoch(request.createdAt)),
                style:
                    text.bodySmall?.copyWith(color: AppColors.textSecondary)),
            const SizedBox(height: AppSpacing.sm),
            Text(
                approved
                    ? 'Your routine (tap a product for details):'
                    : 'Suggested routine (pending doctor approval):',
                style: text.bodySmall?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            for (final it in request.items)
              InkWell(
                onTap: infoFor(it.product) != null
                    ? () => showProductInfoSheet(context, it.product)
                    : null,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.spa_rounded, size: 16, color: statusColor),
                      const SizedBox(width: 6),
                      Expanded(
                        child: RichText(
                          text: TextSpan(
                            style: text.bodySmall
                                ?.copyWith(color: AppColors.textSecondary),
                            children: [
                              TextSpan(
                                  text: it.product,
                                  style: const TextStyle(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w700)),
                              TextSpan(text: '  ·  ${it.dosage}'),
                            ],
                          ),
                        ),
                      ),
                      if (infoFor(it.product) != null)
                        const Icon(Icons.info_outline_rounded,
                            size: 15, color: AppColors.info),
                    ],
                  ),
                ),
              ),
            if (approved && request.doctorNote.trim().isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              Text('Doctor\'s note: ${request.doctorNote}',
                  style: text.bodySmall?.copyWith(
                      fontStyle: FontStyle.italic,
                      color: AppColors.textSecondary)),
            ],
          ],
        ),
      ),
    );
  }
}
