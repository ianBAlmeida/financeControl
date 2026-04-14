import 'package:finance_control/features/categories/domain/category_colors.dart';
import 'package:finance_control/features/categories/domain/category_model.dart';
import 'package:finance_control/features/categories/presentation/categories_controller.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class CategoryDropdownField extends StatelessWidget {
  final String? value;
  final ValueChanged<String?> onChanged;
  final String label;

  const CategoryDropdownField({
    super.key,
    required this.value,
    required this.onChanged,
    this.label = 'Categoria',
  });

  @override
  Widget build(BuildContext context) {
    final categoriesCtrl = context.watch<CategoriesController>();

    final active = categoriesCtrl.active;

    final uniqueById = <String, CategoryModel>{};
    for (final c in active) {
      uniqueById[c.id] = c;
    }

    final categories = uniqueById.values.toList()
      ..sort((a, b) => a.order.compareTo(b.order));

    final safeValue = (value != null && categories.any((c) => c.id == value))
        ? value
        : null;

    if (safeValue != value) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        onChanged(safeValue);
      });
    }

    return DropdownButtonFormField<String>(
      value: safeValue,
      isExpanded: true,
      decoration: InputDecoration(labelText: label),
      items: categories
          .map(
            (c) => DropdownMenuItem<String>(
              value: c.id,
              child: Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: CategoryColors.hexToColor(c.colorHex),
                      shape: BoxShape.circle,
                    ),
                  ),
                  Expanded(
                    child: Text(c.name, overflow: TextOverflow.ellipsis),
                  ),
                ],
              ),
            ),
          )
          .toList(),
      onChanged: onChanged,
      validator: (v) {
        if (v == null || v.isEmpty) return 'Selecione uma categoria';
        return null;
      },
    );
  }
}
