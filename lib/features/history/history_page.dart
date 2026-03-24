import 'package:finance_control/data/repository.dart';
import 'package:finance_control/features/history/history_details_page.dart';
import 'package:finance_control/features/history/monthly_summary.dart';
import 'package:finance_control/shared/state/date_filter_controller.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  late final FinanceRepository repo;
  late final DateFilterController filter;

  MonthlySummary? summary;
  bool loading = true;

  final money = NumberFormat.simpleCurrency(locale: 'pt_BR');

  @override
  void initState() {
    super.initState();
    repo = context.read<FinanceRepository>();
    filter = context.read<DateFilterController>();

    // escuta mudança global do dashboard
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

  Future<void> _pickMonth() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: filter.selectedMonth,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      locale: const Locale('pt', 'BR'),
      helpText: 'Selecionar mês',
      initialEntryMode: DatePickerEntryMode.calendarOnly,
    );

    if (picked != null) {
      filter.setMonth(picked);
      // _load será chamado automaticamente pelo listener
    }
  }

  Future<void> _pickRange() async {
    final start = filter.rangeStart ?? filter.effectiveStart;
    final end = filter.rangeEnd ?? filter.effectiveEnd;

    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      locale: const Locale('pt', 'BR'),
      initialDateRange: DateTimeRange(
        start: start,
        end: end.isBefore(start) ? start : end,
      ),
      helpText: 'Selecionar período',
      saveText: 'Aplicar',
    );

    if (picked != null) {
      filter.setRange(picked.start, picked.end);
      // _load será chamado automaticamente pelo listener
    }
  }

  Future<void> _load() async {
    setState(() => loading = true);

    try {
      await repo.reload();

      final result = await repo.getRangeSummary(
        filter.effectiveStart,
        filter.effectiveEnd,
      );

      if (!mounted) return;
      setState(() {
        summary = result;
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => loading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erro ao carregar resumo: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    // só para rebuildar a label do filtro
    final f = context.watch<DateFilterController>();

    return Scaffold(
      appBar: AppBar(title: const Text('Resumo')),
      body: loading || summary == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(12),
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ChoiceChip(
                      label: const Text('Mês'),
                      selected: !f.useRange,
                      onSelected: (_) => f.setUseRange(false),
                    ),
                    ChoiceChip(
                      label: const Text('Período'),
                      selected: f.useRange,
                      onSelected: (_) => f.setUseRange(true),
                    ),
                    ActionChip(
                      avatar: const Icon(Icons.date_range, size: 18),
                      label: Text(
                        f.useRange ? 'Alterar período' : 'Alterar mês',
                      ),
                      onPressed: f.useRange ? _pickRange : _pickMonth,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text('Filtro global ativo: ${f.labelPtBr()}'),
                const SizedBox(height: 8),
                Card(
                  child: ListTile(
                    title: const Text('Saldo inicial'),
                    trailing: Text(money.format(summary!.initialBalance)),
                  ),
                ),
                Card(
                  child: ListTile(
                    title: const Text('Débito'),
                    trailing: Text('- ${money.format(summary!.debitTotal)}'),
                  ),
                ),
                Card(
                  child: ListTile(
                    title: const Text('Crédito'),
                    trailing: Text('- ${money.format(summary!.creditTotal)}'),
                  ),
                ),
                Card(
                  child: ListTile(
                    title: const Text('Parcelamentos'),
                    trailing: Text(
                      '- ${money.format(summary!.installmentsTotal)}',
                    ),
                  ),
                ),
                Card(
                  child: ListTile(
                    title: const Text('Total de saídas'),
                    trailing: Text('- ${money.format(summary!.totalOut)}'),
                  ),
                ),
                Card(
                  child: ListTile(
                    title: const Text('Saldo final'),
                    trailing: Text(
                      money.format(summary!.finalBalance),
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: summary!.finalBalance >= 0
                            ? Colors.greenAccent
                            : Colors.redAccent,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                ActionChip(
                  avatar: const Icon(Icons.list_alt, size: 18),
                  label: const Text('Ver detalhes dos gastos'),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => HistoryDetailsPage(
                          start: f.effectiveStart,
                          end: f.effectiveEnd,
                          title: f.useRange
                              ? 'Detalhes do período'
                              : 'Detalhes do mês',
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
    );
  }
}
