import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../utils/constants.dart';

class BudgetChart extends StatelessWidget {
  final List<String> labels;
  final List<double> budgetValues;
  final List<double> spentValues;
  final double maxHeight;

  const BudgetChart({
    super.key,
    required this.labels,
    required this.budgetValues,
    required this.spentValues,
    this.maxHeight = 220,
  });

  @override
  Widget build(BuildContext context) {
    final maxY = budgetValues.isNotEmpty
        ? (budgetValues.reduce((a, b) => a > b ? a : b) * 1.15)
        : 100.0;

    return Container(
      height: maxHeight,
      padding: const EdgeInsets.only(
        top: AppDimens.spaceLg,
        right: AppDimens.spaceSm,
        bottom: 0,
        left: 0,
      ),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxY,
          barTouchData: BarTouchData(
            enabled: true,
            touchTooltipData: BarTouchTooltipData(
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                final budget = budgetValues[groupIndex];
                final spent = spentValues[groupIndex];
                return BarTooltipItem(
                  'Presupuesto: \$${budget.toStringAsFixed(0)}\nGastado: \$${spent.toStringAsFixed(0)}',
                  const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                );
              },
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 36,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index < 0 || index >= labels.length) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      labels[index],
                      style: TextStyle(
                        fontSize: 10,
                        color: AppColors.textSecondary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 48,
                interval: maxY / 4,
                getTitlesWidget: (value, meta) {
                  if (value >= 1000) {
                    return Text(
                      '\$${(value / 1000).toStringAsFixed(0)}K',
                      style: TextStyle(fontSize: 10, color: AppColors.textMuted),
                    );
                  }
                  return Text(
                    '\$${value.toInt()}',
                    style: TextStyle(fontSize: 10, color: AppColors.textMuted),
                  );
                },
              ),
            ),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: maxY / 4,
            getDrawingHorizontalLine: (value) => FlLine(
              color: AppColors.border,
              strokeWidth: 1,
            ),
          ),
          borderData: FlBorderData(show: false),
          barGroups: List.generate(labels.length, (i) {
            return BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: budgetValues[i],
                  width: 10,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(3),
                    topRight: Radius.circular(3),
                  ),
                  color: AppColors.primary.withOpacity(0.3),
                ),
                BarChartRodData(
                  toY: spentValues[i],
                  width: 10,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(3),
                    topRight: Radius.circular(3),
                  ),
                  color: AppColors.accent,
                ),
              ],
            );
          }),
        ),
      ),
    );
  }
}
