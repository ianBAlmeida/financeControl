import 'package:finance_control/data/local_storage.dart';
import 'package:finance_control/data/repository.dart';
import 'package:finance_control/features/history/history_details_page.dart';
import 'package:finance_control/features/history/monthly_summary.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  late final FinanceRepository repo;

  bool useRange = false;

  late DateTime selectedMonth;

  DateTime? rangeStart;
  DateTime? rangeEnd;

  MonthlySummary? summary;
  bool loading = true;

  final money = NumberFormat.simpleCurrency(locale: 'pt_BR');
  final dateFmt = DateFormat.yMd('pt_BR');
  final monthFmt = DateFormat.yMMMM('pt_BR');

  @override
  void initState() {
    super.initState();
    repo = FinanceRepository(LocalStorage());

    final now = DateTime.now();
    selectedMonth = DateTime(now.year, now.month, 1);
    rangeStart = DateTime(now.year, now.month, 1);
    rangeEnd = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

    _load();
  }

  DateTime get _effectiveStart {
    if (!useRange) return DateTime(selectedMonth.year, selectedMonth.month, 1);
    return rangeStart ?? DateTime(selectedMonth.year, selectedMonth.month, 1);
  }

  DateTime get _effectiveEnd {
    if (!useRange) {
      return DateTime(
        selectedMonth.year,
        selectedMonth.month + 1,
        0,
        23,
        59,
        59,
      );
    }
    return rangeEnd ??
        DateTime(selectedMonth.year, selectedMonth.month + 1, 0, 23, 59, 59);
  }

  Future<void> _load() async {
    setState(() => loading = true);

    await repo.ensureLoaded();

    MonthlySummary result;
    if (useRange) {
      result = await repo.getRangeSummary(_effectiveStart, _effectiveEnd);
    } else {
      result = await repo.getMonthlySummary(
        selectedMonth.year,
        selectedMonth.month,
      );
    }

    if (!mounted) return;
    setState(() {
      summary = result;
      loading = false;
    });
  }

  Future<void> _pickMonth() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedMonth,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      locale: const Locale('pt', 'BR'),
      helpText: 'Selecionar mês',
      initialEntryMode: DatePickerEntryMode.calendarOnly,
    );

    if (picked != null) {
      setState(() {
        selectedMonth = DateTime(picked.year, picked.month, 1);
      });
      _load();
    }
  }

  Future<void> _pickRange() async {
    final initialStart =
        rangeStart ?? DateTime(selectedMonth.year, selectedMonth.month, 1);
    final initialEnd =
        rangeEnd ?? DateTime(selectedMonth.year, selectedMonth.month + 1, 0);

    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      locale: const Locale('pt', 'BR'),
      initialDateRange: DateTimeRange(
        start: initialStart,
        end: initialEnd.isBefore(initialStart) ? initialStart : initialEnd,
      ),
      helpText: 'Selecionar período',
      saveText: 'Aplicar',
    );

    if (picked != null) {
      setState(() {
        rangeStart = DateTime(
          picked.start.year,
          picked.start.month,
          picked.start.day,
        );
        rangeEnd = DateTime(
          picked.end.year,
          picked.end.month,
          picked.end.day,
          23,
          59,
          59,
        );
      });
      _load();
    }
  }

  String get _filterLabel {
    if (!useRange) return monthFmt.format(selectedMonth);
    return '${dateFmt.format(_effectiveStart)} até ${dateFmt.format(_effectiveEnd)}';
  }

  @override
  Widget build(BuildContext context) {
    final data = summary;

    return Scaffold(
      appBar: AppBar(title: const Text('Resumo')),
      body: loading || data == null
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
                      selected: !useRange,
                      onSelected: (_) {
                        setState(() => useRange = false);
                        _load();
                      },
                    ),
                    ChoiceChip(
                      label: const Text('Período'),
                      selected: useRange,
                      onSelected: (_) {
                        setState(() => useRange = true);
                        _load();
                      },
                    ),
                    ActionChip(
                      avatar: const Icon(Icons.date_range, size: 18),
                      label: Text(useRange ? 'Alterar período' : 'Alterar mês'),
                      onPressed: useRange ? _pickRange : _pickMonth,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Card(
                  child: ListTile(
                    title: const Text('Filtro atual'),
                    subtitle: Text(_filterLabel),
                  ),
                ),
                const SizedBox(height: 8),
                Card(
                  child: ListTile(
                    title: const Text('Saldo inicial'),
                    trailing: Text(money.format(data.initialBalance)),
                  ),
                ),
                Card(
                  child: ListTile(
                    title: const Text('Débito'),
                    trailing: Text('- ${money.format(data.debitTotal)}'),
                  ),
                ),
                Card(
                  child: ListTile(
                    title: const Text('Crédito'),
                    trailing: Text('- ${money.format(data.creditTotal)}'),
                  ),
                ),
                Card(
                  child: ListTile(
                    title: const Text('Parcelamentos'),
                    trailing: Text('- ${money.format(data.installmentsTotal)}'),
                  ),
                ),
                const SizedBox(height: 8),
                Card(
                  child: ListTile(
                    title: const Text('Total de saídas'),
                    trailing: Text('- ${money.format(data.totalOut)}'),
                  ),
                ),
                Card(
                  child: ListTile(
                    title: const Text('Saldo final'),
                    trailing: Text(
                      money.format(data.finalBalance),
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: data.finalBalance >= 0
                            ? Colors.greenAccent
                            : Colors.redAccent,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: ActionChip(
                    avatar: const Icon(Icons.list_alt, size: 18),
                    label: const Text('Ver detalhes dos gastos'),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => HistoryDetailsPage(
                            start: _effectiveStart,
                            end: _effectiveEnd,
                            title: useRange
                                ? 'Detalhes do período'
                                : 'Detalhes do mês',
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
    );
  }
}
