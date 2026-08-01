import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../shared/widgets/glass_card.dart';

/// An inspirational 90-day transformation shown in the "Success Stories" row.
///
/// These are INSPIRATION-ONLY personas — they do NOT claim anyone used this app,
/// product or consultation. To show real photos, set [beforeImage]/[afterImage]
/// to asset paths, but ONLY use images you are licensed to use: your own
/// members' photos WITH their written consent, or stock photos WITH a model
/// release. Do NOT use images copied from the web (copyright + likeness rights).
class TransformationStory {
  const TransformationStory({
    required this.name,
    required this.city,
    required this.gender,
    required this.startKg,
    required this.endKg,
    required this.caption,
    this.days = 90,
    this.beforeImage,
    this.afterImage,
    this.blurFace = true,
  });

  final String name;
  final String city;
  final String gender; // 'M' or 'F'
  final double startKg;
  final double endKg;
  final String caption;
  final int days;
  final String? beforeImage; // optional licensed asset path
  final String? afterImage;

  /// When a real photo is used, blur the top (face) region to protect the
  /// person's identity. Has no effect on the drawn silhouette placeholder.
  final bool blurFace;

  double get lostKg => startKg - endKg;
}

const List<TransformationStory> kTransformationStories = [
  TransformationStory(
    name: 'Priya',
    city: 'Kochi',
    gender: 'F',
    startKg: 82,
    endKg: 72,
    caption: 'Consistent home workouts and mindful eating.',
  ),
  TransformationStory(
    name: 'Rahul',
    city: 'Pune',
    gender: 'M',
    startKg: 95,
    endKg: 85,
    caption: 'Daily walks and cutting back on sugar.',
  ),
  TransformationStory(
    name: 'Ananya',
    city: 'Bengaluru',
    gender: 'F',
    startKg: 70,
    endKg: 62,
    caption: 'Portion control and morning yoga.',
  ),
  TransformationStory(
    name: 'Sneha',
    city: 'Ahmedabad',
    gender: 'F',
    startKg: 76,
    endKg: 69,
    caption: 'Balanced meals, one day at a time.',
  ),
  TransformationStory(
    name: 'Arjun',
    city: 'Chennai',
    gender: 'M',
    startKg: 90,
    endKg: 84,
    caption: 'Small daily habits added up to a big change.',
  ),
];

/// Horizontal, swipeable carousel of inspirational 90-day transformations.
class TransformationStoriesCarousel extends StatelessWidget {
  const TransformationStoriesCarousel({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 258,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.zero,
        itemCount: kTransformationStories.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.md),
        itemBuilder: (context, i) =>
            _StoryCard(story: kTransformationStories[i]),
      ),
    );
  }
}

class _StoryCard extends StatelessWidget {
  const _StoryCard({required this.story});
  final TransformationStory story;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final Color tint =
        story.gender == 'M' ? AppColors.info : AppColors.orange;

    return SizedBox(
      width: 264,
      child: GlassCard(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: _frame(context,
                      tag: 'Before',
                      kg: story.startKg,
                      image: story.beforeImage,
                      tint: tint,
                      blurFace: story.blurFace,
                      highlight: false),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _frame(context,
                      tag: 'After',
                      kg: story.endKg,
                      image: story.afterImage,
                      tint: tint,
                      blurFace: story.blurFace,
                      highlight: true),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: Text('${story.name} · ${story.city}',
                      style: text.titleSmall
                          ?.copyWith(fontWeight: FontWeight.w800),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.14),
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  child: Text('-${story.lostKg.toStringAsFixed(0)} kg',
                      style: text.bodySmall?.copyWith(
                          color: AppColors.success,
                          fontWeight: FontWeight.w800)),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text('${story.days}-day transformation',
                style: text.bodySmall?.copyWith(color: tint)),
            const SizedBox(height: 4),
            Text(story.caption, style: text.bodySmall, maxLines: 2),
          ],
        ),
      ),
    );
  }

  Widget _frame(BuildContext context,
      {required String tag,
      required double kg,
      required String? image,
      required Color tint,
      required bool blurFace,
      required bool highlight}) {
    final Widget content = image != null
        ? ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.md),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(image, fit: BoxFit.cover),
                if (blurFace)
                  // Blur the top ~42% (face region) to protect identity.
                  Align(
                    alignment: Alignment.topCenter,
                    child: FractionallySizedBox(
                      widthFactor: 1,
                      heightFactor: 0.42,
                      child: ClipRect(
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                          child: const SizedBox.expand(),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          )
        : CustomPaint(
            painter: _SilhouettePainter(bulk: _bulk(kg), color: tint),
          );

    return SizedBox(
      height: 132,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceMuted,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: highlight
              ? Border.all(color: AppColors.primary, width: 2)
              : null,
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            content,
            Positioned(
              top: 6,
              left: 6,
              child: _pill(tag,
                  bg: highlight ? AppColors.primary : Colors.black54),
            ),
            Positioned(
              bottom: 6,
              left: 6,
              child: _pill('${kg.toStringAsFixed(0)} kg',
                  bg: Colors.black.withOpacity(0.55)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _pill(String label, {required Color bg}) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        child: Text(label,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w700)),
      );

  /// Body "bulk" 0..1 from a weight — heavier reads as a fuller silhouette.
  static double _bulk(double kg) => ((kg - 55) / 55).clamp(0.15, 1.0);
}

/// Draws a simple, friendly body silhouette whose width scales with [bulk], so
/// a "Before" (heavier) figure looks fuller than the "After". Purely
/// illustrative — no real person is depicted.
class _SilhouettePainter extends CustomPainter {
  _SilhouettePainter({required this.bulk, required this.color});
  final double bulk;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    final double cx = w / 2;

    final Paint paint = Paint()
      ..style = PaintingStyle.fill
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [color.withOpacity(0.55), color.withOpacity(0.32)],
      ).createShader(Offset.zero & size);

    // Head
    final double headR = h * 0.085;
    final double headCy = h * 0.17;
    canvas.drawCircle(Offset(cx, headCy), headR, paint);

    // Torso (width grows with bulk)
    final double bodyW = w * (0.24 + bulk * 0.28);
    final double torsoTop = headCy + headR * 0.8;
    final double torsoBottom = h * 0.60;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(cx, (torsoTop + torsoBottom) / 2),
          width: bodyW,
          height: torsoBottom - torsoTop,
        ),
        Radius.circular(bodyW * 0.42),
      ),
      paint,
    );

    // Arms
    final double armW = bodyW * 0.24;
    final double armLen = (torsoBottom - torsoTop) * 0.92;
    for (final double s in [-1.0, 1.0]) {
      final double ax = cx + s * (bodyW / 2 + armW * 0.15);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(ax, torsoTop + armLen / 2),
            width: armW,
            height: armLen,
          ),
          Radius.circular(armW / 2),
        ),
        paint,
      );
    }

    // Legs
    final double legW = bodyW * 0.36;
    final double legTop = torsoBottom - (torsoBottom - torsoTop) * 0.06;
    final double legBottom = h * 0.95;
    for (final double s in [-1.0, 1.0]) {
      final double lx = cx + s * (legW * 0.62);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(lx, (legTop + legBottom) / 2),
            width: legW,
            height: legBottom - legTop,
          ),
          Radius.circular(legW / 2),
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _SilhouettePainter old) =>
      old.bulk != bulk || old.color != color;
}
