import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../shared/widgets/glass_card.dart';
import '../../state/locale_provider.dart';

class _Lang {
  const _Lang(this.code, this.native, this.english);
  final String code;
  final String native;
  final String english;
}

const List<_Lang> _languages = [
  _Lang('en', 'English', 'English'),
  _Lang('hi', 'हिंदी', 'Hindi'),
  _Lang('mr', 'मराठी', 'Marathi'),
  _Lang('gu', 'ગુજરાતી', 'Gujarati'),
  _Lang('bn', 'বাংলা', 'Bengali'),
  _Lang('ta', 'தமிழ்', 'Tamil'),
  _Lang('te', 'తెలుగు', 'Telugu'),
  _Lang('kn', 'ಕನ್ನಡ', 'Kannada'),
  _Lang('or', 'ଓଡ଼ିଆ', 'Odia'),
];

/// Shown once when the app opens: pick the app language before signing in.
class LanguageSelectScreen extends ConsumerStatefulWidget {
  const LanguageSelectScreen({super.key});

  @override
  ConsumerState<LanguageSelectScreen> createState() =>
      _LanguageSelectScreenState();
}

class _LanguageSelectScreenState extends ConsumerState<LanguageSelectScreen> {
  String _selected = 'en';

  void _continue() {
    ref.read(localeProvider.notifier).set(Locale(_selected));
    context.go(Routes.onboarding);
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: AppSpacing.page,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppSpacing.xxl),
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  gradient: AppColors.mixGradient,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: const Icon(Icons.translate_rounded,
                    color: Colors.white, size: 34),
              ),
              const SizedBox(height: AppSpacing.xl),
              Text('Choose your language', style: text.displaySmall),
              const SizedBox(height: AppSpacing.sm),
              Text('अपनी भाषा चुनें · আপনার ভাষা · உங்கள் மொழி',
                  style: text.bodyMedium),
              const SizedBox(height: AppSpacing.xl),

              Expanded(
                child: ListView(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  children: [
                    for (final l in _languages) ...[
                      GlassCard(
                        onTap: () => setState(() => _selected = l.code),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(l.native, style: text.titleLarge),
                                  if (l.native != l.english)
                                    Text(l.english, style: text.bodySmall),
                                ],
                              ),
                            ),
                            Container(
                              width: 26,
                              height: 26,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _selected == l.code
                                    ? AppColors.primary
                                    : Colors.transparent,
                                border: Border.all(
                                  color: _selected == l.code
                                      ? AppColors.primary
                                      : AppColors.textSecondary
                                          .withOpacity(0.4),
                                  width: 2,
                                ),
                              ),
                              child: _selected == l.code
                                  ? const Icon(Icons.check_rounded,
                                      size: 16, color: Colors.white)
                                  : null,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                    ],
                  ],
                ),
              ),

              FilledButton(
                onPressed: _continue,
                child: const Text('Continue'),
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
          ),
        ),
      ),
    );
  }
}
