import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../data/models/weekly_checkin.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../shared/widgets/glass_card.dart';
import '../../shared/widgets/section_header.dart';
import '../../state/health_providers.dart';
import '../../state/providers.dart';
import '../../state/repository_providers.dart';

class WeeklyCheckInScreen extends ConsumerStatefulWidget {
  const WeeklyCheckInScreen({super.key});

  @override
  ConsumerState<WeeklyCheckInScreen> createState() =>
      _WeeklyCheckInScreenState();
}

class _WeeklyCheckInScreenState extends ConsumerState<WeeklyCheckInScreen> {
  final _weight = TextEditingController();
  final _waist = TextEditingController();
  final _challenges = TextEditingController();
  final _notes = TextEditingController();

  int _energy = 3, _sleep = 3, _digestion = 3, _mood = 3;
  bool _frontCaptured = false, _sideCaptured = false;
  String? _frontUrl, _sideUrl;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final p = ref.read(participantProvider);
    if (p != null) {
      _weight.text = p.currentWeightKg.toString();
      _waist.text = p.waistCm?.toString() ?? '';
    }
  }

  @override
  void dispose() {
    _weight.dispose();
    _waist.dispose();
    _challenges.dispose();
    _notes.dispose();
    super.dispose();
  }

  int get _weekNumber {
    final day = ref.read(participantProvider)?.currentDay ?? 1;
    return ((day - 1) ~/ 7) + 1;
  }

  Future<void> _capture(bool front) async {
    final result = await ref.read(cameraServiceProvider).capturePhoto();
    if (result == null || !mounted) return;
    setState(() => front ? _frontCaptured = true : _sideCaptured = true);
    final bytes = await ref.read(imageCompressionProvider).compress(result.bytes);
    final url = await ref.read(imageUploadServiceProvider).upload(
          bytes,
          storageKey: 'progress/${front ? 'front' : 'side'}',
          mimeType: result.mimeType,
        );
    if (!mounted) return;
    setState(() => front ? _frontUrl = url : _sideUrl = url);
  }

  Future<void> _submit() async {
    final weight = double.tryParse(_weight.text) ?? 0;
    final waist = double.tryParse(_waist.text) ?? 0;
    if (weight <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(AppLocalizations.of(context).enterWeightError)));
      return;
    }
    setState(() => _saving = true);

    final uid = ref.read(authUidProvider) ?? 'demo-user';
    final checkin = WeeklyCheckIn(
      weekNumber: _weekNumber,
      weightKg: weight,
      waistCm: waist,
      frontPhotoUrl: _frontUrl,
      sidePhotoUrl: _sideUrl,
      energy: _energy,
      sleep: _sleep,
      digestion: _digestion,
      mood: _mood,
      challenges: _challenges.text.trim().isEmpty ? null : _challenges.text.trim(),
      notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
      createdAt: DateTime.now(),
    );

    await ref.read(weeklyCheckinRepositoryProvider).submit(uid, checkin);
    await ref.read(participantProvider.notifier).updateWeight(weight);

    if (!mounted) return;
    setState(() => _saving = false);
    await _showSummary(weight);
    if (mounted) Navigator.of(context).maybePop();
  }

  Future<void> _showSummary(double newWeight) async {
    final l = AppLocalizations.of(context);
    final p = ref.read(participantProvider);
    final start = p?.startWeightKg ?? newWeight;
    final heightM = (p?.heightCm ?? 0) / 100;
    final bmi = heightM > 0 ? newWeight / (heightM * heightM) : 0;
    final lost = (start - newWeight).clamp(0, 999);

    await showDialog<void>(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: GlassCard(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 76,
                height: 76,
                decoration: const BoxDecoration(
                    gradient: AppColors.brandGradient, shape: BoxShape.circle),
                child: const Icon(Icons.insights_rounded,
                    color: Colors.white, size: 40),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(l.weekLoggedTitle(_weekNumber),
                  style: Theme.of(context).textTheme.headlineSmall,
                  textAlign: TextAlign.center),
              const SizedBox(height: AppSpacing.md),
              _summaryRow(l.summaryWeightLost,
                  '${lost.toStringAsFixed(1)} kg', AppColors.success),
              _summaryRow(
                  l.summaryCurrentBmi, bmi.toStringAsFixed(1), AppColors.primary),
              _summaryRow(l.summaryCurrentWeight,
                  '${newWeight.toStringAsFixed(1)} kg', AppColors.info),
              const SizedBox(height: AppSpacing.lg),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(l.actionGreat),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _summaryRow(String label, String value, Color color) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: Theme.of(context).textTheme.bodyMedium),
            Text(value,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(color: color)),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l.checkinTitle(_weekNumber))),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.xxl),
        children: [
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(child: _numField(l.fieldWeightKg, _weight)),
              const SizedBox(width: AppSpacing.md),
              Expanded(child: _numField(l.fieldWaistCm, _waist)),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),

          SectionHeader(title: l.progressPhotos),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: _PhotoCapture(
                  label: l.photoFront,
                  captured: _frontCaptured,
                  uploaded: _frontUrl != null,
                  onTap: () => _capture(true),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _PhotoCapture(
                  label: l.photoSide,
                  captured: _sideCaptured,
                  uploaded: _sideUrl != null,
                  onTap: () => _capture(false),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),

          SectionHeader(title: l.howWasWeek),
          const SizedBox(height: AppSpacing.md),
          GlassCard(
            child: Column(
              children: [
                _RatingRow(
                    label: l.ratingEnergy,
                    value: _energy,
                    onChanged: (v) => setState(() => _energy = v)),
                _RatingRow(
                    label: l.ratingSleep,
                    value: _sleep,
                    onChanged: (v) => setState(() => _sleep = v)),
                _RatingRow(
                    label: l.ratingDigestion,
                    value: _digestion,
                    onChanged: (v) => setState(() => _digestion = v)),
                _RatingRow(
                    label: l.ratingMood,
                    value: _mood,
                    onChanged: (v) => setState(() => _mood = v),
                    last: true),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          _multiField(l.fieldChallenges, _challenges),
          _multiField(l.fieldProgressNotes, _notes),
          const SizedBox(height: AppSpacing.md),

          FilledButton(
            onPressed: _saving ? null : _submit,
            child: _saving
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : Text(l.submitCheckin),
          ),
        ],
      ),
    );
  }

  Widget _numField(String label, TextEditingController c) => TextField(
        controller: c,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
        decoration: InputDecoration(labelText: label),
      );

  Widget _multiField(String label, TextEditingController c) => Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.md),
        child: TextField(
          controller: c,
          maxLines: 2,
          decoration: InputDecoration(labelText: label),
        ),
      );
}

