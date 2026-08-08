import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';

/// Transformation-story banner images, shown once right after a participant logs
/// in (before Home). Save your images in assets/images/ with these names. If a
/// file is missing, that slide shows a tasteful placeholder so the app still
/// builds. Provide 5 or 6 — to use fewer, delete lines from this list.
const List<String> kTransformationIntroBanners = [
  'assets/images/transformation_story_1.png',
  'assets/images/transformation_story_2.png',
  'assets/images/transformation_story_3.png',
  'assets/images/transformation_story_4.png',
  'assets/images/transformation_story_5.png',
  'assets/images/transformation_story_6.png',
];

/// The final "the next transformation could be yours" banner — also your own
/// image. If it's missing, a built-in card is shown as a fallback only.
const String kTransformationNextBanner =
    'assets/images/transformation_next_is_you.png';

/// Post-login carousel: real transformation stories, ending on a "your
/// transformation could be next" call to action, then on to Home.
class TransformationIntroScreen extends StatefulWidget {
  const TransformationIntroScreen({super.key});

  @override
  State<TransformationIntroScreen> createState() =>
      _TransformationIntroScreenState();
}

class _TransformationIntroScreenState extends State<TransformationIntroScreen> {
  final PageController _controller = PageController();
  int _index = 0;

  // Image banners + one final call-to-action slide.
  int get _pageCount => kTransformationIntroBanners.length + 1;
  bool get _isLast => _index == _pageCount - 1;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _goHome() => context.go(Routes.home);

  void _next() {
    if (_isLast) {
      _goHome();
    } else {
      _controller.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _goHome,
                child: const Text('Skip'),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _pageCount,
                onPageChanged: (i) => setState(() => _index = i),
                itemBuilder: (context, i) {
                  if (i < kTransformationIntroBanners.length) {
                    return _ImageBanner(
                      path: kTransformationIntroBanners[i],
                      fallback: _PlaceholderBanner(index: i),
                    );
                  }
                  return const _ImageBanner(
                    path: kTransformationNextBanner,
                    fallback: _NextIsYouSlide(),
                  );
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (int i = 0; i < _pageCount; i++)
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
                child: Text(_isLast ? 'Enter Dayjoy Fit90' : 'Continue'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ImageBanner extends StatelessWidget {
  const _ImageBanner({required this.path, required this.fallback});
  final String path;
  final Widget fallback;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      child: Image.asset(
        path,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => fallback,
      ),
    );
  }
}

/// Shown when a story image file hasn't been added yet.
class _PlaceholderBanner extends StatelessWidget {
  const _PlaceholderBanner({required this.index});
  final int index;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                gradient: AppColors.brandGradient,
                borderRadius: BorderRadius.circular(AppRadius.lg),
              ),
              child: const Icon(Icons.auto_awesome_rounded,
                  color: Colors.white, size: 56),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text('Transformation story ${index + 1}',
                style: text.titleLarge, textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.sm),
            Text('Add transformation_story_${index + 1}.png to assets/images/',
                style:
                    text.bodySmall?.copyWith(color: AppColors.textSecondary),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

/// The final call-to-action slide.
class _NextIsYouSlide extends StatelessWidget {
  const _NextIsYouSlide();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Center(
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.xxl),
          decoration: BoxDecoration(
            gradient: AppColors.mixGradient,
            borderRadius: AppRadius.card,
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.30),
                blurRadius: 30,
                offset: const Offset(0, 16),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.emoji_events_rounded,
                  color: Colors.white, size: 72),
              const SizedBox(height: AppSpacing.xl),
              const Text(
                'The next transformation\ncould be YOURS',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Your 90-day journey starts today. Show up daily, and let\'s '
                'write your story.',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: Colors.white.withOpacity(0.92), height: 1.4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
