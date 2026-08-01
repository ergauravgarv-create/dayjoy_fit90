import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../shared/widgets/glass_card.dart';
import '../../state/providers.dart';

class _Risk {
  const _Risk(this.icon, this.title, this.detail);
  final IconData icon;
  final String title;
  final String detail;
}

/// Personalised BMI report: the number, where it sits, and the health risks to
/// be aware of — framed to motivate action. Informational, not a diagnosis.
class BmiReportScreen extends ConsumerWidget {
  const BmiReportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = ref.watch(participantProvider);
    final TextTheme text = Theme.of(context).textTheme;

    if (p == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final double bmi = p.bmi;
    final String category = p.bmiCategory;
    final Color color = _categoryColor(category);
    final String summary = _summary(category);
    final List<_Risk> risks = _risksFor(category);

    return Scaffold(
      appBar: AppBar(title: const Text('BMI Report')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, 40),
        children: [
          // Headline card
          GlassCard(
            gradient: LinearGradient(
              colors: [color, color.withOpacity(0.75)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Your BMI',
                    style: text.titleMedium?.copyWith(color: Colors.white70)),
                const SizedBox(height: 2),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(bmi.toStringAsFixed(1),
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 46,
                            fontWeight: FontWeight.w800,
                            height: 1)),
                    const SizedBox(width: 10),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(category,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text('${p.currentWeightKg.round()} kg · '
                    '${p.heightCm.round()} cm',
                    style: const TextStyle(color: Colors.white70)),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Scale
          _BmiScale(bmi: bmi),
          const SizedBox(height: AppSpacing.xl),

          Text('What this means for you', style: text.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          Text(summary, style: text.bodyMedium?.copyWith(height: 1.45)),
          const SizedBox(height: AppSpacing.xl),

          if (risks.isNotEmpty) ...[
            Text(
                category == 'Normal'
                    ? 'Why staying here matters'
                    : 'Health risks to be aware of',
                style: text.titleMedium),
            const SizedBox(height: AppSpacing.md),
            for (final r in risks) _RiskTile(risk: r, color: color),
            const SizedBox(height: AppSpacing.sm),
          ],

          // Motivation
          GlassCard(
            gradient: AppColors.mixGradient,
            child: Row(
              children: [
                const Icon(Icons.emoji_events_rounded,
                    color: Colors.white, size: 30),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    'Your 90-day journey can change these numbers. Small daily '
                    'actions — every day — add up to a healthier you.',
                    style: text.bodyMedium?.copyWith(
                        color: Colors.white, height: 1.4),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'This report is for information and motivation only — it is not a '
            'medical diagnosis. Please consult a doctor for personal advice.',
            style: text.bodySmall?.copyWith(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  static Color _categoryColor(String c) => switch (c) {
        'Underweight' => AppColors.info,
        'Normal' => AppColors.success,
        'Overweight' => AppColors.orange,
        'Obese' => AppColors.error,
        _ => AppColors.textSecondary,
      };

  static String _summary(String c) => switch (c) {
        'Underweight' =>
          'Your BMI is below the healthy range. Being underweight can be just '
              'as challenging as being overweight — the goal is to build '
              'strength and reach a healthy weight steadily.',
        'Normal' =>
          'You are in the healthy BMI range — well done! The focus now is to '
              'stay consistent, build strength and protect your long-term '
              'health.',
        'Overweight' =>
          'Your BMI is above the healthy range. This is an early warning: '
              'acting now — before it climbs further — makes a big difference '
              'and is very achievable in 90 days.',
        'Obese' =>
          'Your BMI is in the obese range, which meaningfully raises the risk '
              'of several health problems. The good news: steady weight loss '
              'reduces these risks quickly, and your 90-day plan is built for '
              'exactly that.',
        _ =>
          'Add your height and weight in your profile to see your BMI report.',
      };

  static List<_Risk> _risksFor(String c) => switch (c) {
        'Obese' => const [
            _Risk(Icons.water_drop_rounded, 'High cholesterol',
                'Raised LDL and triglycerides that strain your arteries.'),
            _Risk(Icons.pie_chart_rounded, 'Belly (visceral) fat',
                'Fat around organs that drives many other risks.'),
            _Risk(Icons.bloodtype_rounded, 'Type-2 diabetes risk',
                'Higher blood sugar and insulin resistance.'),
            _Risk(Icons.favorite_rounded, 'High blood pressure & heart strain',
                'The heart works harder, raising heart-disease risk.'),
            _Risk(Icons.accessible_rounded, 'Joint pain (knees & hips)',
                'Extra load wears down knees, hips and ankles.'),
            _Risk(Icons.airline_seat_recline_normal_rounded, 'Back pain',
                'Added weight strains the lower back and posture.'),
            _Risk(Icons.spa_rounded, 'Low bone mineral density',
                'Weaker bones over time, raising fracture risk.'),
            _Risk(Icons.bedtime_rounded, 'Poor sleep & breathlessness',
                'Sleep apnea and getting winded on light activity.'),
          ],
        'Overweight' => const [
            _Risk(Icons.water_drop_rounded, 'Rising cholesterol',
                'Levels tend to creep up as weight increases.'),
            _Risk(Icons.pie_chart_rounded, 'Belly fat building up',
                'Waist size is an early warning sign.'),
            _Risk(Icons.bloodtype_rounded, 'Higher diabetes & BP risk',
                'Blood sugar and blood pressure start trending up.'),
            _Risk(Icons.accessible_rounded, 'Early joint & back strain',
                'Knees and lower back begin to feel the extra load.'),
          ],
        'Underweight' => const [
            _Risk(Icons.shield_rounded, 'Weakened immunity',
                'More prone to infections and slower recovery.'),
            _Risk(Icons.battery_alert_rounded, 'Low energy & fatigue',
                'Not enough reserves to feel your best.'),
            _Risk(Icons.spa_rounded, 'Low bone density',
                'Higher risk of weak bones and fractures.'),
            _Risk(Icons.fitness_center_rounded, 'Muscle loss',
                'Too little fuel makes it hard to build strength.'),
          ],
        'Normal' => const [
            _Risk(Icons.favorite_rounded, 'Protects your heart',
                'Lower risk of blood-pressure and heart problems.'),
            _Risk(Icons.bolt_rounded, 'More energy every day',
                'A healthy weight supports steady energy and mood.'),
            _Risk(Icons.directions_run_rounded, 'Easier movement',
                'Less strain on joints, better mobility for years.'),
          ],
        _ => const [],
      };
}

class _RiskTile extends StatelessWidget {
  const _RiskTile({required this.risk, required this.color});
  final _Risk risk;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: GlassCard(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: color.withOpacity(0.14),
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Icon(risk.icon, color: color, size: 22),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(risk.title,
                      style: text.titleSmall
                          ?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text(risk.detail, style: text.bodySmall),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A horizontal BMI scale (15–40) with the user's marker.
class _BmiScale extends StatelessWidget {
  const _BmiScale({required this.bmi});
  final double bmi;

  @override
  Widget build(BuildContext context) {
    const double min = 15, max = 40;
    final double t = ((bmi - min) / (max - min)).clamp(0.0, 1.0);
    final TextTheme text = Theme.of(context).textTheme;

    return LayoutBuilder(builder: (context, c) {
      final double w = c.maxWidth;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              // Coloured segments (widths proportional to their BMI span).
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.pill),
                child: Row(
                  children: [
                    Expanded(flex: 35, child: _seg(AppColors.info)), // <18.5
                    Expanded(flex: 65, child: _seg(AppColors.success)), // -25
                    Expanded(flex: 50, child: _seg(AppColors.orange)), // -30
                    Expanded(flex: 100, child: _seg(AppColors.error)), // 30-40
                  ],
                ),
              ),
              // Marker
              Positioned(
                left: (w * t - 2).clamp(0.0, w - 4),
                top: -4,
                child: Container(
                  width: 4,
                  height: 26,
                  decoration: BoxDecoration(
                    color: Colors.black87,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Under 18.5', style: text.bodySmall),
              Text('Normal', style: text.bodySmall),
              Text('25', style: text.bodySmall),
              Text('30+', style: text.bodySmall),
            ],
          ),
        ],
      );
    });
  }

  Widget _seg(Color c) => Container(height: 14, color: c);
}
