import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../shared/widgets/glass_card.dart';
import '../../shared/widgets/section_header.dart';
import '../../state/supplement_chart_data.dart';
import '../../state/supplement_provider.dart';

/// Doctor's review: edit suggested Dayjoy supplements, dosage, foods, then
/// approve the consultation.
class SupplementReviewScreen extends ConsumerStatefulWidget {
  const SupplementReviewScreen({super.key, required this.request});
  final SupplementRequest request;

  @override
  ConsumerState<SupplementReviewScreen> createState() =>
      _SupplementReviewScreenState();
}

class _SupplementReviewScreenState
    extends ConsumerState<SupplementReviewScreen> {
  late List<SupplementItem> _items;
  late List<TextEditingController> _dosage;
  late List<String> _eat;
  late List<String> _avoid;
  late final TextEditingController _note;

  @override
  void initState() {
    super.initState();
    _items = widget.request.items
        .map((e) => SupplementItem(product: e.product, dosage: e.dosage))
        .toList();
    _dosage = [
      for (final it in _items) TextEditingController(text: it.dosage)
    ];
    _eat = [...widget.request.eat];
    _avoid = [...widget.request.avoid];
    _note = TextEditingController(text: widget.request.doctorNote);
  }

  @override
  void dispose() {
    for (final c in _dosage) {
      c.dispose();
    }
    _note.dispose();
    super.dispose();
  }

  void _addProduct() {
    final existing = _items.map((e) => e.product).toSet();
    final options =
        kProductDosage.keys.where((p) => !existing.contains(p)).toList();
    if (options.isEmpty) return;
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      backgroundColor: AppColors.surfaceOf(context),
      builder: (ctx) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
              maxHeight: MediaQuery.of(ctx).size.height * 0.7),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.sm),
                child: Text('Add a supplement',
                    style: Theme.of(ctx).textTheme.titleMedium),
              ),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  padding: EdgeInsets.zero,
                  children: [
                    for (final p in options)
                      ListTile(
                        leading: const Icon(Icons.medication_liquid_rounded,
                            color: AppColors.primary),
                        title: Text(p),
                        subtitle: Text(infoFor(p)?.tagline ?? dosageFor(p)),
                        onTap: () {
                          Navigator.pop(ctx);
                          setState(() {
                            _items.add(SupplementItem(
                                product: p, dosage: dosageFor(p)));
                            _dosage.add(
                                TextEditingController(text: dosageFor(p)));
                          });
                        },
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showProductInfo(String product, int index) {
    final info = infoFor(product);
    if (info == null) return;
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      backgroundColor: AppColors.surfaceOf(context),
      builder: (ctx) => SafeArea(
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
                Text(product, style: Theme.of(ctx).textTheme.titleLarge),
              Text(info.tagline,
                  style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                      fontStyle: FontStyle.italic)),
              const SizedBox(height: AppSpacing.md),
              Text('Key benefits',
                  style: Theme.of(ctx)
                      .textTheme
                      .titleSmall
                      ?.copyWith(color: AppColors.primary)),
              const SizedBox(height: 4),
              for (final b in info.benefits)
                Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('•  '),
                      Expanded(
                          child: Text(b,
                              style: Theme.of(ctx).textTheme.bodySmall)),
                    ],
                  ),
                ),
              if (info.ingredients.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.sm),
                Text('Ingredients: ${info.ingredients}',
                    style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary)),
              ],
              const SizedBox(height: AppSpacing.md),
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
                        child: Text('Recommended: ${info.dosage}',
                            style: Theme.of(ctx).textTheme.bodySmall)),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              SizedBox(
                width: double.infinity,
                child: FilledButton.tonal(
                  onPressed: () {
                    _dosage[index].text = info.dosage;
                    Navigator.pop(ctx);
                  },
                  child: const Text('Use recommended dosage'),
                ),
              ),
            ],
          ),
          ),
        ),
      ),
    );
  }

  Future<void> _addFood(List<String> list, String title) async {
    final ctrl = TextEditingController();
    final added = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'e.g. Green vegetables'),
          onSubmitted: (v) => Navigator.pop(ctx, v.trim()),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
              child: const Text('Add')),
        ],
      ),
    );
    ctrl.dispose();
    if (added != null && added.isNotEmpty) {
      setState(() => list.add(added));
    }
  }

  void _approve() {
    // Capture messenger & navigator BEFORE popping — after Navigator.pop the
    // element is deactivated, and ScaffoldMessenger.of(context) would throw
    // ("Looking up a deactivated widget's ancestor is unsafe"), surfacing as an
    // un-closeable error overlay.
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    for (int i = 0; i < _items.length; i++) {
      _items[i].dosage = _dosage[i].text.trim();
    }
    final updated = SupplementRequest(
      id: widget.request.id,
      kind: widget.request.kind,
      conditions: widget.request.conditions,
      aiConcerns: widget.request.aiConcerns,
      comment: widget.request.comment,
      bodyArea: widget.request.bodyArea,
      items: _items,
      eat: _eat,
      avoid: _avoid,
      reportPhoto: widget.request.reportPhoto,
      status: 'approved',
      doctorNote: _note.text.trim(),
      createdAt: widget.request.createdAt,
      approvedAt: DateTime.now().millisecondsSinceEpoch,
    );
    ref.read(supplementRequestsProvider.notifier).replace(updated);
    messenger.showSnackBar(
      const SnackBar(
        content: Text('✅ Supplement consultation approved'),
        backgroundColor: AppColors.success,
      ),
    );
    navigator.pop();
  }

  void _viewReport(String data) {
    showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(AppSpacing.lg),
        child: GestureDetector(
          onTap: () => Navigator.pop(ctx),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.md),
            child: Image.memory(base64Decode(data), fit: BoxFit.contain),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final req = widget.request;
    final TextTheme text = Theme.of(context).textTheme;

    final bool isSkin = req.kind == 'skin';
    return Scaffold(
      appBar: AppBar(
          title: Text(isSkin ? 'Review skin routine' : 'Review consultation')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg, AppSpacing.md, AppSpacing.lg, 120),
        children: [
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text('Reported issues', style: text.titleSmall),
                    if (req.bodyArea != null && req.bodyArea!.isNotEmpty) ...[
                      const Spacer(),
                      Chip(
                        avatar: const Icon(Icons.accessibility_new_rounded,
                            size: 14, color: AppColors.primary),
                        label: Text(req.bodyArea!),
                        visualDensity: VisualDensity.compact,
                        backgroundColor: AppColors.primary.withOpacity(0.10),
                      ),
                    ],
                  ],
                ),
                if (req.aiConcerns.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Row(
                      children: [
                        const Icon(Icons.auto_awesome_rounded,
                            size: 13, color: AppColors.taskYoga),
                        const SizedBox(width: 4),
                        Text('✦ = flagged by AI screening',
                            style: text.bodySmall
                                ?.copyWith(color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                const SizedBox(height: AppSpacing.xs),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.xs,
                  children: [
                    for (final c in req.conditions)
                      Chip(
                        avatar: req.aiConcerns.contains(c)
                            ? const Icon(Icons.auto_awesome_rounded,
                                size: 14, color: AppColors.taskYoga)
                            : null,
                        label: Text(c),
                        visualDensity: VisualDensity.compact,
                        backgroundColor: AppColors.info.withOpacity(0.12),
                      ),
                  ],
                ),
                if (req.comment != null && req.comment!.trim().isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceMuted,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: Text('Patient note: ${req.comment}',
                        style: text.bodySmall),
                  ),
                ],
                if (req.reportPhoto != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  GestureDetector(
                    onTap: () => _viewReport(req.reportPhoto!),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      child: Image.memory(base64Decode(req.reportPhoto!),
                          height: 180,
                          width: double.infinity,
                          fit: BoxFit.cover),
                    ),
                  ),
                  Text('Tap the report to view full size',
                      style: text.bodySmall
                          ?.copyWith(color: AppColors.textSecondary)),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          Row(
            children: [
              Expanded(
                  child: SectionHeader(
                      title: isSkin
                          ? 'Skincare & supplements'
                          : 'Dayjoy supplements')),
              TextButton.icon(
                onPressed: _addProduct,
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Add'),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          for (int i = 0; i < _items.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: GlassCard(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(_items[i].product,
                                    style: text.titleSmall
                                        ?.copyWith(color: AppColors.primary)),
                              ),
                              if (infoFor(_items[i].product) != null)
                                InkWell(
                                  onTap: () =>
                                      _showProductInfo(_items[i].product, i),
                                  child: const Padding(
                                    padding: EdgeInsets.all(2),
                                    child: Icon(Icons.info_outline_rounded,
                                        size: 18, color: AppColors.info),
                                  ),
                                ),
                            ],
                          ),
                          if (infoFor(_items[i].product) != null)
                            Text(infoFor(_items[i].product)!.tagline,
                                style: text.bodySmall?.copyWith(
                                    color: AppColors.textSecondary)),
                          TextField(
                            controller: _dosage[i],
                            style: text.bodySmall,
                            decoration: const InputDecoration(
                              isDense: true,
                              labelText: 'Dosage & timing',
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded,
                          color: AppColors.error),
                      onPressed: () => setState(() {
                        _items.removeAt(i);
                        _dosage.removeAt(i).dispose();
                      }),
                    ),
                  ],
                ),
              ),
            ),

          const SizedBox(height: AppSpacing.md),
          _FoodEditor(
            title: 'Food to eat',
            items: _eat,
            color: AppColors.success,
            onAdd: () => _addFood(_eat, 'Add food to eat'),
            onRemove: (v) => setState(() => _eat.remove(v)),
          ),
          const SizedBox(height: AppSpacing.md),
          _FoodEditor(
            title: 'Food to avoid',
            items: _avoid,
            color: AppColors.error,
            onAdd: () => _addFood(_avoid, 'Add food to avoid'),
            onRemove: (v) => setState(() => _avoid.remove(v)),
          ),

          const SizedBox(height: AppSpacing.lg),
          TextField(
            controller: _note,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Doctor\'s note (optional)',
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: FilledButton.icon(
            onPressed: _approve,
            icon: const Icon(Icons.verified_rounded),
            label: Text(req.isApproved
                ? 'Update approved consultation'
                : 'Approve consultation'),
          ),
        ),
      ),
    );
  }
}

class _FoodEditor extends StatelessWidget {
  const _FoodEditor({
    required this.title,
    required this.items,
    required this.color,
    required this.onAdd,
    required this.onRemove,
  });
  final String title;
  final List<String> items;
  final Color color;
  final VoidCallback onAdd;
  final void Function(String) onRemove;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.circle, size: 10, color: color),
              const SizedBox(width: 6),
              Text(title, style: text.titleSmall),
              const Spacer(),
              TextButton.icon(
                onPressed: onAdd,
                icon: const Icon(Icons.add_rounded, size: 16),
                label: const Text('Add'),
              ),
            ],
          ),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.xs,
            children: [
              for (final v in items)
                Chip(
                  label: Text(v),
                  visualDensity: VisualDensity.compact,
                  backgroundColor: color.withOpacity(0.12),
                  onDeleted: () => onRemove(v),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
