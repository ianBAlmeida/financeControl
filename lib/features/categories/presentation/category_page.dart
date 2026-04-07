import 'package:finance_control/features/categories/domain/category_colors.dart';
import 'package:finance_control/features/categories/domain/category_model.dart';
import 'package:finance_control/features/categories/presentation/categories_controller.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class CategoriesPage extends StatelessWidget {
  const CategoriesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<CategoriesController>();
    final categories = [...ctrl.all]
      ..sort((a, b) => a.order.compareTo(b.order));

    return Scaffold(
      appBar: AppBar(title: const Text('Categorias')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openForm(context),
        child: const Icon(Icons.add),
      ),
      body: categories.isEmpty
          ? const Center(child: Text('Nenhuma categoria cadastrada'))
          : ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: categories.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, i) {
                final c = categories[i];
                final color = CategoryColors.hexToColor(c.colorHex);

                return Card(
                  child: ListTile(
                    leading: CircleAvatar(radius: 10, backgroundColor: color),
                    title: Text(c.name),
                    subtitle: Text(c.isArchived ? 'Arquivada' : 'Ativa'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          tooltip: 'Editar',
                          icon: const Icon(Icons.edit_outlined),
                          onPressed: () => _openForm(context, existing: c),
                        ),
                        IconButton(
                          tooltip: c.isArchived ? 'Desarquivar' : 'Arquivar',
                          icon: Icon(
                            c.isArchived
                                ? Icons.unarchive_outlined
                                : Icons.archive_outlined,
                          ),
                          onPressed: () => context
                              .read<CategoriesController>()
                              .archiveToggle(c.id),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  Future<void> _openForm(
    BuildContext context, {
    CategoryModel? existing,
  }) async {
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    String selectedHex =
        existing?.colorHex ??
        CategoryColors.colorToHex(CategoryColors.palette.first);

    await showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            title: Text(
              existing == null ? 'Nova categoria' : 'Editar categoria',
            ),
            content: SizedBox(
              width: 420,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(labelText: 'Nome'),
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Cor',
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: CategoryColors.palette.map((color) {
                      final hex = CategoryColors.colorToHex(color);
                      final selected = selectedHex == hex;

                      return InkWell(
                        borderRadius: BorderRadius.circular(999),
                        onTap: () => setStateDialog(() => selectedHex = hex),
                        child: Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: selected
                                  ? Colors.white
                                  : Colors.transparent,
                              width: 2,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: () async {
                  final name = nameCtrl.text.trim();
                  if (name.isEmpty) return;

                  final ctrl = context.read<CategoriesController>();
                  if (existing == null) {
                    await ctrl.create(name: name, colorHex: selectedHex);
                  } else {
                    await ctrl.update(
                      existing.copywith(name: name, colorHex: selectedHex),
                    );
                  }

                  if (context.mounted) Navigator.pop(context);
                },
                child: const Text('Salvar'),
              ),
            ],
          );
        },
      ),
    );
  }
}
