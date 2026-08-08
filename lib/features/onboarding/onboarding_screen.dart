import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';

/// One intro slide. Each slide shows a branded banner IMAGE from assets/images/.
/// If an image file is missing, the app falls back to the text layout below, so
/// it always builds. To change a banner, replace its image file (same name).
class OnboardSlide {
  const OnboardSlide({
    required this.icon,
    required this.gradient,
    required this.title,
    required this.body,
    this.image,
  });

  final IconData icon;
  final List<Color> gradient;
  final String title;
  final String body;

  /// Full-bleed banner image (preferred). Falls back to icon+title+body.
  final String? image;
}

/// The four intro banners, in the order they appear.
const List<OnboardSlide> kOnboardSlides = [
  OnboardSlide(
    image: 'assets/images/onboarding_1_welcome.png',
    icon: Icons.spa_rounded,
    gradient: [AppColors.primary, AppColors.secondary],
    title: 'Welcome to Dayjoy Fit90',
    body:
        'The 90-Day Transformation Challenge. Your journey to a healthier, '
        'happier you starts here.',
  ),
  OnboardSlide(
    image: 'assets/images/onboarding_2_streak.png',
    icon: Icons.local_fire_department_rounded,
    gradient: [AppColors.orange, AppColors.orangeDark],
    title: 'Build an Unbreakable Streak',
    body:
        'Small daily actions, big transformations. Complete daily tasks, earn '
        '100 points a day, unlock badges and climb the leaderboard.',
  ),
  OnboardSlide(
    image: 'assets/images/onboarding_3_rituals.png',
    icon: Icons.self_improvement_rounded,
    gradient: [AppColors.primary, AppColors.secondary],
    title: 'Six Daily Rituals',
    body:
        'Yoga, nutrition, fitness, daily water, 10,000 steps and a night '
        'shake — simple rituals, powerful results.',
  ),
  OnboardSlide(
    image: 'assets/images/onboarding_4_coach.png',
    icon: Icons.health_and_safety_rounded,
    gradient: [AppColors.orange, AppColors.orangeDark],
    title: 'Coach & Doctor on Call',
    body:
        'Book Ms. Sonali for fitness guidance and consult Dr. Prachita for '
        'your health concerns — whenever you need it.',
  ),
];

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int _index = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _next() {
    if (_index < kOnboardSlides.length - 1) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
      );
    } else {
      context.go(Routes.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isLast = _index == kOnboardSlides.length - 1;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => context.go(Routes.login),
                child: const Text('Skip'),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: kOnboardSlides.length,
                onPageChanged: (i) => setState(() => _index = i),
                itemBuilder: (context, i) {
                  final OnboardSlide s = kOnboardSlides[i];
                  if (s.image != null) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                      child: Image.asset(
                        s.image!,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => _textSlide(context, s),
                      ),
                    );
                  }
                  return _textSlide(context, s);
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (int i = 0; i < kOnboardSlides.length; i++)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: i == _index ? 22 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: i == _index
                          ? AppColors.primary
                          : AppColors.primary.withOpacity(0.22),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: FilledButton(
                onPressed: _next,
                child: Text(isLast ? 'Get Started' : 'Continue'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Fallback slide used when a banner image file isn't present.
  Widget _textSlide(BuildContext context, OnboardSlide s) {
    final TextTheme text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 190,
            height: 190,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: s.gradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: s.gradient.last.withOpacity(0.35),
                  blurRadius: 34,
                  offset: const Offset(0, 16),
                ),
              ],
            ),
            child: Icon(s.icon, size: 92, color: Colors.white),
          ),
          const SizedBox(height: AppSpacing.xxl),
          Text(s.title, style: text.headlineSmall, textAlign: TextAlign.center),
          const SizedBox(height: AppSpacing.md),
          Text(s.body, style: text.bodyMedium, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
