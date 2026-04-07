import 'package:finance_control/features/categories/presentation/categories_controller.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:finance_control/features/categories/domain/category_colors.dart';

class CategoryDropdownField extends StatelessWidget {
  const CategoryDropdownField({
    super.key,
    required this.value,
    required this.onChanged,
    this.label = 'Categoria',
  });

  final String? value;
  final ValueChanged<String?> onChanged;
  final String label;

  @override
  Widget build(BuildContext context) {
    final categories = context.watch<CategoriesController>().active;

    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(labelText: label),
      items: categories.map((c) {
        final color = CategoryColors.hexToColor(c.colorHex);
        return DropdownMenuItem<String>(
          value: c.id,
          child: Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Text(c.name),
            ],
          ),
        );
      }).toList(),
      onChanged: onChanged,
      validator: (v) =>
          (v == null || v.isEmpty) ? 'Selecione uma categoria' : null,
    );
  }
}
