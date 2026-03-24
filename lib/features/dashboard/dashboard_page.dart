import 'package:finance_control/data/category.dart';
import 'package:finance_control/data/models.dart';
import 'package:finance_control/data/repository.dart';
import 'package:finance_control/features/summary/category_pie_chart.dart';
import 'package:finance_control/features/summary/category_totals.dart';
import 'package:finance_control/shared/state/date_filter_controller.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  Map<Category, double> categoryTotals = {};
  late final FinanceRepository repo;
  bool loading = true;

  double debitInitial = 0;
  double debitTotalSpent = 0;
  double creditTotalPeriod = 0;
  double creditInstallmentsPeriod = 0;

  final dateFmt = DateFormat.yMd('pt_BR');
  final monthFmt = DateFormat.yMMMM('pt_BR');

  @override
  void initState() {
    super.initState();
    repo = context.read<FinanceRepository>();
    _load();
  }

  Future<void> _openRouteAndRefresh(String path) async {
    await context.push(path);
    if (mounted) await _load();
  }

  Future<void> _pickMonth(DateFilterController filter) async {
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
      filter.setMonth(picked); // global
      _load();
    }
  }

  Future<void> _pickRange(DateFilterController filter) async {
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
      filter.setRange(picked.start, picked.end); // global
      _load();
    }
  }

  Future<void> _load() async {
    setState(() => loading = true);
    try {
      await repo.reload();

      final filter = context.read<DateFilterController>();
      final start = filter.effectiveStart;
      final end = filter.effectiveEnd;

      bool inRange(DateTime d) => !d.isBefore(start) && !d.isAfter(end);

      final debits = await repo.getDebits();
      final credits = await repo.getCredits();
      final installments = await repo.getInstallments();

      // CORREÇÃO: start.month
      final initial = await repo.getInitialBalance(start.year, start.month);

      final debitsPeriod = debits.where((e) => inRange(e.date)).toList();
      final creditsPeriod = credits.where((e) => inRange(e.date)).toList();

      final debitSpent = debitsPeriod.fold<double>(0, (p, e) => p + e.amount);
      final creditSpent = creditsPeriod.fold<double>(0, (p, e) => p + e.amount);

      double installmentsInPeriodTotal = 0;
      final List<InstallmentPlan> installmentsInPeriod = [];

      for (final plan in installments) {
        bool hasInstallmentInPeriod = false;

        for (int i = 0; i < plan.totalInstallments; i++) {
          final due = DateTime(
            plan.startDate.year,
            plan.startDate.month + i,
            plan.startDate.day,
          );

          if (inRange(due)) {
            installmentsInPeriodTotal += plan.installmentValue;
            hasInstallmentInPeriod = true;
          }
        }

        if (hasInstallmentInPeriod) {
          installmentsInPeriod.add(plan);
        }
      }

      final categoryMap = sumByCategory([
        ...debitsPeriod,
        ...creditsPeriod,
        ...installmentsInPeriod,
      ]);

      if (!mounted) return;
      setState(() {
        debitInitial = initial;
        debitTotalSpent = debitSpent;
        creditTotalPeriod = creditSpent;
        creditInstallmentsPeriod = installmentsInPeriodTotal;
        categoryTotals = categoryMap;
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => loading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erro ao carregar dashboard: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final filter = context.watch<DateFilterController>();

    if (loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final debitCurrent = debitInitial - debitTotalSpent;
    final creditInvoice = creditTotalPeriod + creditInstallmentsPeriod;

    String periodLabel() {
      if (!filter.useRange) return monthFmt.format(filter.selectedMonth);
      return '${dateFmt.format(filter.effectiveStart)} até ${dateFmt.format(filter.effectiveEnd)}';
    }

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Controle Financeiro'),
        titleTextStyle: const TextStyle(fontSize: 22),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(12),
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ChoiceChip(
                  label: const Text('Mês'),
                  selected: !filter.useRange,
                  onSelected: (_) {
                    filter.setUseRange(false);
                    _load();
                  },
                ),
                ChoiceChip(
                  label: const Text('Período'),
                  selected: filter.useRange,
                  onSelected: (_) {
                    filter.setUseRange(true);
                    _load();
                  },
                ),
                ActionChip(
                  avatar: const Icon(Icons.date_range, size: 18),
                  label: Text(
                    filter.useRange ? 'Alterar período' : 'Alterar mês',
                  ),
                  onPressed: () =>
                      filter.useRange ? _pickRange(filter) : _pickMonth(filter),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Filtro: ${periodLabel()}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 10),
            _InfoCard(
              title: 'Saldo (débito)',
              value: 'R\$ ${debitCurrent.toStringAsFixed(2)}',
              subtitle:
                  'Inicial: R\$ ${debitInitial.toStringAsFixed(2)} • Gasto: R\$ ${debitTotalSpent.toStringAsFixed(2)}',
              onTap: () => _openRouteAndRefresh('/debit'),
            ),
            _InfoCard(
              title: filter.useRange
                  ? 'Crédito (período)'
                  : 'Crédito (gastos mês)',
              value: 'R\$ ${creditTotalPeriod.toStringAsFixed(2)}',
              subtitle: filter.useRange
                  ? 'Gastos avulsos no período'
                  : 'Gastos avulsos do mês',
              onTap: () => _openRouteAndRefresh('/credit'),
            ),
            _InfoCard(
              title: filter.useRange ? 'Parcelas (período)' : 'Parcelas (mês)',
              value: 'R\$ ${creditInstallmentsPeriod.toStringAsFixed(2)}',
              subtitle: filter.useRange
                  ? 'Parcelas que caem no período'
                  : 'Parcelas que caem este mês',
              onTap: () => _openRouteAndRefresh('/installments'),
            ),
            _InfoCard(
              title: filter.useRange
                  ? 'Fatura total (período)'
                  : 'Fatura total (mês)',
              value: 'R\$ ${creditInvoice.toStringAsFixed(2)}',
              subtitle: filter.useRange
                  ? 'Crédito + parcelas do período'
                  : 'Crédito + parcelas do mês',
              onTap: () => _openRouteAndRefresh('/summary'),
            ),
            const SizedBox(height: 40),
            Wrap(
              spacing: 8,
              runSpacing: 2,
              alignment: WrapAlignment.center,
              children: [
                _NavChip(
                  label: 'Parcelas',
                  icon: Icons.payments,
                  onTap: () => context.go('/installments'),
                ),
                _NavChip(
                  label: 'Resumo',
                  icon: Icons.assessment,
                  onTap: () => context.go('/summary'),
                ),
                _NavChip(
                  label: 'Histórico',
                  icon: Icons.calendar_month,
                  onTap: () => context.go('/history'),
                ),
                const SizedBox(height: 110),
                SizedBox(
                  height: 180,
                  child: CategoryPieChart(totals: categoryTotals),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String title;
  final String value;
  final String? subtitle;
  final VoidCallback onTap;

  const _InfoCard({
    required this.title,
    required this.value,
    required this.onTap,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(title),
        subtitle: subtitle != null ? Text(subtitle!) : null,
        trailing: Text(value, style: Theme.of(context).textTheme.titleLarge),
        onTap: onTap,
      ),
    );
  }
}

class _NavChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _NavChip({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      avatar: Icon(icon, size: 18),
      label: Text(label),
      onPressed: onTap,
    );
  }
}
