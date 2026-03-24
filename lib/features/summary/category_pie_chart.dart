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
        radius: 98,
        titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
      );
    }).toList();

    return PieChart(
      PieChartData(sections: sections, sectionsSpace: 2, centerSpaceRadius: 30),
    );
  }
}

Map<Category, Color> _categoryColors(BuildContext context) {
  return {
    Category.alimentacao: const Color.fromARGB(255, 6, 105, 14),
    Category.carro: const Color.fromARGB(255, 83, 124, 7),
    Category.cosmetico: Colors.blueGrey,
    Category.lazer: const Color.fromARGB(255, 150, 16, 16),
    Category.mercado: Colors.brown,
    Category.transporte: Colors.pinkAccent,
    Category.servico: Colors.indigo,
    Category.outros: Colors.teal,
  };
}
