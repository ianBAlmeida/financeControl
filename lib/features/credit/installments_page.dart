import 'package:finance_control/data/category.dart';
import 'package:finance_control/data/models.dart';
import 'package:finance_control/data/repository.dart';
import 'package:finance_control/features/credit/installments_dialog.dart';
import 'package:finance_control/shared/state/date_filter_controller.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class InstallmentsPage extends StatefulWidget {
  const InstallmentsPage({super.key});

  @override
  State<InstallmentsPage> createState() => _InstallmentsPageState();
}

class _InstallmentsPageState extends State<InstallmentsPage> {
  late final FinanceRepository repo;
  bool loading = true;
  List<InstallmentPlan> plans = [];
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
      final all = await repo.getInstallments();

      if (!mounted) return;
      setState(() {
        plans = all;
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao carregar parcelamentos: $e')),
      );
    }
  }

  Future<void> _addOrEdit({InstallmentPlan? existing}) async {
    final changed = await showDialog<bool>(
      context: context,
      builder: (_) => InstallmentsDialog(existing: existing, repo: repo),
    );
    if (changed == true) _load();
  }

  Future<void> _remove(String id) async {
    await repo.removeInstallment(id);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final filter = context.watch<DateFilterController>();
    final start = filter.effectiveStart;
    final end = filter.effectiveEnd;

    bool inRange(DateTime d) => !d.isBefore(start) && !d.isAfter(end);

    double periodTotal = 0;
    final visible = <InstallmentPlan>[];

    for (final p in plans) {
      bool hasInPeriod = false;
      for (int i = 0; i < p.totalInstallments; i++) {
        final due = DateTime(
          p.startDate.year,
          p.startDate.month + i,
          p.startDate.day,
        );
        if (inRange(due)) {
          hasInPeriod = true;
          periodTotal += p.installmentValue;
        }
      }
      if (hasInPeriod) visible.add(p);
    }

    if (loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Parcelamentos')),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          Text('Filtro: ${filter.labelPtBr()}'),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              title: const Text('Total de parcelas no período'),
              trailing: Text(currency.format(periodTotal)),
            ),
          ),
          const SizedBox(height: 8),
          ...visible.map(
            (p) => Card(
              child: ListTile(
                title: Text(p.description),
                subtitle: Text(
                  '${p.category.label} - ${p.person}\n'
                  'Início: ${DateFormat.yMd('pt_BR').format(p.startDate)} • ${p.currentInstallment}/${p.totalInstallments}',
                ),
                isThreeLine: true,
                trailing: Text(currency.format(p.installmentValue)),
                onTap: () => _addOrEdit(existing: p),
                onLongPress: () => _remove(p.id),
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
