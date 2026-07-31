import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_constants.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../data/models/participant.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../shared/widgets/glass_card.dart';
import '../../state/providers.dart';
import '../../state/repository_providers.dart';

/// Participant registration. When [existing] is null it's the onboarding form
/// (creates the profile then enters the app); otherwise it edits the profile.
class RegistrationScreen extends ConsumerStatefulWidget {
  const RegistrationScreen({super.key, this.existing});

  final Participant? existing;

  @override
  ConsumerState<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends ConsumerState<RegistrationScreen> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _age = TextEditingController();
  final _height = TextEditingController();
  final _startWeight = TextEditingController();
  final _target = TextEditingController();
  final _waist = TextEditingController();
  final _city = TextEditingController();
  final _distributor = TextEditingController();
  final _sponsor = TextEditingController();
  final _health = TextEditingController();
  final _medical = TextEditingController();

  String _gender = 'Male';
  String _food = 'Vegetarian';
  String _activity = 'Moderate';
  bool _consent = false;
  bool _saving = false;
  String? _photoUrl;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final p = widget.existing;
    if (p != null) {
      _name.text = p.name;
      _email.text = p.email ?? '';
      _age.text = p.age.toString();
      _height.text = p.heightCm.toString();
      _startWeight.text = p.startWeightKg.toString();
      _target.text = p.targetWeightKg.toString();
      _waist.text = p.waistCm?.toString() ?? '';
      _city.text = p.city;
      _distributor.text = p.distributorName ?? '';
      _sponsor.text = p.sponsorId ?? '';
      _health.text = p.healthConditions ?? '';
      _gender = p.gender;
      _food = p.foodPreference;
      _activity = p.physicalActivityLevel ?? 'Moderate';
      _photoUrl = p.photoUrl;
      _consent = true;
    }
  }

  @override
  void dispose() {
    for (final c in [
      _name, _email, _age, _height, _startWeight, _target, _waist,
      _city, _distributor, _sponsor, _health, _medical,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  String? _validate() {
    final l = AppLocalizations.of(context);
    if (_name.text.trim().isEmpty) return l.valName;
    if ((int.tryParse(_age.text) ?? 0) <= 0) return l.valAge;
    if ((double.tryParse(_height.text) ?? 0) <= 0) return l.valHeight;
    if ((double.tryParse(_startWeight.text) ?? 0) <= 0) return l.valStartWeight;
    if ((double.tryParse(_target.text) ?? 0) <= 0) return l.valTarget;
    if (_city.text.trim().isEmpty) return l.valCity;
    if (!_consent) return l.valConsent;
    return null;
  }

  Future<void> _submit() async {
    final error = _validate();
    if (error != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error)));
      return;
    }
    setState(() => _saving = true);

    final auth = ref.read(authControllerProvider);
    final uid = widget.existing?.id ?? auth.uid ?? 'demo-user';
    final mobile = widget.existing?.mobile ?? auth.phone ?? '';
    final start = double.tryParse(_startWeight.text) ?? 0;

    String? clean(TextEditingController c) =>
        c.text.trim().isEmpty ? null : c.text.trim();

    final participant = Participant(
      id: uid,
      name: _name.text.trim(),
      mobile: mobile,
      email: clean(_email),
      photoUrl: _photoUrl,
      age: int.tryParse(_age.text) ?? 0,
      gender: _gender,
      heightCm: double.tryParse(_height.text) ?? 0,
      startWeightKg: widget.existing?.startWeightKg ?? start,
      currentWeightKg: widget.existing?.currentWeightKg ?? start,
      targetWeightKg: double.tryParse(_target.text) ?? 0,
      city: _city.text.trim(),
      distributorName: clean(_distributor),
      sponsorId: clean(_sponsor),
      role: widget.existing?.role ?? UserRole.participant,
      foodPreference: _food,
      waistCm: double.tryParse(_waist.text),
      startDate: widget.existing?.startDate ?? DateTime.now(),
      streak: widget.existing?.streak ?? 0,
      totalPoints: widget.existing?.totalPoints ?? 0,
      physicalActivityLevel: _activity,
      healthConditions: clean(_health),
    );

    await ref.read(participantRepositoryProvider).upsert(participant);
    // Detailed medical history is sensitive — in Firebase mode write it to the
    // participants/{uid}/medical subcollection instead of the profile doc.
    ref.invalidate(participantProvider);

    if (!mounted) return;
    if (_isEdit) {
      Navigator.of(context).pop();
    } else {
      ref.read(authControllerProvider.notifier).markRegistered();
      context.go(Routes.home);
    }
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final l = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? l.regEditTitle : l.regCreateTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.xxl),
        children: [
          const SizedBox(height: AppSpacing.md),
          Center(
            child: Column(
              children: [
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 44,
                      backgroundColor: AppColors.primary.withOpacity(0.15),
                      child: _photoUrl == null
                          ? const Icon(Icons.person_rounded,
                              size: 44, color: AppColors.primary)
                          : const Icon(Icons.check_rounded,
                              size: 40, color: AppColors.success),
                    ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: GestureDetector(
                        onTap: () => setState(() => _photoUrl = 'captured'),
                        child: const CircleAvatar(
                          radius: 15,
                          backgroundColor: AppColors.primary,
                          child: Icon(Icons.photo_camera_rounded,
                              size: 16, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(l.regPhotoOptional, style: text.bodySmall),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          _section(l.secAboutYou),
          _field(l.fieldFullName, _name),
          _field(l.fieldEmailOptional, _email,
              keyboard: TextInputType.emailAddress),
          Row(
            children: [
              Expanded(
                  child:
                      _field(l.fieldAge, _age, keyboard: TextInputType.number)),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                  child: _chips(l.fieldGender, const ['Male', 'Female', 'Other'],
                      _gender, (v) => setState(() => _gender = v), (v) {
                return switch (v) {
                  'Male' => l.genderMale,
                  'Female' => l.genderFemale,
                  _ => l.genderOther,
                };
              })),
            ],
          ),

          const SizedBox(height: AppSpacing.lg),
          _section(l.secBodyGoals),
          Row(
            children: [
              Expanded(child: _field(l.fieldHeightCm, _height,
                  keyboard: TextInputType.number)),
              const SizedBox(width: AppSpacing.md),
              Expanded(child: _field(l.fieldWaistCm, _waist,
                  keyboard: TextInputType.number)),
            ],
          ),
          Row(
            children: [
              Expanded(child: _field(l.fieldStartWeight, _startWeight,
                  keyboard: TextInputType.number, enabled: !_isEdit)),
              const SizedBox(width: AppSpacing.md),
              Expanded(child: _field(l.fieldTargetWeight, _target,
                  keyboard: TextInputType.number)),
            ],
          ),
          _chips(l.fieldFoodPreference,
              const ['Vegetarian', 'Non-Vegetarian'], _food,
              (v) => setState(() => _food = v),
              (v) => v == 'Vegetarian' ? l.foodVeg : l.foodNonVeg),
          const SizedBox(height: AppSpacing.md),
          _chips(
              l.fieldActivityLevel,
              const ['Sedentary', 'Light', 'Moderate', 'Active', 'Very active'],
              _activity,
              (v) => setState(() => _activity = v), (v) {
            return switch (v) {
              'Sedentary' => l.actSedentary,
              'Light' => l.actLight,
              'Moderate' => l.actModerate,
              'Active' => l.actActive,
              _ => l.actVeryActive,
            };
          }),

          const SizedBox(height: AppSpacing.lg),
          _section(l.secProgramHealth),
          _field(l.fieldCity, _city),
          _field(l.fieldDistributor, _distributor),
          _field(l.fieldSponsor, _sponsor),
          _field(l.fieldHealthConditions, _health, maxLines: 2),
          _field(l.fieldMedicalHistory, _medical, maxLines: 2),

          const SizedBox(height: AppSpacing.md),
          GlassCard(
            child: Row(
              children: [
                Checkbox(
                  value: _consent,
                  onChanged: (v) => setState(() => _consent = v ?? false),
                ),
                Expanded(
                  child: Text(l.consentText, style: text.bodySmall),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          FilledButton(
            onPressed: _saving ? null : _submit,
            child: _saving
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : Text(_isEdit ? l.actionSave : l.startJourney),
          ),
        ],
      ),
    );
  }

  Widget _section(String title) => Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
        child: Text(title, style: Theme.of(context).textTheme.titleMedium),
      );

  Widget _field(
    String label,
    TextEditingController controller, {
    TextInputType? keyboard,
    int maxLines = 1,
    bool enabled = true,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: TextField(
        controller: controller,
        keyboardType: keyboard,
        maxLines: maxLines,
        enabled: enabled,
        inputFormatters: keyboard == TextInputType.number
            ? [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))]
            : null,
        decoration: InputDecoration(labelText: label),
      ),
    );
  }

  Widget _chips(
    String label,
    List<String> options,
    String selected,
    ValueChanged<String> onSelect,
    String Function(String) display,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.xs,
          children: [
            for (final o in options)
              ChoiceChip(
                label: Text(display(o)),
                selected: selected == o,
                labelStyle: TextStyle(
                  color: selected == o ? Colors.white : AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
                onSelected: (_) => onSelect(o),
              ),
          ],
        ),
      ],
    );
  }
}
