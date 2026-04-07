import 'package:finance_control/features/budgets/presentation/category_budget_controller.dart';
import 'package:finance_control/features/categories/presentation/categories_controller.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class CategoryBudgetPage extends StatelessWidget {
  const CategoryBudgetPage({super.key});

  @override
  Widget build(BuildContext context) {
    final categoriesCtrl = context.watch<CategoriesController>();
    final budgetCtrl = context.watch<CategoryBudgetController>();
    final active = categoriesCtrl.active;

    return Scaffold(
      appBar: AppBar(title: const Text('Metas por categoria')),
      body: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: active.length,
        itemBuilder: (_, i) {
          final c = active[i];
          final limit = budgetCtrl.limitOf(c.id);

          return Card(
            child: ListTile(
              title: Text(c.name),
              subtitle: Text(
                limit == null
                    ? 'Sem meta definida'
                    : 'Limite R\$${limit.toStringAsFixed(2)}',
              ),
              trailing: const Icon(Icons.edit_outlined),
              onTap: () => _editLimit(context, c.id, c.name, limit),
            ),
          );
        },
      ),
    );
  }

  Future<void> _editLimit(
    BuildContext context,
    String categoryId,
    String categoryName,
    double? currentLimit,
  ) async {
    final crtl = TextEditingController(
      text: currentLimit?.toStringAsFixed(2) ?? '',
    );
  }
}
