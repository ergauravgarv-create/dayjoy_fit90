import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Smooth gradient line chart for the weight-trend visual.
class WeightLineChart extends StatelessWidget {
  const WeightLineChart({
    super.key,
    required this.values,
    this.height = 160,
    this.showLabels = true,
  });

  final List<double> values;
  final double height;
  final bool showLabels;

  @override
  Widget build(BuildContext context) {
    if (values.isEmpty) return SizedBox(height: height);

    final double minY =
        values.reduce((a, b) => a < b ? a : b) - 1;
    final double maxY =
        values.reduce((a, b) => a > b ? a : b) + 1;

    final List<FlSpot> spots = [
      for (int i = 0; i < values.length; i++) FlSpot(i.toDouble(), values[i]),
    ];

    return SizedBox(
      height: height,
      child: LineChart(
        LineChartData(
          minY: minY,
          maxY: maxY,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: ((maxY - minY) / 3).clamp(1.0, 100.0),
            getDrawingHorizontalLine: (_) => FlLine(
              color: Colors.grey.withOpacity(0.15),
              strokeWidth: 1,
            ),
          ),
          titlesData: FlTitlesData(
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: showLabels,
                reservedSize: 34,
                interval: ((maxY - minY) / 3).clamp(1.0, 100.0),
                getTitlesWidget: (v, _) => Text(
                  v.toStringAsFixed(0),
                  style: const TextStyle(
                      fontSize: 10, color: AppColors.textSecondary),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: showLabels,
                reservedSize: 22,
                interval: 1,
                getTitlesWidget: (v, _) {
                  final int i = v.toInt();
                  if (i % 2 != 0) return const SizedBox.shrink();
                  return Text('W${i + 1}',
                      style: const TextStyle(
                          fontSize: 10, color: AppColors.textSecondary));
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              curveSmoothness: 0.32,
              gradient: AppColors.brandGradient,
              barWidth: 4,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, _, __, ___) => FlDotCirclePainter(
                  radius: 3,
                  color: Colors.white,
                  strokeWidth: 2,
                  strokeColor: AppColors.primary,
                ),
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.primary.withOpacity(0.20),
                    AppColors.primary.withOpacity(0.0),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
