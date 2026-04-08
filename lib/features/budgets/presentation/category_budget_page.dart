import 'package:finance_control/features/budgets/presentation/category_budget_controller.dart';
import 'package:finance_control/features/categories/presentation/categories_controller.dart';
import 'package:finance_control/shared/utils/input_parses.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class CategoryBudgetsPage extends StatelessWidget {
  const CategoryBudgetsPage({super.key});

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
                    : 'Limite: R\$ ${limit.toStringAsFixed(2)}',
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
    final ctrl = TextEditingController(
      text: currentLimit?.toStringAsFixed(2) ?? '',
    );

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Meta: $categoryName'),
        content: TextField(
          controller: ctrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'Limite mensal',
            prefixText: 'R\$ ',
            hintText: 'Ex.: 500,00',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          if (currentLimit != null)
            TextButton(
              onPressed: () async {
                await context.read<CategoryBudgetController>().remove(
                  categoryId,
                );
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text('Remover meta'),
            ),
          FilledButton(
            onPressed: () async {
              final value = parsePtBrToDouble(ctrl.text);

              if (value <= 0) {
                // vazio/zero: remove meta se existir
                if (currentLimit != null) {
                  await context.read<CategoryBudgetController>().remove(
                    categoryId,
                  );
                }
                if (context.mounted) Navigator.pop(context);
                return;
              }

              await context.read<CategoryBudgetController>().upsert(
                categoryId,
                value,
              );

              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }
}
