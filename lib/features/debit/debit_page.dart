import 'package:finance_control/data/models.dart';
import 'package:finance_control/data/repository.dart';
import 'package:finance_control/features/categories/presentation/categories_controller.dart';
import 'package:finance_control/features/debit/debit_dialog.dart';
import 'package:finance_control/shared/state/date_filter_controller.dart';
import 'package:finance_control/shared/theme/app_colors.dart';
import 'package:finance_control/shared/theme/app_spacing.dart';
import 'package:finance_control/shared/utils/input_parses.dart';
import 'package:finance_control/shared/widgets/app_card.dart';
import 'package:finance_control/shared/widgets/app_loading.dart';
import 'package:finance_control/shared/widgets/empty_state.dart';
import 'package:finance_control/shared/widgets/section_title.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class DebitPage extends StatefulWidget {
  const DebitPage({super.key});

  @override
  State<DebitPage> createState() => _DebitPageState();
}

class _DebitPageState extends State<DebitPage> {
  late final FinanceRepository repo;
  late final DateFilterController filter;

  List<DebitEntry> debits = [];
  double initialBalance = 0;
  bool loading = true;

  final currency = NumberFormat.simpleCurrency(locale: 'pt_BR');
  final dateFmt = DateFormat.yMd('pt_BR');

  @override
  void initState() {
    super.initState();
    repo = context.read<FinanceRepository>();
    filter = context.read<DateFilterController>();
    filter.addListener(_onFilterChanged);
    _load();
  }

  void _onFilterChanged() {
    if (!mounted) return;
    _load();
  }

  @override
  void dispose() {
    filter.removeListener(_onFilterChanged);
    super.dispose();
  }

  Future<void> _load() async {
    try {
      setState(() => loading = true);

      await repo.reload();

      final start = filter.effectiveStart;
      final end = filter.effectiveEnd;
      bool inRange(DateTime d) => !d.isBefore(start) && !d.isAfter(end);

      final list = await repo.getDebits();
      final bal = await repo.getInitialBalance(start.year, start.month);

      if (!mounted) return;
      setState(() {
        debits = list.where((e) => inRange(e.date)).toList();
        initialBalance = bal;
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => loading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erro ao carregar débitos: $e')));
    }
  }

  double get totalSpent => debits.fold(0, (p, e) => p + e.amount);
  double get currentBalance => initialBalance - totalSpent;

  Future<void> _editInitialBalance() async {
    final controller = TextEditingController();

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Saldo inicial (${filter.labelPtBr()})'),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'Valor',
            prefixText: 'R\$ ',
            hintText: 'Ex: 1650,00',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              final raw = controller.text.trim();
              if (raw.isEmpty) {
                Navigator.pop(ctx);
                return;
              }

              final parsed = parsePtBrToDouble(raw);
              if (parsed < 0) return;

              final base = filter.effectiveStart;
              await repo.setInitialBalance(base.year, base.month, parsed);

              if (!mounted) return;
              Navigator.pop(ctx);
              _load();
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }

  Future<void> _addOrEdit({DebitEntry? existing}) async {
    final changed = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.35),
      builder: (_) => DebitDialog(existing: existing, repo: repo),
    );
    if (changed == true) _load();
  }

  Future<void> _removeDebit(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Remover débito'),
        content: const Text('Tem certeza que deseja remover esse lançamento?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remover'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await repo.removeDebit(id);
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentFilter = context.watch<DateFilterController>();
    final categoriesCtrl = context.watch<CategoriesController>();

    if (loading) return const AppLoading();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Débito'),
        actions: [
          IconButton(
            tooltip: 'Editar saldo inicial',
            onPressed: _editInitialBalance,
            icon: const Icon(Icons.edit),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.sm),
        children: [
          SectionTitle(
            title: 'Filtro global ativo',
            subtitle: currentFilter.labelPtBr(),
          ),
          AppCard(
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Saldo inicial'),
              subtitle: Text('Saldo atual: ${currency.format(currentBalance)}'),
              trailing: Text(
                currency.format(initialBalance),
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
          AppCard(
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Gasto total no filtro'),
              trailing: Text(
                '- ${currency.format(totalSpent)}',
                style: const TextStyle(color: AppColors.danger),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          SectionTitle(
            title: 'Lançamentos',
            subtitle: '${debits.length} item(ns)',
          ),
          if (debits.isEmpty)
            const AppCard(
              child: EmptyState(
                icon: Icons.receipt_long_outlined,
                title: 'Sem débitos no período',
                message: 'Adicione um lançamento para começar.',
              ),
            )
          else
            ...debits.map(
              (d) => AppCard(
                onTap: () => _addOrEdit(existing: d),
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(d.description),
                  subtitle: Text(
                    '${categoriesCtrl.nameOf(d.categoryId)} • ${d.person} • ${dateFmt.format(d.date)}',
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '- ${currency.format(d.amount)}',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        tooltip: 'Editar',
                        onPressed: () => _addOrEdit(existing: d),
                        icon: const Icon(Icons.edit_outlined),
                      ),
                      IconButton(
                        tooltip: 'Excluir',
                        onPressed: () => _removeDebit(d.id),
                        icon: const Icon(Icons.delete_forever_outlined),
                      ),
                    ],
                  ),
                  onTap: () => _addOrEdit(existing: d),
                ),
              ),
            ),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addOrEdit(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
