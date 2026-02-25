import 'package:finance_control/data/category.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class CategoryPieChart extends StatelessWidget {
  final Map<Category, double> totals;
  const CategoryPieChart({super.key, required this.totals});

  @override
  Widget build(BuildContext context) {
    final totalValue = totals.values.fold<double>(0, (p, e) => p + e);
    if (totalValue == 0) {
      return const Center(child: Text('Sem dados para o mês!'));
    }

    final colors = _categoryColors(context);
    final sections = totals.entries.map((e) {
      final percent = (e.value / totalValue * 100).toStringAsFixed(1);
      return PieChartSectionData(
        color: colors[e.key],
        value: e.value,
        title: '${e.key.label}\n$percent',
        radius: 80,
        titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
      );
    }).toList();

    return PieChart(
      PieChartData(sections: sections, sectionsSpace: 2, centerSpaceRadius: 30),
    );
  }
}

Map<Category, Color> _categoryColors(BuildContext context) {
  final cs = Theme.of(context).colorScheme;
  return {
    Category.alimentacao: cs.primary,
    Category.carro: cs.secondary,
    Category.cosmetico: cs.tertiary,
    Category.lazer: cs.error,
    Category.mercado: cs.surfaceTint,
    Category.transporte: cs.outline,
    Category.servico: cs.tertiaryFixedDim,
    Category.outros: cs.onSurfaceVariant,
  };
}
