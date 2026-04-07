import 'package:finance_control/features/categories/domain/category_colors.dart';
import 'package:finance_control/features/categories/presentation/categories_controller.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class CategoryPieChart extends StatelessWidget {
  final Map<String, double> totals; // categoryId -> total
  final CategoriesController categoriesCtrl;

  const CategoryPieChart({
    super.key,
    required this.totals,
    required this.categoriesCtrl,
  });

  @override
  Widget build(BuildContext context) {
    final totalValue = totals.values.fold<double>(0, (p, e) => p + e);
    if (totalValue == 0) {
      return const Center(child: Text('Sem dados para o período!'));
    }

    // Ordena do maior para o menor
    final sorted = totals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Top 6 + Outros
    const topN = 6;
    final top = sorted.take(topN).toList();
    final others = sorted.skip(topN).fold<double>(0, (p, e) => p + e.value);

    final sections = <PieChartSectionData>[];

    for (final e in top) {
      final category = categoriesCtrl.byId(e.key);
      final name = category?.name ?? 'Sem categoria';
      final color = category != null
          ? CategoryColors.hexToColor(category.colorHex)
          : CategoryColors.byId(e.key);

      final percent = (e.value / totalValue * 100).toStringAsFixed(1);

      sections.add(
        PieChartSectionData(
          color: color,
          value: e.value,
          title: '$name\n$percent%',
          radius: 98,
          titleStyle: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

    if (others > 0) {
      final percent = (others / totalValue * 100).toStringAsFixed(1);
      sections.add(
        PieChartSectionData(
          color: const Color(0xFF9CA3AF),
          value: others,
          title: 'Outros\n$percent%',
          radius: 98,
          titleStyle: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

    return PieChart(
      PieChartData(sections: sections, sectionsSpace: 2, centerSpaceRadius: 24),
    );
  }
}
