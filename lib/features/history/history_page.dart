import 'package:finance_control/data/repository.dart';
import 'package:finance_control/features/history/history_details_page.dart';
import 'package:finance_control/features/history/monthly_summary.dart';
import 'package:finance_control/shared/state/date_filter_controller.dart';
import 'package:finance_control/shared/theme/app_colors.dart';
import 'package:finance_control/shared/theme/app_spacing.dart';
import 'package:finance_control/shared/widgets/app_card.dart';
import 'package:finance_control/shared/widgets/app_loading.dart';
import 'package:finance_control/shared/widgets/app_safe_area_shell.dart';
import 'package:finance_control/shared/widgets/section_title.dart';
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
    if (picked != null) filter.setMonth(picked);
  }

  Future<void> _pickRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      locale: const Locale('pt', 'BR'),
      initialDateRange: DateTimeRange(
        start: filter.rangeStart ?? filter.effectiveStart,
        end: filter.rangeEnd ?? filter.effectiveEnd,
      ),
      helpText: 'Selecionar período',
      saveText: 'Aplicar',
    );
    if (picked != null) filter.setRange(picked.start, picked.end);
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
      ).showSnackBar(SnackBar(content: Text('Erro ao carregar histórico: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final f = context.watch<DateFilterController>();

    if (loading || summary == null) return const AppLoading();

    return AppSafeAreaShell(
      child: Scaffold(
        appBar: AppBar(title: const Text('Histórico')),
        body: ListView(
          padding: const EdgeInsets.all(AppSpacing.sm),
          children: [
            SectionTitle(
              title: 'Filtro global ativo',
              subtitle: f.labelPtBr(),
              trailing: ActionChip(
                avatar: const Icon(Icons.date_range, size: 18),
                label: Text(f.useRange ? 'Alterar período' : 'Alterar mês'),
                onPressed: f.useRange ? _pickRange : _pickMonth,
              ),
            ),
            Wrap(
              spacing: AppSpacing.xs,
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
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            _item('Saldo inicial', summary!.initialBalance),
            _item('Débito', -summary!.debitTotal),
            _item('Crédito', -summary!.creditTotal),
            _item('Parcelamentos', -summary!.installmentsTotal),
            _item('Total de saídas', -summary!.totalOut),
            _item(
              'Saldo final',
              summary!.finalBalance,
              color: summary!.finalBalance >= 0
                  ? AppColors.success
                  : AppColors.danger,
            ),
            const SizedBox(height: AppSpacing.sm),
            AppCard(
              child: Align(
                alignment: Alignment.centerLeft,
                child: ActionChip(
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
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }

  Widget _item(String label, double value, {Color? color}) {
    return AppCard(
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(label),
        trailing: Text(
          money.format(value),
          style: TextStyle(fontWeight: FontWeight.w700, color: color),
        ),
      ),
    );
  }
}
