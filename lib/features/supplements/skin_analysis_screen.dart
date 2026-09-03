import 'dart:convert';
import 'dart:math' show sqrt;
import 'dart:typed_data';
import 'dart:ui' as ui;

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

const List<String> _bodyAreas = [
  'Face',
  'Neck',
  'Hands',
  'Nails',
  'Arms',
  'Legs',
  'Feet',
  'Back',
  'Chest',
  'Scalp',
  'Other',
];

class SkinAnalysisScreen extends ConsumerStatefulWidget {
  const SkinAnalysisScreen({super.key});

  @override
  ConsumerState<SkinAnalysisScreen> createState() =>
      _SkinAnalysisScreenState();
}

class _SkinAnalysisScreenState extends ConsumerState<SkinAnalysisScreen> {
  String? _facePhoto;
  final Set<String> _concerns = {};
  final Set<String> _aiConcerns = {}; // flagged by the AI screening
  final TextEditingController _comment = TextEditingController();
  bool _busy = false;
  bool _analyzing = false;
  bool _aiRunning = false;
  bool _hasAnalyzed = false;
  bool _consent = false; // explicit consent to process the photo
  String _bodyArea = 'Face'; // which body area the photo is of

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

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

  /// Step 1 — confirm the body part BEFORE analysing. The app tells the user
  /// which body part it will analyse (e.g. "toenail") and asks them to confirm
  /// or correct it; analysis only runs on a confirmed part.
  Future<void> _confirmAndAnalyze() async {
    if (_facePhoto == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add a skin photo first.')),
      );
      return;
    }
    if (!_consent) return;

    final photo = base64Decode(_facePhoto!);
    String area = _bodyArea; // the part the app will analyse
    final TextTheme text = Theme.of(context).textTheme;

    final confirmed = await showDialog<String>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: const Text('Confirm the body part'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  child: Image.memory(photo,
                      height: 120, width: double.infinity, fit: BoxFit.cover),
                ),
                const SizedBox(height: AppSpacing.md),
                RichText(
                  text: TextSpan(
                    style: text.bodyMedium,
                    children: [
                      const TextSpan(
                          text: 'We\'ll analyse this as a photo of your '),
                      TextSpan(
                          text: area,
                          style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              color: AppColors.taskYoga)),
                      const TextSpan(text: '. Is that correct?'),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text('Tap the correct part if this is wrong:',
                    style: text.bodySmall
                        ?.copyWith(color: AppColors.textSecondary)),
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.xs,
                  children: [
                    for (final a in _bodyAreas)
                      ChoiceChip(
                        label: Text(a),
                        selected: area == a,
                        selectedColor: AppColors.taskYoga,
                        labelStyle: TextStyle(
                          color: area == a
                              ? Colors.white
                              : AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                        onSelected: (_) => setLocal(() => area = a),
                      ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel')),
            FilledButton.icon(
              onPressed: () => Navigator.pop(ctx, area),
              icon: const Icon(Icons.auto_awesome_rounded, size: 18),
              label: const Text('Yes, analyse'),
            ),
          ],
        ),
      ),
    );

    if (confirmed == null || !mounted) return;
    setState(() => _bodyArea = confirmed);
    await _runAiAnalysis();
  }

