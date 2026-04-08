import 'package:finance_control/data/models.dart';
import 'package:finance_control/data/repository.dart';
import 'package:finance_control/features/categories/presentation/categories_controller.dart';
import 'package:finance_control/features/dashboard/quick_actions_items.dart';
import 'package:finance_control/features/summary/category_pie_chart.dart';
import 'package:finance_control/features/summary/category_totals.dart';
import 'package:finance_control/shared/state/date_filter_controller.dart';
import 'package:finance_control/shared/theme/app_colors.dart';
import 'package:finance_control/shared/theme/app_spacing.dart';
import 'package:finance_control/shared/utils/installment_period_helper.dart';
import 'package:finance_control/shared/widgets/app_card.dart';
import 'package:finance_control/shared/widgets/app_loading.dart';
import 'package:finance_control/shared/widgets/empty_state.dart';
import 'package:finance_control/shared/widgets/kpi_tile.dart';
import 'package:finance_control/shared/widgets/section_title.dart';
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
  Map<String, double> categoryTotals = {};
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
      filter.setMonth(picked);
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
      filter.setRange(picked.start, picked.end);
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

      final initial = await repo.getInitialBalance(start.year, start.month);

      final debitsPeriod = debits.where((e) => inRange(e.date)).toList();
      final creditsPeriod = credits.where((e) => inRange(e.date)).toList();

      final debitSpent = debitsPeriod.fold<double>(0, (p, e) => p + e.amount);
      final creditSpent = creditsPeriod.fold<double>(0, (p, e) => p + e.amount);

      double installmentsInPeriodTotal = 0;
      final List<InstallmentPlan> installmentsInPeriod = [];

      final Map<String, InstallmentSlice> currentSliceByPlanId = {};

      DateTime monthCursor(DateTime d) => DateTime(d.year, d.month);
      final startMonth = monthCursor(start);
      final endMonth = monthCursor(end);

      for (final plan in installments) {
        bool hasInstallmentInPeriod = false;

        for (
          DateTime m = startMonth;
          !m.isAfter(endMonth);
          m = DateTime(m.year, m.month + 1)
        ) {
          final slice = installmentForMonth(
            startDate: plan.startDate,
            totalInstallments: plan.totalInstallments,
            currentInstallment: plan.currentInstallment,
            monthRef: m,
          );

          if (slice != null) {
            installmentsInPeriodTotal += plan.installmentValue;
            hasInstallmentInPeriod = true;

            currentSliceByPlanId[plan.id] = slice;
          }
        }

        if (hasInstallmentInPeriod) {
          installmentsInPeriod.add(plan);
        }
      }

      final categoryMap = sumByCategoryId([
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
    final categoriesCtrl = context.watch<CategoriesController>();

    if (loading) return const AppLoading();

    final debitCurrent = debitInitial - debitTotalSpent;
    final creditInvoice = creditTotalPeriod + creditInstallmentsPeriod;
    final totalOut = debitTotalSpent + creditInvoice;

    String periodLabel() {
      if (!filter.useRange) return monthFmt.format(filter.selectedMonth);
      return '${dateFmt.format(filter.effectiveStart)} até ${dateFmt.format(filter.effectiveEnd)}';
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: const Text('Controle Financeiro'),
        titleTextStyle: const TextStyle(
          fontSize: 22,
          color: AppColors.textPrimary,
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.sm),
          children: [
            SectionTitle(
              title: 'Filtro global',
              subtitle: periodLabel(),
              trailing: ActionChip(
                avatar: const Icon(Icons.date_range, size: 18),
                label: Text(
                  filter.useRange ? 'Alterar período' : 'Alterar mês',
                ),
                onPressed: () =>
                    filter.useRange ? _pickRange(filter) : _pickMonth(filter),
              ),
            ),
            Wrap(
              spacing: AppSpacing.xs,
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
              ],
            ),
            const SizedBox(height: AppSpacing.sm),

            SectionTitle(title: 'Visão rápida'),
            KpiTile(
              label: 'Saldo atual (débito)',
              value: 'R\$ ${debitCurrent.toStringAsFixed(2)}',
              caption:
                  'Inicial: R\$ ${debitInitial.toStringAsFixed(2)} • Gasto: R\$ ${debitTotalSpent.toStringAsFixed(2)}',
              icon: Icons.account_balance_wallet_outlined,
              valueColor: debitCurrent >= 0
                  ? AppColors.success
                  : AppColors.danger,
              onTap: () => _openRouteAndRefresh('/debit'),
            ),
            KpiTile(
              label: filter.useRange
                  ? 'Fatura total (período)'
                  : 'Fatura total (mês)',
              value: 'R\$ ${creditInvoice.toStringAsFixed(2)}',
              caption:
                  'Crédito: R\$ ${creditTotalPeriod.toStringAsFixed(2)} • Parcelas: R\$ ${creditInstallmentsPeriod.toStringAsFixed(2)}',
              icon: Icons.credit_card,
              valueColor: AppColors.warning,
              onTap: () => _openRouteAndRefresh('/summary'),
            ),
            KpiTile(
              label: 'Total de saídas',
              value: 'R\$ ${totalOut.toStringAsFixed(2)}',
              caption: 'Débito + fatura',
              icon: Icons.trending_down_rounded,
              valueColor: AppColors.danger,
            ),

            const SizedBox(height: AppSpacing.sm),

            SectionTitle(title: 'Atalhos'),
            AppCard(
              child: QuickActionsGrid(
                items: [
                  QuickActionsItems(
                    label: 'Débito',
                    icon: Icons.account_balance_wallet_outlined,
                    onTap: () => _openRouteAndRefresh('/debit'),
                  ),
                  QuickActionsItems(
                    label: 'Crédito',
                    icon: Icons.credit_card,
                    onTap: () => _openRouteAndRefresh('/credit'),
                  ),
                  QuickActionsItems(
                    label: 'Parcelas',
                    icon: Icons.payments,
                    onTap: () => _openRouteAndRefresh('/installments'),
                  ),
                  QuickActionsItems(
                    label: 'Categorias',
                    icon: Icons.category_rounded,
                    onTap: () => _openRouteAndRefresh('/category'),
                  ),
                  QuickActionsItems(
                    label: 'Resumo',
                    icon: Icons.assessment,
                    onTap: () => _openRouteAndRefresh('/summary'),
                  ),
                  QuickActionsItems(
                    label: 'Histórico',
                    icon: Icons.calendar_month,
                    onTap: () => _openRouteAndRefresh('/history'),
                  ),
                  QuickActionsItems(
                    label: 'Metas',
                    icon: Icons.grading_outlined,
                    onTap: () => _openRouteAndRefresh('/category-budget'),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.sm),

            SectionTitle(title: 'Gastos por categoria'),
            if (categoryTotals.isEmpty)
              const AppCard(
                child: EmptyState(
                  icon: Icons.pie_chart_outline,
                  title: 'Sem dados no período selecionado',
                  message: 'Adicione lançamentos para visualizar o gráfico.',
                ),
              )
            else ...[
              AppCard(
                child: SizedBox(
                  height: 240,
                  child: CategoryPieChart(
                    totals: categoryTotals,
                    categoriesCtrl: categoriesCtrl,
                  ),
                ),
              ),
            ],

            const SizedBox(height: AppSpacing.lg),
          ],
        ),
      ),
    );
  }
}
