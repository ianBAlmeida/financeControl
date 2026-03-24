import 'package:finance_control/data/category.dart';
import 'package:finance_control/data/models.dart';
import 'package:finance_control/data/repository.dart';
import 'package:finance_control/features/debit/debit_dialog.dart';
import 'package:finance_control/shared/state/date_filter_controller.dart';
import 'package:finance_control/shared/utils/input_parses.dart';
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
    _load();
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

    if (loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

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
        padding: const EdgeInsets.all(12),
        children: [
          Text('Filtro: ${currentFilter.labelPtBr()}'),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              title: const Text('Saldo inicial (referência)'),
              trailing: Text(currency.format(initialBalance)),
              subtitle: Text('Saldo Atual: ${currency.format(currentBalance)}'),
            ),
          ),
          const SizedBox(height: 8),
          ...debits.map(
            (d) => Card(
              child: ListTile(
                title: Text(d.description),
                subtitle: Text(
                  '${d.category.label} - ${d.person} - ${dateFmt.format(d.date)}',
                ),
                trailing: Text('- ${currency.format(d.amount)}'),
                onTap: () => _addOrEdit(existing: d),
                onLongPress: () => _removeDebit(d.id),
              ),
            ),
          ),
          const SizedBox(height: 64),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addOrEdit(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
