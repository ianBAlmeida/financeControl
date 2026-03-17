import 'package:finance_control/data/category.dart';
import 'package:flutter/material.dart';

class CategoryDropdownField extends StatelessWidget {
  const CategoryDropdownField({
    super.key,
    required this.value,
    required this.onChanged,
    this.label = 'Categoria',
  });

  final Category value;
  final ValueChanged<Category> onChanged;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        canvasColor: const Color(0xFF1E1E1E), // fundo sólido do menu aberto
      ),
      child: DropdownButtonFormField<Category>(
        value: value,
        decoration: InputDecoration(labelText: label),
        dropdownColor: const Color(0xFF1E1E1E),
        items: Category.values
            .map(
              (c) => DropdownMenuItem<Category>(
                value: c,
                child: Text(
                  c.label,
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            )
            .toList(),
        onChanged: (v) {
          if (v != null) onChanged(v);
        },
      ),
    );
  }
}
