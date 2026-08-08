import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/glass_card.dart';
import '../../state/meal_photos_provider.dart';
import '../../state/meal_provider.dart';
import 'meal_data.dart';

/// A chronological diary of meals — photos + logged foods, grouped by day.
class FoodDiaryScreen extends ConsumerWidget {
  const FoodDiaryScreen({super.key});

  String _dayLabel(DateTime d) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final diff = today.difference(DateTime(d.year, d.month, d.day)).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    return DateFormat('EEEE, d MMM').format(d);
  }

  void _viewPhoto(BuildContext context, String data) {
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
  Widget build(BuildContext context, WidgetRef ref) {
    final diary = ref.watch(foodDiaryProvider);
    final TextTheme text = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Food Diary')),
      body: diary.isEmpty
          ? const EmptyState(
              icon: Icons.menu_book_rounded,
              title: 'Your food diary is empty',
              message: 'Log meals and snap a photo of your plate in the Meal '
                  'Tracker — the last 7 days show up here.',
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.xxl),
              children: [
                for (final day in diary) ...[
                  Padding(
                    padding: const EdgeInsets.only(
                        top: AppSpacing.sm, bottom: AppSpacing.sm),
                    child: Row(
                      children: [
                        Text(_dayLabel(day.date), style: text.titleMedium),
                        const Spacer(),
                        if (day.kcal > 0)
                          Text('${day.kcal} kcal',
                              style: text.bodySmall?.copyWith(
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ),
                  for (final type in MealType.values)
                    if (day.photos[type] != null ||
                        day.logsFor(type).isNotEmpty)
                      _MealBlock(
                        type: type,
                        photo: day.photos[type],
                        logs: day.logsFor(type),
                        onViewPhoto: _viewPhoto,
                      ),
                  const SizedBox(height: AppSpacing.md),
                ],
              ],
            ),
    );
  }
}

class _MealBlock extends StatelessWidget {
  const _MealBlock(
      {required this.type,
      required this.photo,
      required this.logs,
      required this.onViewPhoto});
  final MealType type;
  final String? photo;
  final List<MealLog> logs;
  final void Function(BuildContext, String) onViewPhoto;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final int kcal = logs.fold(0, (s, l) => s + l.kcal);
    final String items = logs.map((l) => l.food.name).join(', ');

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: GlassCard(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (photo != null)
              GestureDetector(
                onTap: () => onViewPhoto(context, photo!),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  child: Image.memory(base64Decode(photo!),
                      width: 72, height: 72, fit: BoxFit.cover),
                ),
              )
            else
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Icon(type.icon, color: AppColors.primary),
              ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(type.label, style: text.titleSmall),
                      const Spacer(),
                      if (kcal > 0)
                        Text('$kcal kcal',
                            style: text.bodySmall?.copyWith(
                                fontWeight: FontWeight.w700)),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    items.isEmpty ? 'Photo logged' : items,
                    style: text.bodySmall
                        ?.copyWith(color: AppColors.textSecondary),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
