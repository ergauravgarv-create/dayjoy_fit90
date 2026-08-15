import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../services/ocr/ocr_service.dart';
import '../../shared/widgets/glass_card.dart';
import '../../state/supplement_chart_data.dart';
import '../../state/supplement_provider.dart';

/// Read-only product knowledge sheet (tagline, benefits, ingredients, dosage)
/// shown when a participant taps a product in their plan.
void showProductInfoSheet(BuildContext context, String product) {
  final info = infoFor(product);
  if (info == null) return;
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    backgroundColor: AppColors.surfaceOf(context),
    builder: (ctx) {
      final text = Theme.of(ctx).textTheme;
      return SafeArea(
        child: ConstrainedBox(
          constraints:
              BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.8),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.medication_liquid_rounded,
                        color: AppColors.primary),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(child: Text(product, style: text.titleLarge)),
                ],
              ),
              Text(info.tagline,
                  style: text.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                      fontStyle: FontStyle.italic)),
              const SizedBox(height: AppSpacing.md),
              Text('Benefits',
                  style:
                      text.titleSmall?.copyWith(color: AppColors.primary)),
              const SizedBox(height: 4),
              for (final b in info.benefits)
                Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('•  '),
                      Expanded(child: Text(b, style: text.bodySmall)),
                    ],
                  ),
                ),
              if (info.ingredients.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.sm),
                Text('Ingredients: ${info.ingredients}',
                    style: text.bodySmall
                        ?.copyWith(color: AppColors.textSecondary)),
              ],
              const SizedBox(height: AppSpacing.sm),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.info.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.schedule_rounded,
                        size: 18, color: AppColors.info),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                        child: Text('How to take: ${info.dosage}',
                            style: text.bodySmall)),
                  ],
                ),
              ),
            ],
          ),
          ),
        ),
      );
    },
  );
}

/// Keyword hints → health condition, for the light text-based AI screening of
/// the user's described symptoms. Keys are labels from [kSupplementConditions].
const Map<String, List<String>> _healthKeywords = {
  'Diabetes': ['diabet', 'sugar', 'glucose', 'hba1c', 'insulin'],
  'Heart Disease': [
    'heart', 'cardiac', 'blood pressure', 'hypertension', 'cholesterol',
    'chest pain', 'bp '
  ],
  'Bone & Joint Problems': [
    'bone', 'joint', 'knee', 'arthritis', 'back pain', 'calcium'
  ],
  'Liver Disease': ['liver', 'fatty liver', 'sgpt', 'sgot', 'bilirubin', 'jaundice'],
  'Digestion (Indigestion / Acidity)': [
    'acidity', 'gas', 'indigestion', 'bloating', 'gastric', 'heartburn', 'acid'
  ],
  'Piles / Fissure': ['piles', 'fissure', 'hemorrhoid', 'haemorrhoid'],
  'Low Immunity': ['immunity', 'frequent cold', 'infection', 'weak immune'],
  'Respiratory Health': ['asthma', 'breathing', 'cough', 'lungs', 'respirat', 'bronch'],
  'Female Health (Weakness / Anaemia)': [
    'anaemia', 'anemia', 'hemoglobin', 'haemoglobin', 'iron', 'weakness'
  ],
  'Female Health (Hormonal Imbalance)': ['pcod', 'pcos', 'hormonal', 'period', 'menstru'],
  'Weight Management': ['weight', 'obesity', 'obese', 'overweight'],
  'Skin Problems': ['skin', 'acne', 'pimple', 'eczema', 'rash'],
  'Brain Health / Cognitive': [
    'memory', 'focus', 'concentration', 'brain', 'stress', 'anxiety'
  ],
  'Kidney (Stone / Uric Acid / UTI)': [
    'kidney', 'stone', 'uric acid', 'uti', 'creatinine', 'urine'
  ],
  'Thyroid (Hypothyroidism)': ['thyroid', 'tsh', 'hypothyroid'],
  'Eye Health': ['eye', 'vision', 'eyesight'],
  'Healthy Sleep': ['sleep', 'insomnia'],
  'Hair / Nail Health': ['hair fall', 'hairfall', 'dandruff', 'nail'],
  'Sinusitis': ['sinus'],
  'Sciatica': ['sciatica'],
  'Varicose Veins': ['varicose'],
};

class SupplementConsultScreen extends ConsumerStatefulWidget {
  const SupplementConsultScreen({super.key});

  @override
  ConsumerState<SupplementConsultScreen> createState() =>
      _SupplementConsultScreenState();
}

