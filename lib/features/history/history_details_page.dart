import 'package:finance_control/data/repository.dart';
import 'package:finance_control/features/categories/domain/presentation/categories_controller.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

enum HistoryItemType { debit, credit, installment }

class HistoryItem {
  final HistoryItemType type;
  final DateTime date;
  final String description;
  final String? categoryId;
  final String person;
  final double amount;
  final String? extra;

  const HistoryItem({
    required this.type,
    required this.date,
    required this.description,
    required this.categoryId,
    required this.person,
    required this.amount,
    this.extra,
  });
}

class HistoryDetailsPage extends StatefulWidget {
  const HistoryDetailsPage({
    super.key,
    required this.start,
    required this.end,
    required this.title,
  });

  final DateTime start;
  final DateTime end;
  final String title;

  @override
  State<HistoryDetailsPage> createState() => _HistoryDetailsPageState();
}

class _HistoryDetailsPageState extends State<HistoryDetailsPage> {
  late final FinanceRepository repo;
  final money = NumberFormat.simpleCurrency(locale: 'pt_BR');
  final dateFmt = DateFormat.yMd('pt_BR');

  bool loading = true;
  List<HistoryItem> items = [];

  @override
  void initState() {
    super.initState();
    repo = context.read<FinanceRepository>();
  }

  bool _inRange(DateTime d) {
    return !d.isBefore(widget.start) && !d.isAfter(widget.end);
  }

  Future<void> _load() async {
    setState(() => loading = true);
    await repo.ensureLoaded();

    final debits = await repo.getDebits();
    final credits = await repo.getCredits();
    final installments = await repo.getInstallments();

    final list = <HistoryItem>[];

    // Débitos
    for (final d in debits) {
      if (_inRange(d.date)) {
        list.add(
          HistoryItem(
            type: HistoryItemType.debit,
            date: d.date,
            description: d.description,
            categoryId: d.categoryId,
            person: d.person,
            amount: d.amount,
          ),
        );
      }
    }

    // Créditos
    for (final c in credits) {
      if (_inRange(c.date)) {
        list.add(
          HistoryItem(
            type: HistoryItemType.credit,
            date: c.date,
            description: c.description,
            categoryId: c.categoryId,
            person: c.person,
            amount: c.amount,
          ),
        );
      }
    }

    // Parcelamentos (cada parcela no período vira uma linha)
    for (final p in installments) {
      for (int i = 0; i < p.totalInstallments; i++) {
        final due = DateTime(
          p.startDate.year,
          p.startDate.month + i,
          p.startDate.day,
        );

        if (_inRange(due)) {
          list.add(
            HistoryItem(
              type: HistoryItemType.installment,
              date: due,
              description: p.description,
              categoryId: p.categoryId,
              person: p.person,
              amount: p.installmentValue,
              extra: 'Parcela ${i + 1}/${p.totalInstallments}',
            ),
          );
        }
      }
    }

    list.sort((a, b) => b.date.compareTo(a.date));

    if (!mounted) return;
    setState(() {
      items = list;
      loading = false;
    });
  }

  String _typeLabel(HistoryItemType type) {
    switch (type) {
      case HistoryItemType.debit:
        return 'Débito';
      case HistoryItemType.credit:
        return 'Crédito';
      case HistoryItemType.installment:
        return 'Parcelado';
    }
  }

  Color _typeColor(HistoryItemType type) {
    switch (type) {
      case HistoryItemType.debit:
        return Colors.orangeAccent;
      case HistoryItemType.credit:
        return Colors.lightBlueAccent;
      case HistoryItemType.installment:
        return Colors.purpleAccent;
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoriesCtrl = context.watch<CategoriesController>();
    final subtitlePeriod =
        '${dateFmt.format(widget.start)} até ${dateFmt.format(widget.end)}';

    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
                  child: Card(
                    child: ListTile(
                      title: const Text('Período'),
                      subtitle: Text(subtitlePeriod),
                      trailing: Text(
                        '${items.length} item(ns)',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: items.isEmpty
                      ? const Center(
                          child: Text('Nenhum gasto encontrado no período'),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(12, 6, 12, 12),
                          itemCount: items.length,
                          itemBuilder: (context, index) {
                            final item = items[index];
                            return Card(
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: _typeColor(
                                    item.type,
                                  ).withValues(alpha: 0.18),
                                  child: Icon(
                                    item.type == HistoryItemType.debit
                                        ? Icons.account_balance_wallet_outlined
                                        : item.type == HistoryItemType.credit
                                        ? Icons.credit_card
                                        : Icons.view_timeline,
                                    color: _typeColor(item.type),
                                  ),
                                ),
                                title: Text(item.description),
                                subtitle: Text(
                                  '${_typeLabel(item.type)} • ${categoriesCtrl.nameOf(item.categoryId!)} • ${item.person}\n'
                                  '${dateFmt.format(item.date)}'
                                  '${item.extra != null ? ' • ${item.extra}' : ''}',
                                ),
                                isThreeLine: true,
                                trailing: Text(
                                  '- ${money.format(item.amount)}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}
