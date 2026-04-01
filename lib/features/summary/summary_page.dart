import 'package:finance_control/data/models.dart';
import 'package:finance_control/data/repository.dart';
import 'package:finance_control/features/summary/category_totals.dart';
import 'package:finance_control/shared/state/date_filter_controller.dart';
import 'package:finance_control/shared/theme/app_colors.dart';
import 'package:finance_control/shared/theme/app_spacing.dart';
import 'package:finance_control/shared/widgets/app_card.dart';
import 'package:finance_control/shared/widgets/app_loading.dart';
import 'package:finance_control/shared/widgets/empty_state.dart';
import 'package:finance_control/shared/widgets/section_title.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class SummaryPage extends StatefulWidget {
  const SummaryPage({super.key});

  @override
  State<SummaryPage> createState() => _SummaryPageState();
}

class _SummaryPageState extends State<SummaryPage> {
  late final FinanceRepository repo;
  late final DateFilterController filter;

  bool loading = true;
  String? errorMessage;

  double debitInitial = 0;
  double debitSpent = 0;
  double creditSpent = 0;
  double creditInstallments = 0;

  Map<String, double> creditByPerson = {};
  Map<String, double> creditByPersonWithInstallments = {};
  Map<String, double> categoryTotals = {};

  final currency = NumberFormat.simpleCurrency(locale: 'pt_BR');

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

  Future<void> _load() async {
    setState(() {
      loading = true;
      errorMessage = null;
    });

    try {
      await repo.reload();

      final start = filter.effectiveStart;
      final end = filter.effectiveEnd;
      bool inRange(DateTime d) => !d.isBefore(start) && !d.isAfter(end);

      final debits = await repo.getDebits();
      final credits = await repo.getCredits();
      final installments = await repo.getInstallments();
      final initial = await repo.getInitialBalance(start.year, start.month);

      final debitsPeriod = debits.where((e) => inRange(e.date)).toList();
      final creditsPeriod = credits.where((e) => inRange(e.date)).toList();

      final debitSpentLocal = debitsPeriod.fold<double>(
        0,
        (p, e) => p + e.amount,
      );
      final creditSpentLocal = creditsPeriod.fold<double>(
        0,
        (p, e) => p + e.amount,
      );

      double installmentsInPeriod = 0;
      final List<InstallmentPlan> installmentsForCategory = [];
      final List<InstallmentPlan> installmentsOccurrences = [];

      for (final plan in installments) {
        bool hasAny = false;
        for (int i = 0; i < plan.totalInstallments; i++) {
          final due = DateTime(
            plan.startDate.year,
            plan.startDate.month + i,
            plan.startDate.day,
          );
          if (inRange(due)) {
            installmentsInPeriod += plan.installmentValue;
            hasAny = true;

            installmentsOccurrences.add(
              InstallmentPlan(
                id: plan.id,
                description: plan.description,
                categoryId: plan.categoryId,
                person: plan.person,
                installmentValue: plan.installmentValue,
                totalInstallments: plan.totalInstallments,
                currentInstallment: i + 1,
                startDate: due,
              ),
            );
          }
        }
        if (hasAny) installmentsForCategory.add(plan);
      }

      final Map<String, double> byPerson = {};
      for (final c in creditsPeriod) {
        byPerson[c.person] = (byPerson[c.person] ?? 0) + c.amount;
      }

      final Map<String, double> byPersonWithInst = {...byPerson};
      for (final p in installmentsOccurrences) {
        byPersonWithInst[p.person] =
            (byPersonWithInst[p.person] ?? 0) + p.installmentValue;
      }

      final categoryMap = sumByCategoryId([
        ...debitsPeriod,
        ...creditsPeriod,
        ...installmentsForCategory,
      ]);

      if (!mounted) return;
      setState(() {
        debitInitial = initial;
        debitSpent = debitSpentLocal;
        creditSpent = creditSpentLocal;
        creditInstallments = installmentsInPeriod;
        creditByPerson = byPerson;
        creditByPersonWithInstallments = byPersonWithInst;
        categoryTotals = categoryMap;
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        loading = false;
        errorMessage = 'Falha ao carregar resumo: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentFilter = context.watch<DateFilterController>();

    if (loading) return const AppLoading();

    final debitCurrent = debitInitial - debitSpent;
    final creditInvoice = creditSpent + creditInstallments;
    final projected = debitCurrent - creditInvoice;

    return Scaffold(
      appBar: AppBar(title: const Text('Resumo')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.sm),
          children: [
            SectionTitle(
              title: 'Filtro global ativo',
              subtitle: currentFilter.labelPtBr(),
            ),
            if (errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                child: Text(
                  errorMessage!,
                  style: const TextStyle(color: AppColors.danger),
                ),
              ),

            SectionTitle(title: 'Débito'),
            _infoCard('Saldo inicial', debitInitial),
            _infoCard('Gasto débito', debitSpent),
            _infoCard(
              'Saldo atual',
              debitCurrent,
              valueColor: debitCurrent >= 0
                  ? AppColors.success
                  : AppColors.danger,
            ),

            const SizedBox(height: AppSpacing.sm),
            SectionTitle(title: 'Crédito'),
            _infoCard(
              currentFilter.useRange ? 'Gastos do período' : 'Gastos do mês',
              creditSpent,
            ),
            _infoCard(
              currentFilter.useRange
                  ? 'Parcelas do período'
                  : 'Parcelas do mês',
              creditInstallments,
            ),
            _infoCard(
              currentFilter.useRange
                  ? 'Fatura total (período)'
                  : 'Fatura total (mês)',
              creditInvoice,
            ),

            const SizedBox(height: AppSpacing.sm),
            SectionTitle(title: 'Resumo geral'),
            _infoCard('Saldo projetado (débito - fatura)', projected),

            const SizedBox(height: AppSpacing.sm),
            SectionTitle(
              title: currentFilter.useRange
                  ? 'Crédito por pessoa (período)'
                  : 'Crédito por pessoa (mês)',
            ),
            if (creditByPerson.isEmpty)
              const AppCard(
                child: EmptyState(
                  icon: Icons.people_outline,
                  title: 'Sem dados por pessoa no período',
                ),
              )
            else
              ...creditByPerson.entries.map((e) => _lineRow(e.key, e.value)),

            const SizedBox(height: AppSpacing.sm),
            SectionTitle(
              title: currentFilter.useRange
                  ? 'Crédito + parcelas por pessoa (período)'
                  : 'Crédito + parcelas por pessoa (mês)',
            ),
            if (creditByPersonWithInstallments.isEmpty)
              const AppCard(
                child: EmptyState(
                  icon: Icons.groups_outlined,
                  title: 'Sem dados consolidados por pessoa',
                ),
              )
            else
              ...creditByPersonWithInstallments.entries.map(
                (e) => _lineRow(e.key, e.value),
              ),

            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }

  Widget _infoCard(String label, double value, {Color? valueColor}) {
    return AppCard(
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(label),
        trailing: Text(
          currency.format(value),
          style: TextStyle(fontWeight: FontWeight.w700, color: valueColor),
        ),
      ),
    );
  }

  Widget _lineRow(String label, double value) {
    return AppCard(
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Text(currency.format(value)),
        ],
      ),
    );
  }
}