class _SupplementConsultScreenState
    extends ConsumerState<SupplementConsultScreen> {
  final Set<String> _selected = {};
  final Set<String> _aiConcerns = {}; // flagged by the AI screening
  final TextEditingController _comment = TextEditingController();
  final OcrService _ocr = createOcrService();
  String? _reportPhoto;
  bool _busy = false;
  bool _aiRunning = false;
  bool _hasAnalyzed = false;
  bool _submitting = false;
  bool _consent = false;
  bool _reportRead = false; // OCR pulled text from the attached report

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  /// Light AI screening: reads the described symptoms and flags matching
  /// health conditions. Not a diagnosis — the doctor reviews everything and
  /// reads any attached report.
  Future<void> _runAiAnalysis() async {
    if (_comment.text.trim().isEmpty && _reportPhoto == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
                Text('Describe your symptoms or attach a report first.')),
      );
      return;
    }
    if (!_consent) return;
    setState(() => _aiRunning = true);

    // Read the attached medical report on-device (OCR), then screen the
    // combined report text + typed symptoms for health-condition keywords.
    String reportText = '';
    if (_reportPhoto != null) {
      reportText = await _ocr.extractText(base64Decode(_reportPhoto!));
    }
    await Future<void>.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;

    final input = '${_comment.text} $reportText'.toLowerCase();
    final flagged = <String>[];
    for (final e in _healthKeywords.entries) {
      if (e.value.any((k) => input.contains(k))) flagged.add(e.key);
    }
    final detected =
        flagged.where(kSupplementConditions.contains).take(6).toList();
    setState(() {
      _aiRunning = false;
      _hasAnalyzed = true;
      _reportRead = reportText.trim().isNotEmpty;
      _aiConcerns
        ..clear()
        ..addAll(detected);
      _selected.addAll(detected);
    });
  }

  Future<void> _attach(ImageSource source) async {
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busy = true);
    try {
      final x = await ImagePicker()
          .pickImage(source: source, maxWidth: 1400, imageQuality: 72);
      if (x != null) {
        final bytes = await x.readAsBytes();
        setState(() => _reportPhoto = base64Encode(bytes));
      }
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Could not attach the report.')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _submit() async {
    if (!_consent) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please give consent above to continue.')),
      );
      return;
    }
    if (_selected.isEmpty &&
        _comment.text.trim().isEmpty &&
        _reportPhoto == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'Select an issue, describe symptoms, or attach a report.')),
      );
      return;
    }
    setState(() => _submitting = true);
    await Future<void>.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;
    final s = suggestFor(_selected.toList());
    final req = SupplementRequest(
      id: 's_${DateTime.now().millisecondsSinceEpoch}',
      conditions: _selected.toList(),
      aiConcerns: _aiConcerns.toList(),
      comment: _comment.text.trim().isEmpty ? null : _comment.text.trim(),
      items: s.items,
      eat: s.eat,
      avoid: s.avoid,
      reportPhoto: _reportPhoto,
      createdAt: DateTime.now().millisecondsSinceEpoch,
    );
    ref.read(supplementRequestsProvider.notifier).add(req);
    setState(() {
      _submitting = false;
      _selected.clear();
      _aiConcerns.clear();
      _comment.clear();
      _reportPhoto = null;
      _hasAnalyzed = false;
      _consent = false;
      _reportRead = false;
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
        .where((r) => r.kind == 'health')
        .toList();
    final TextTheme text = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Supplement Consultation')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.xxl),
        children: [
          Text('Tell us your health issues', style: text.titleMedium),
          const SizedBox(height: AppSpacing.xs),
          Text(
              'Select what applies, or attach a medical / test report. '
              '${AppConstants.doctorName} reviews and approves your plan.',
              style:
                  text.bodySmall?.copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.xs,
            children: [
              for (final c in kSupplementConditions)
                FilterChip(
                  avatar: _aiConcerns.contains(c)
                      ? Icon(Icons.auto_awesome_rounded,
                          size: 14,
                          color: _selected.contains(c)
                              ? Colors.white
                              : AppColors.primary)
                      : null,
                  label: Text(c),
                  selected: _selected.contains(c),
                  selectedColor: AppColors.primary,
                  labelStyle: TextStyle(
                    color: _selected.contains(c)
                        ? Colors.white
                        : AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                  onSelected: (v) => setState(
                      () => v ? _selected.add(c) : _selected.remove(c)),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),

          // Report attachment
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.description_rounded,
                        color: AppColors.info),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text('Medical / test report (optional)',
                          style: text.titleSmall),
                    ),
                  ],
                ),
                if (_reportPhoto != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    child: Image.memory(base64Decode(_reportPhoto!),
                        height: 160,
                        width: double.infinity,
                        fit: BoxFit.cover),
                  ),
                ],
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _busy
                            ? null
                            : () => _attach(ImageSource.camera),
                        icon: const Icon(Icons.photo_camera_rounded),
                        label: const Text('Capture'),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _busy
                            ? null
                            : () => _attach(ImageSource.gallery),
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

          // Describe symptoms — feeds the AI screening.
          Text('Describe your symptoms (optional)', style: text.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: _comment,
            maxLines: 3,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              hintText: 'e.g. frequent acidity, high sugar, joint pain…',
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Consent — required before analysing / sharing health data.
          GlassCard(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm, vertical: 2),
            child: CheckboxListTile(
              value: _consent,
              onChanged: (v) => setState(() => _consent = v ?? false),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
              dense: true,
              activeColor: AppColors.primary,
              title: Text(
                'I consent to my health details and any report being analysed '
                'and shared with ${AppConstants.doctorName} for review.',
                style: text.bodySmall,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // AI screening of the described symptoms.
          SizedBox(
            width: double.infinity,
            child: FilledButton.tonalIcon(
              onPressed: (_aiRunning || !_consent) ? null : _runAiAnalysis,
              icon: _aiRunning
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.auto_awesome_rounded),
              label: Text(_aiRunning
                  ? 'Analysing…'
                  : (_hasAnalyzed ? 'Re-run AI analysis' : 'Analyse with AI')),
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
                          size: 18, color: AppColors.primary),
                      const SizedBox(width: 6),
                      Text('AI screening result', style: text.titleSmall),
                    ],
                  ),
                  if (_reportRead)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Row(
                        children: [
                          const Icon(Icons.document_scanner_rounded,
                              size: 13, color: AppColors.success),
                          const SizedBox(width: 4),
                          Text('Read text from your report',
                              style: text.bodySmall
                                  ?.copyWith(color: AppColors.success)),
                        ],
                      ),
                    ),
                  const SizedBox(height: AppSpacing.xs),
                  if (_aiConcerns.isEmpty)
                    Text(
                        'No specific conditions detected from your text/report. '
                        'The doctor will review your attached report and details.',
                        style: text.bodySmall
                            ?.copyWith(color: AppColors.textSecondary))
                  else ...[
                    Text('Flagged from your description (pre-selected above):',
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
                                style: const TextStyle(color: Colors.white)),
                            backgroundColor: AppColors.primary,
                            visualDensity: VisualDensity.compact,
                          ),
                      ],
                    ),
                  ],
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'A screening from your described symptoms — not a '
                    'diagnosis. The doctor reviews and approves.',
                    style: text.bodySmall
                        ?.copyWith(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.lg),

          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: (_submitting || !_consent) ? null : _submit,
              icon: _submitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.send_rounded),
              label: Text(_submitting
                  ? 'Sending report…'
                  : (_consent
                      ? 'Send report to doctor'
                      : 'Give consent above to continue')),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Suggestions are generated from your inputs and are NOT medical '
            'advice. They only apply once reviewed and approved by '
            '${AppConstants.doctorName}.',
            style: text.bodySmall?.copyWith(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),

          if (requests.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xl),
            Text('Your consultations', style: text.titleMedium),
            const SizedBox(height: AppSpacing.md),
            for (final r in requests) _RequestCard(request: r, text: text),
          ],
        ],
      ),
    );
  }
}

