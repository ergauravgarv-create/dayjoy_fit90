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
        child: Padding(
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
      );
    },
  );
}

class SupplementConsultScreen extends ConsumerStatefulWidget {
  const SupplementConsultScreen({super.key});

  @override
  ConsumerState<SupplementConsultScreen> createState() =>
      _SupplementConsultScreenState();
}

class _SupplementConsultScreenState
    extends ConsumerState<SupplementConsultScreen> {
  final Set<String> _selected = {};
  String? _reportPhoto;
  bool _busy = false;

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

  void _submit() {
    if (_selected.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one health issue.')),
      );
      return;
    }
    final s = suggestFor(_selected.toList());
    final req = SupplementRequest(
      id: 's_${DateTime.now().millisecondsSinceEpoch}',
      conditions: _selected.toList(),
      items: s.items,
      eat: s.eat,
      avoid: s.avoid,
      reportPhoto: _reportPhoto,
      createdAt: DateTime.now().millisecondsSinceEpoch,
    );
    ref.read(supplementRequestsProvider.notifier).add(req);
    setState(() {
      _selected.clear();
      _reportPhoto = null;
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
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _submit,
              icon: const Icon(Icons.medical_information_rounded),
              label: const Text('Get Dayjoy suggestion & send to doctor'),
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
