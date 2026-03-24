import 'package:finance_control/data/category.dart';
import 'package:finance_control/data/models.dart';
import 'package:finance_control/data/repository.dart';
import 'package:finance_control/features/credit/credit_month_dialog.dart';
import 'package:finance_control/shared/state/date_filter_controller.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class CreditPage extends StatefulWidget {
  const CreditPage({super.key});

  @override
  State<CreditPage> createState() => _CreditPageState();
}

class _CreditPageState extends State<CreditPage> {
  late final FinanceRepository repo;
  bool loading = true;
  List<CreditEntry> credits = [];
  final currency = NumberFormat.simpleCurrency(locale: 'pt_BR');

  @override
  void initState() {
    super.initState();
    repo = context.read<FinanceRepository>();
    _load();
  }

  Future<void> _load() async {
    try {
      setState(() => loading = true);
      await repo.reload();

      final filter = context.read<DateFilterController>();
      final start = filter.effectiveStart;
      final end = filter.effectiveEnd;

      bool inRange(DateTime d) => !d.isBefore(start) && !d.isAfter(end);

      final list = await repo.getCredits();

      if (!mounted) return;
      setState(() {
        credits = list.where((e) => inRange(e.date)).toList();
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

  Future<void> _addOrEdit({CreditEntry? existing}) async {
    final changed = await showDialog<bool>(
      context: context,
      builder: (_) => CreditMonthDialog(existing: existing, repo: repo),
    );
    if (changed == true) _load();
  }

  Future<void> _remove(String id) async {
    await repo.removeCredit(id);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final filter = context.watch<DateFilterController>();

    if (loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final total = credits.fold<double>(0, (p, e) => p + e.amount);

    return Scaffold(
      appBar: AppBar(title: const Text('Crédito')),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          Text('Filtro: ${filter.labelPtBr()}'),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              title: const Text('Total do período'),
              trailing: Text(currency.format(total)),
            ),
          ),
          const SizedBox(height: 8),
          ...credits.map(
            (c) => Card(
              child: ListTile(
                title: Text(c.description),
                subtitle: Text(
                  '${c.category.label} - ${c.person} - ${DateFormat.yMd('pt_BR').format(c.date)}',
                ),
                trailing: Text('- ${currency.format(c.amount)}'),
                onTap: () => _addOrEdit(existing: c),
                onLongPress: () => _remove(c.id),
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
