import 'package:finance_control/data/category.dart';
import 'package:finance_control/data/local_storage.dart';
import 'package:finance_control/data/models.dart';
import 'package:finance_control/data/repository.dart';
import 'package:finance_control/features/credit/installments_dialog.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class InstallmentsPage extends StatefulWidget {
  const InstallmentsPage({super.key});

  @override
  State<InstallmentsPage> createState() => _InstallmentsPageState();
}

class _InstallmentsPageState extends State<InstallmentsPage> {
  late final FinanceRepository repo;
  List<InstallmentPlan> installments = [];
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
      final list = await repo.getInstallments();
      setState(() {
        installments = list;
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => loading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erro ao carregar parcelas: $e')));
    }
  }

  Future<void> _openDialog([InstallmentPlan? existing]) async {
    final changed = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (_) => InstallmentsDialog(existing: existing, repo: repo),
    );
  }

  Future<void> _remove(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Remover parcelamento'),
        content: const Text('Tem certeza que deseja remover o parcelamento?'),
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
      await repo.removeInstallment(id);
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Parcelamentos')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openDialog(),
        child: const Icon(Icons.add),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(12),
          children: [
            if (installments.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 32),
                child: Center(child: Text('Nennhum parcelamento cadastrado')),
              ),
            ...installments.map((plan) {
              final subtitle = [
                plan.category.label,
                plan.person,
                'Início: ${DateFormat.yMd('pt_BR').format(plan.startDate)}',
                'Parcela ${plan.currentInstallment}/${plan.totalInstallments}',
              ].join(' • ');

              return Card(
                child: ListTile(
                  isThreeLine: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  title: Text(plan.description),
                  subtitle: Text(subtitle),
                  trailing: ConstrainedBox(
                    constraints: const BoxConstraints(
                      minWidth: 96,
                      maxWidth: 120,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(currency.format(plan.installmentValue)),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 4,
                          runSpacing: 4,
                          alignment: WrapAlignment.end,
                          children: [
                            IconButton(
                              onPressed: () => _openDialog(plan),
                              icon: const Icon(Icons.edit, size: 20),
                              tooltip: 'Editar',
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, size: 20),
                              onPressed: () => _remove(plan.id),
                              tooltip: 'Remover',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
