import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../l10n/gen/app_localizations.dart';

class _Visual {
  const _Visual(this.icon, this.color);
  final IconData icon;
  final Color color;
}

const List<_Visual> _visuals = [
  _Visual(Icons.self_improvement_rounded, AppColors.taskYoga),
  _Visual(Icons.local_fire_department_rounded, AppColors.accent),
  _Visual(Icons.favorite_rounded, AppColors.primary),
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
    if (_index < _visuals.length - 1) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
      );
    } else {
      context.go(Routes.login);
    }
  }

  String _title(AppLocalizations l, int i) =>
      [l.onboardTitle1, l.onboardTitle2, l.onboardTitle3][i];
  String _body(AppLocalizations l, int i) =>
      [l.onboardBody1, l.onboardBody2, l.onboardBody3][i];

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final l = AppLocalizations.of(context);
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => context.go(Routes.login),
                child: Text(l.actionSkip),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _visuals.length,
                onPageChanged: (i) => setState(() => _index = i),
                itemBuilder: (context, i) {
                  final _Visual v = _visuals[i];
                  return Padding(
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 180,
                          height: 180,
                          decoration: BoxDecoration(
                            color: v.color.withOpacity(0.12),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(v.icon, size: 88, color: v.color),
                        ),
                        const SizedBox(height: AppSpacing.xxl),
                        Text(_title(l, i),
                            style: text.headlineSmall,
                            textAlign: TextAlign.center),
                        const SizedBox(height: AppSpacing.md),
                        Text(_body(l, i),
                            style: text.bodyMedium,
                            textAlign: TextAlign.center),
                      ],
                    ),
                  );
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (int i = 0; i < _visuals.length; i++)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: i == _index ? 22 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: i == _index
                          ? AppColors.primary
                          : AppColors.primary.withOpacity(0.25),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: FilledButton(
                onPressed: _next,
                child: Text(_index == _visuals.length - 1
                    ? l.actionGetStarted
                    : l.actionContinue),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