  /// Runs a lightweight on-device screening of the photo and pre-selects
  /// the concerns it flags. This is a heuristic wellness screen (colour/tone
  /// signals), NOT a medical diagnosis — a doctor reviews everything.
  Future<void> _runAiAnalysis() async {
    if (_facePhoto == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add a face photo first.')),
      );
      return;
    }
    if (!_consent) return;
    setState(() => _aiRunning = true);
    final detected =
        await _detectFromPhoto(base64Decode(_facePhoto!), _bodyArea);
    // A brief pause so it reads as "analysing".
    await Future<void>.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    setState(() {
      _aiRunning = false;
      _hasAnalyzed = true;
      _aiConcerns
        ..clear()
        ..addAll(detected);
      _concerns.addAll(detected); // pre-select AI-flagged concerns
    });
  }

  /// Very light colour/tone heuristic → a few concerns to review, tuned to the
  /// body area (face / nails / other skin). Returns concern labels from
  /// [kSkinConcerns]. Never throws — this is a wellness screen, not a diagnosis.
  Future<List<String>> _detectFromPhoto(Uint8List bytes, String area) async {
    try {
      final codec = await ui.instantiateImageCodec(bytes, targetWidth: 80);
      final frame = await codec.getNextFrame();
      final data =
          await frame.image.toByteData(format: ui.ImageByteFormat.rawRgba);
      if (data == null) return const [];
      final px = data.buffer.asUint8List();
      int n = 0, dark = 0, shiny = 0;
      double sumR = 0, sumG = 0, sumB = 0, sumL = 0, sumL2 = 0;
      for (int i = 0; i + 3 < px.length; i += 4) {
        if (px[i + 3] < 20) continue; // skip transparent
        final r = px[i].toDouble(), g = px[i + 1].toDouble(), b = px[i + 2].toDouble();
        final l = 0.299 * r + 0.587 * g + 0.114 * b;
        sumR += r; sumG += g; sumB += b; sumL += l; sumL2 += l * l;
        if (l < 60) dark++;
        if (l > 220) shiny++;
        n++;
      }
      if (n == 0) return const [];
      final avgL = sumL / n;
      final variance = (sumL2 / n) - (avgL * avgL);
      final std = variance > 0 ? sqrt(variance) : 0.0;
      final redness = (sumR / n) - ((sumG / n) + (sumB / n)) / 2;
      final darkFrac = dark / n, shinyFrac = shiny / n;
      final out = <String>[];

      if (area == 'Nails') {
        // Ridged / uneven texture reads as brittleness; redness → infection;
        // darkening → discolouration.
        if (std > 42) out.add('Brittle / breaking nails');
        if (redness > 18) out.add('Nail fungus / infection');
        if (avgL < 110 || darkFrac > 0.30) out.add('Discoloured nails');
        if (out.isEmpty) out.add('Brittle / breaking nails');
      } else if (area == 'Face') {
        if (redness > 16) out.add('Sensitivity / redness');
        if (darkFrac > 0.28) out.add('Dark circles');
        if (shinyFrac > 0.10) out.add('Oily skin');
        if (std > 52) out.add('Pigmentation / uneven tone');
        if (avgL < 95) out.add('Dullness');
      } else {
        // Any other skin (hands, arms, legs, back…).
        if (redness > 20 && std > 44) {
          out.add('Psoriasis / scaly patches');
        } else if (redness > 15) {
          out.add('Sensitivity / redness');
        }
        if (darkFrac > 0.28) out.add('Blemishes / dark spots');
        if (std > 55) out.add('Rough / cracked skin');
        if (avgL < 95) out.add('Tan / sunburn');
      }
      return out.where(kSkinConcerns.contains).take(3).toList();
    } catch (_) {
      return const [];
    }
  }

  Future<void> _submit() async {
    if (_facePhoto == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add a face photo first.')),
      );
      return;
    }
    if (!_consent) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please give consent above to continue.')),
      );
      return;
    }
    if (_concerns.isEmpty && _comment.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Select a concern or add a comment for the doctor.')),
      );
      return;
    }
    setState(() => _analyzing = true);
    await Future<void>.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;
    final s = suggestForSkin(_concerns.toList());
    final now = DateTime.now().millisecondsSinceEpoch;
    ref.read(supplementRequestsProvider.notifier).add(SupplementRequest(
          id: 'skin_$now',
          kind: 'skin',
          conditions: _concerns.toList(),
          aiConcerns: _aiConcerns.toList(),
          comment: _comment.text.trim().isEmpty ? null : _comment.text.trim(),
          bodyArea: _bodyArea,
          items: s.items,
          eat: s.eat,
          avoid: s.avoid,
          reportPhoto: _facePhoto,
          createdAt: now,
        ));
    setState(() {
      _analyzing = false;
      _concerns.clear();
      _aiConcerns.clear();
      _comment.clear();
      _hasAnalyzed = false;
      _facePhoto = null;
      _consent = false;
    });
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Report sent to ${AppConstants.doctorName} for review.'),
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
                        child: Text('Photo of the affected skin',
                            style: text.titleMedium)),
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
                        label: const Text('Camera'),
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

          // Which body area — face or any skin (hand, arm, leg…).
          Text('Where is the skin issue?', style: text.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.xs,
            children: [
              for (final a in _bodyAreas)
                ChoiceChip(
                  label: Text(a),
                  selected: _bodyArea == a,
                  selectedColor: AppColors.taskYoga,
                  labelStyle: TextStyle(
                    color: _bodyArea == a
                        ? Colors.white
                        : AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                  onSelected: (_) => setState(() => _bodyArea = a),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),

          // Consent — required before processing the photo.
          GlassCard(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm, vertical: 2),
            child: CheckboxListTile(
              value: _consent,
              onChanged: (v) => setState(() => _consent = v ?? false),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
              dense: true,
              activeColor: AppColors.taskYoga,
              title: Text(
                'I consent to my skin photo being analysed for a skin-wellness '
                'screening and shared with ${AppConstants.doctorName} for review.',
                style: text.bodySmall,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Step 1 — AI screening of the photo.
          SizedBox(
            width: double.infinity,
            child: FilledButton.tonalIcon(
              onPressed: (_facePhoto == null || _aiRunning || !_consent)
                  ? null
                  : _confirmAndAnalyze,
              icon: _aiRunning
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.auto_awesome_rounded),
              label: Text(_aiRunning
                  ? 'Analysing your photo…'
                  : (_hasAnalyzed
                      ? 'Re-run AI analysis'
                      : 'Analyse my skin with AI')),
            ),
          ),
          if (_hasAnalyzed) ...[
            const SizedBox(height: AppSpacing.md),
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.auto_awesome_rounded,
                          size: 18, color: AppColors.taskYoga),
                      const SizedBox(width: 6),
                      Text('AI screening result', style: text.titleSmall),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  if (_aiConcerns.isEmpty)
                    Text(
                        'No obvious concerns detected. Add what you notice below.',
                        style: text.bodySmall
                            ?.copyWith(color: AppColors.textSecondary))
                  else ...[
                    Text('Flagged for review (pre-selected below):',
                        style: text.bodySmall
                            ?.copyWith(color: AppColors.textSecondary)),
                    const SizedBox(height: AppSpacing.xs),
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.xs,
                      children: [
                        for (final c in _aiConcerns)
                          Chip(
                            avatar: const Icon(Icons.auto_awesome_rounded,
                                size: 14, color: Colors.white),
                            label: Text(c,
                                style:
                                    const TextStyle(color: Colors.white)),
                            backgroundColor: AppColors.taskYoga,
                            visualDensity: VisualDensity.compact,
                          ),
                      ],
                    ),
                  ],
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'A wellness screen from photo colour & tone — not a medical '
                    'diagnosis. Confirm or adjust below.',
                    style: text.bodySmall
                        ?.copyWith(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.lg),

          // Step 2 — user confirms / adds concerns.
          Text('What do you notice on your skin?', style: text.titleMedium),
          const SizedBox(height: AppSpacing.xs),
          Text('Add or remove any — AI-flagged ones (✦) are pre-selected.',
              style:
                  text.bodySmall?.copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.xs,
            children: [
              for (final c in kSkinConcerns)
                FilterChip(
                  avatar: _aiConcerns.contains(c)
                      ? Icon(Icons.auto_awesome_rounded,
                          size: 14,
                          color: _concerns.contains(c)
                              ? Colors.white
                              : AppColors.taskYoga)
                      : null,
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

          // Step 3 — free-text comment for the doctor.
          Text('Anything else for the doctor? (optional)',
              style: text.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: _comment,
            maxLines: 3,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              hintText: 'Describe your concern in your own words…',
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: (_analyzing || !_consent) ? null : _submit,
              icon: _analyzing
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.send_rounded),
              label: Text(_analyzing
                  ? 'Sending report…'
                  : (_consent
                      ? 'Send report to doctor'
                      : 'Give consent above to continue')),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'The report (your photo, concerns & comment) and suggested products '
            'go to ${AppConstants.doctorName}. You\'ll see the routine only '
            'after the doctor reviews and approves it.',
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
                    child: Text(
                        '${request.bodyArea != null && request.bodyArea!.isNotEmpty ? '${request.bodyArea} · ' : ''}${request.conditions.join(', ')}',
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
            // The routine stays hidden until the doctor reviews & approves —
            // the customer must NOT see suggested products before approval.
            if (!approved)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.orange.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.hourglass_top_rounded,
                        size: 18, color: AppColors.orange),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        '${AppConstants.doctorName} is reviewing your photo. '
                        'Your recommended routine will appear here once approved.',
                        style: text.bodySmall
                            ?.copyWith(color: AppColors.textSecondary),
                      ),
                    ),
                  ],
                ),
              )
            else ...[
              Text('Your routine (tap a product for details):',
                  style:
                      text.bodySmall?.copyWith(fontWeight: FontWeight.w700)),
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
              if (request.doctorNote.trim().isNotEmpty) ...[
                const SizedBox(height: AppSpacing.sm),
                Text('Doctor\'s note: ${request.doctorNote}',
                    style: text.bodySmall?.copyWith(
                        fontStyle: FontStyle.italic,
                        color: AppColors.textSecondary)),
              ],
            ],
          ],
        ),
      ),
    );
  }
}
