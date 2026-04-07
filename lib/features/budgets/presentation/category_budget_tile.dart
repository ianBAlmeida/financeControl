import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CategoryBudgetTile extends StatelessWidget {
  const CategoryBudgetTile({
    super.key,
    required this.categoryName,
    required this.spent,
    required this.limit,
  });

  final String categoryName;
  final double spent;
  final double limit;

  @override
  Widget build(BuildContext context) {
    final money = NumberFormat.simpleCurrency(locale: 'pt_BR');
    final ratio = limit <= 0 ? 0.0 : (spent / limit);
    final percent = (ratio * 100).clamp(0, 999).toStringAsFixed(0);

    Color color;
    String label;
    if (ratio >= 1.0) {
      color = Colors.redAccent;
      label = 'Estourou';
    } else if (ratio >= 0.8) {
      color = Colors.orangeAccent;
      label = 'Atenção';
    } else {
      color = Colors.green;
      label = 'Ok';
    }

    final exceeded = (spent - limit).clamp(0, double.infinity);

    return Card(
      child: ListTile(
        title: Text(categoryName),
        subtitle: Text(
          exceeded > 0
              ? '$label • $percent% • Excedeu ${money.format(exceeded)}'
              : '$label • $percent% • ${money.format(spent)} de ${money.format(limit)}',
        ),
        trailing: Icon(Icons.flag, color: color),
      ),
    );
  }
}
