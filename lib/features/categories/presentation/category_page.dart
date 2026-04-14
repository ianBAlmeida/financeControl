import 'package:finance_control/data/category_budget_repository.dart';
import 'package:finance_control/features/categories/domain/category_colors.dart';
import 'package:finance_control/features/categories/domain/category_model.dart';
import 'package:finance_control/features/categories/presentation/categories_controller.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class CategoriesPage extends StatefulWidget {
  const CategoriesPage({super.key});

  @override
  State<CategoriesPage> createState() => _CategoriesPageState();
}

class _CategoriesPageState extends State<CategoriesPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CategoriesController>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<CategoriesController>();
    final active = ctrl.active;
    final archived = ctrl.all.where((c) => c.isArchived).toList()
      ..sort((a, b) => a.order.compareTo(b.order));

    return Scaffold(
      appBar: AppBar(title: const Text('Categorias'), centerTitle: true),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openCreateDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('Nova categoria'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          const _SectionHeader(title: 'Ativas'),
          if (active.isEmpty)
            const _EmptyHint(message: 'Nenhuma categoria ativa.')
          else
            ...active.map((c) => _CategoryTile(category: c)),

          const SizedBox(height: 16),

          const _SectionHeader(title: 'Arquivadas'),
          if (archived.isEmpty)
            const _EmptyHint(message: 'Nenhuma categoria arquivada.')
          else
            ...archived.map((c) => _CategoryTile(category: c)),
        ],
      ),
    );
  }

  Future<void> _openCreateDialog(BuildContext context) async {
    final nameCtrl = TextEditingController();
    String selectedColor = '#FF6366F1';

    final saved = await showDialog<bool>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setLocal) {
          return AlertDialog(
            title: const Text('Nova categoria'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Nome',
                      hintText: 'Ex.: Alimentação',
                    ),
                    textInputAction: TextInputAction.done,
                  ),
                  const SizedBox(height: 12),
                  _ColorPicker(
                    selectedHex: selectedColor,
                    onSelected: (hex) => setLocal(() => selectedColor = hex),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Salvar'),
              ),
            ],
          );
        },
      ),
    );

    if (saved != true) return;

    final name = nameCtrl.text.trim();
    if (name.isEmpty) return;

    await context.read<CategoriesController>().create(
      name: name,
      colorHex: selectedColor,
    );

    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Categoria "$name" criada.')));
  }
}

class _CategoryTile extends StatelessWidget {
  final CategoryModel category;
  const _CategoryTile({required this.category});

  @override
  Widget build(BuildContext context) {
    final ctrl = context.read<CategoriesController>();
    final budgetRepo = context.read<CategoryBudgetRepository>();
    final color = CategoryColors.hexToColor(category.colorHex);

    return Card(
      child: ListTile(
        leading: CircleAvatar(backgroundColor: color),
        title: Text(category.name),
        subtitle: Text(category.isArchived ? 'Arquivada' : 'Ativa'),
        trailing: Wrap(
          spacing: 4,
          children: [
            IconButton(
              tooltip: 'Editar',
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => _openEditDialog(context, category),
            ),
            IconButton(
              tooltip: category.isArchived ? 'Desarquivar' : 'Arquivar',
              icon: Icon(
                category.isArchived
                    ? Icons.unarchive_outlined
                    : Icons.archive_outlined,
              ),
              onPressed: () async {
                await ctrl.archiveToggle(category.id);
              },
            ),
            IconButton(
              tooltip: 'Excluir',
              icon: const Icon(Icons.delete_outline),
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text('Excluir categoria'),
                    content: Text(
                      'Deseja excluir a categoria "${category.name}"?',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancelar'),
                      ),
                      FilledButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Excluir'),
                      ),
                    ],
                  ),
                );

                if (confirm != true) return;

                // remove budget da categoria (se existir)
                await budgetRepo.remove(category.id);

                // remove categoria
                await ctrl.deleteCategory(category.id);

                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Categoria "${category.name}" excluída.'),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openEditDialog(BuildContext context, CategoryModel c) async {
    final nameCtrl = TextEditingController(text: c.name);
    String selectedColor = c.colorHex;

    final saved = await showDialog<bool>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setLocal) {
          return AlertDialog(
            title: const Text('Editar categoria'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(labelText: 'Nome'),
                  ),
                  const SizedBox(height: 12),
                  _ColorPicker(
                    selectedHex: selectedColor,
                    onSelected: (hex) => setLocal(() => selectedColor = hex),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Salvar'),
              ),
            ],
          );
        },
      ),
    );

    if (saved != true) return;
    final newName = nameCtrl.text.trim();
    if (newName.isEmpty) return;

    final updated = c.copyWith(name: newName, colorHex: selectedColor);

    await context.read<CategoriesController>().update(updated);

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Categoria "${updated.name}" atualizada.')),
    );
  }
}

class _ColorPicker extends StatelessWidget {
  final String selectedHex;
  final ValueChanged<String> onSelected;

  const _ColorPicker({required this.selectedHex, required this.onSelected});

  String _toHex(Color c) {
    final a = c.alpha.toRadixString(16).padLeft(2, '0');
    final r = c.red.toRadixString(16).padLeft(2, '0');
    final g = c.green.toRadixString(16).padLeft(2, '0');
    final b = c.blue.toRadixString(16).padLeft(2, '0');
    return '#$a$r$g$b'.toUpperCase(); // formato AARRGGBB
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: CategoryColors.palette.map((color) {
        final hex = _toHex(color);
        final isSelected = hex == selectedHex.toUpperCase();

        return InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => onSelected(hex),
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? Colors.black : Colors.transparent,
                width: 2,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 8),
      child: Text(title, style: Theme.of(context).textTheme.titleMedium),
    );
  }
}

class _EmptyHint extends StatelessWidget {
  final String message;
  const _EmptyHint({required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(message, style: Theme.of(context).textTheme.bodyMedium),
    );
  }
}
