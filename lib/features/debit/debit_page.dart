import 'package:finance_control/data/category.dart';
import 'package:finance_control/data/local_storage.dart';
import 'package:finance_control/data/models.dart';
import 'package:finance_control/data/repository.dart';
import 'package:finance_control/features/debit/debit_dialog.dart';
import 'package:finance_control/shared/utils/input_parses.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DebitPage extends StatefulWidget {
  const DebitPage({super.key});

  @override
  State<DebitPage> createState() => _DebitPageState();
}

class _DebitPageState extends State<DebitPage> {
  late final FinanceRepository repo;
  List<DebitEntry> debits = [];
  double initialBalance = 0;
  bool loading = true;
  final currency = NumberFormat.simpleCurrency(locale: 'pt_BR');

  @override
  void initState() {
    super.initState();
    repo = FinanceRepository(LocalStorage());
    _load();
  }

  //Carrega os lançamentos e saldo do mês corrente
  Future<void> _load() async {
    try {
      await repo.reload();
      setState(() => loading = true);
      final now = DateTime.now();
      final list = await repo.getDebits();
      final bal = await repo.getInitialBalance(now.year, now.month);
      setState(() {
        debits = list
            .where((e) => e.date.year == now.year && e.date.month == now.month)
            .toList();
        initialBalance = bal;
        loading = false;
      });
    } catch (e) {
      if (!mounted) return setState(() => loading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erro ao carregar débitos: $e')));
    }
  }

  double get totalSpent => debits.fold(0, (p, e) => p + e.amount);
  double get currentBalance => initialBalance - totalSpent;

  //Cria ou edita um lançamento de débito
  Future<void> _editInitialBalance() async {
    final controller = TextEditingController(
      text: initialBalance.toStringAsFixed(2),
    );
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Saldo inicial do mês'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Valor',
            prefixText: 'R\$ ',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              final parsed = parsePtBrToDouble(controller.text);
              final v = parsed > 0 ? parsed : initialBalance;
              initialBalance;
              final now = DateTime.now();
              await repo.setInitialBalance(now.year, now.month, v);
              Navigator.pop(context);
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

    if (changed == true) {
      _load();
    }
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
    if (loading)
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    return Scaffold(
      appBar: AppBar(
        title: const Text('Débito'),
        actions: [
          IconButton(
            onPressed: _editInitialBalance,
            icon: const Icon(Icons.edit),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          Card(
            child: ListTile(
              title: const Text('Saldo inicial (mês)'),
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
                  '${d.category.label} - ${d.person} - ${DateFormat.yMd('pt_BR').format(d.date)}',
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