class _RequestCard extends StatelessWidget {
  const _RequestCard({required this.request, required this.text});
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
                      style: text.titleSmall),
                ),
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
            Text(DateFormat('d MMM, h:mm a')
                .format(DateTime.fromMillisecondsSinceEpoch(request.createdAt)),
                style:
                    text.bodySmall?.copyWith(color: AppColors.textSecondary)),
            const SizedBox(height: AppSpacing.sm),
            if (!approved)
              Text('Suggested (pending doctor approval):',
                  style: text.bodySmall
                      ?.copyWith(fontWeight: FontWeight.w700)),
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
                      Icon(Icons.medication_liquid_rounded,
                          size: 16, color: statusColor),
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
            if (approved) ...[
              if (request.eat.isNotEmpty)
                _FoodLine('Eat', request.eat, AppColors.success, text),
              if (request.avoid.isNotEmpty)
                _FoodLine('Avoid', request.avoid, AppColors.error, text),
              () {
                final benefits = benefitsFor(request.conditions);
                if (benefits.isEmpty) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text('Benefits: ${benefits.join(' · ')}',
                      style: text.bodySmall
                          ?.copyWith(color: AppColors.textSecondary)),
                );
              }(),
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

class _FoodLine extends StatelessWidget {
  const _FoodLine(this.label, this.items, this.color, this.text);
  final String label;
  final List<String> items;
  final Color color;
  final TextTheme text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: RichText(
        text: TextSpan(
          style: text.bodySmall?.copyWith(color: AppColors.textSecondary),
          children: [
            TextSpan(
                text: '$label: ',
                style:
                    TextStyle(color: color, fontWeight: FontWeight.w800)),
            TextSpan(text: items.join(', ')),
          ],
        ),
      ),
    );
  }
}
