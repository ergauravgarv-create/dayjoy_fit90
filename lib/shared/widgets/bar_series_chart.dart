import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Lightweight vertical bar chart (no external chart lib). Heights are scaled
/// to the series max; pass [asPercent] to render 0..1 values as "NN%" captions.
class BarSeriesChart extends StatelessWidget {
  const BarSeriesChart({
    super.key,
    required this.values,
    required this.labels,
    this.height = 140,
    this.asPercent = false,
    this.gradient = AppColors.brandGradient,
  });

  final List<double> values;
  final List<String> labels;
  final double height;
  final bool asPercent;
  final Gradient gradient;

  @override
  Widget build(BuildContext context) {
    if (values.isEmpty) return SizedBox(height: height);
    final double maxV =
        values.reduce((a, b) => a > b ? a : b).clamp(0.0001, double.infinity);
    final double barMax = height - 46;

    return SizedBox(
      height: height,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (int i = 0; i < values.length; i++)
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    asPercent
                        ? '${(values[i] * 100).round()}'
                        : values[i].toStringAsFixed(0),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 4),
                  Container(
                    height: (values[i] / maxV) * barMax,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      gradient: gradient,
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(6)),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    i < labels.length ? labels[i] : '',
                    style: Theme.of(context).textTheme.bodySmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
