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
                child: Padding(
                  padding: const EdgeInsetsGeometry.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              plan.description,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              subtitle,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 8),

                      ConstrainedBox(
                        constraints: const BoxConstraints(
                          minWidth: 90,
                          maxWidth: 110,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              currency.format(plan.installmentValue),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.titleSmall
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),

                            const SizedBox(height: 12),

                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                InkWell(
                                  borderRadius: BorderRadius.circular(20),
                                  onTap: () => _openDialog(plan),
                                  child: const Padding(
                                    padding: EdgeInsetsGeometry.all(6),
                                    child: Icon(Icons.edit, size: 18),
                                  ),
                                ),
                                InkWell(
                                  borderRadius: BorderRadius.circular(20),
                                  onTap: () => _remove(plan.id),
                                  child: const Padding(
                                    padding: EdgeInsetsGeometry.all(6),
                                    child: Icon(Icons.delete, size: 18),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
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