class _PhotoCapture extends StatelessWidget {
  const _PhotoCapture({
    required this.label,
    required this.captured,
    required this.uploaded,
    required this.onTap,
  });

  final String label;
  final bool captured;
  final bool uploaded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return GlassCard(
      onTap: onTap,
      child: SizedBox(
        height: 120,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              uploaded
                  ? Icons.check_circle_rounded
                  : (captured ? Icons.cloud_upload_rounded : Icons.add_a_photo_rounded),
              size: 34,
              color: uploaded ? AppColors.success : AppColors.primary,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(l.photoLabel(label),
                style: Theme.of(context).textTheme.titleSmall),
            Text(
              uploaded
                  ? l.photoUploaded
                  : (captured ? l.photoUploading : l.photoTapCapture),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _RatingRow extends StatelessWidget {
  const _RatingRow({
    required this.label,
    required this.value,
    required this.onChanged,
    this.last = false,
  });

  final String label;
  final int value;
  final ValueChanged<int> onChanged;
  final bool last;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          child: Row(
            children: [
              SizedBox(
                width: 84,
                child: Text(label,
                    style: Theme.of(context).textTheme.bodyMedium),
              ),
              const Spacer(),
              for (int i = 1; i <= 5; i++)
                GestureDetector(
                  onTap: () => onChanged(i),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Icon(
                      i <= value ? Icons.circle : Icons.circle_outlined,
                      size: 22,
                      color: i <= value
                          ? AppColors.primary
                          : AppColors.textSecondary.withOpacity(0.4),
                    ),
                  ),
                ),
            ],
          ),
        ),
        if (!last) const Divider(height: 1),
      ],
    );
  }
}
