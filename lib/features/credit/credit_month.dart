import 'package:finance_control/data/category.dart';
import 'package:finance_control/data/local_storage.dart';
import 'package:finance_control/data/models.dart';
import 'package:finance_control/data/repository.dart';
import 'package:finance_control/features/credit/credit_month_dialog.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CreditPage extends StatefulWidget {
  const CreditPage({super.key});

  @override
  State<CreditPage> createState() => _CreditPageState();
}

class _CreditPageState extends State<CreditPage> {
  late final FinanceRepository repo;
  List<CreditEntry> credits = [];
  bool loading = true;
  final currency = NumberFormat.simpleCurrency(locale: 'pt_BR');

  @override
  void initState() {
    super.initState();
    repo = FinanceRepository(LocalStorage());
    _load();
  }

  Future<void> _load() async {
    setState(() => loading = true);
    try {
      await repo.reload();
      final now = DateTime.now();
      final list = await repo.getCredits();
      setState(() {
        credits = list
            .where((e) => e.date.year == now.year && e.date.month == now.month)
            .toList();
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => loading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erro ao carregar créditos: $e')));
    }
  }

  double get total => credits.fold(0, (p, e) => p + e.amount);

  Future<void> _addOrEdit({CreditEntry? existing}) async {
    final changed = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.35),
      builder: (_) => CreditMonthDialog(existing: existing, repo: repo),
    );

    if (changed == true) {
      _load();
    }
  }

  Future<void> _removeCredit(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Remover crédito'),
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
      await repo.removeCredit(id);
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading)
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    return Scaffold(
      appBar: AppBar(title: const Text('Crédito (gastos do mês)')),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          Card(
            child: ListTile(
              title: const Text('Total do mês'),
              trailing: Text(currency.format(total)),
            ),
          ),
          ...credits.map(
            (c) => Card(
              child: ListTile(
                title: Text(c.description),
                subtitle: Text(
                  '${c.category.label} - ${c.person} - ${DateFormat.yMd('pt_BR').format(c.date)}',
                ),
                trailing: Text(currency.format(c.amount)),
                onTap: () => _addOrEdit(existing: c),
                onLongPress: () => _removeCredit(c.id),
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
