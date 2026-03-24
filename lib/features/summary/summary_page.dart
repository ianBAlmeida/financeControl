import 'package:finance_control/data/category.dart';
import 'package:finance_control/data/models.dart';
import 'package:finance_control/data/repository.dart';
import 'package:finance_control/features/summary/category_totals.dart';
import 'package:finance_control/shared/state/date_filter_controller.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

// Tela de resumo geral (integrada ao filtro global)
class SummaryPage extends StatefulWidget {
  const SummaryPage({super.key});

  @override
  State<SummaryPage> createState() => _SummaryPageState();
}

class _SummaryPageState extends State<SummaryPage> {
  late final FinanceRepository repo;

  bool loading = true;
  String? errorMessage;

  double debitInitial = 0;
  double debitSpent = 0;
  double creditSpent = 0;
  double creditInstallments = 0;

  Map<String, double> creditByPerson = {};
  Map<String, double> creditByPersonWithInstallments = {};
  Map<Category, double> categoryTotals = {};

  final currency = NumberFormat.simpleCurrency(locale: 'pt_BR');
  final dateFmt = DateFormat.yMd('pt_BR');

  @override
  void initState() {
    super.initState();
    repo = context.read<FinanceRepository>();
    _load();
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
    setState(() {
      loading = true;
      errorMessage = null;
    });

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

            // ocorrência "virtual" para somar por pessoa corretamente por parcela no período
            installmentsOccurrences.add(
              InstallmentPlan(
                id: plan.id,
                description: plan.description,
                category: plan.category,
                person: plan.person,
                installmentValue: plan.installmentValue,
                totalInstallments: plan.totalInstallments,
                currentInstallment: i + 1,
                startDate: due,
              ),
            );
          }
        }

        if (hasAny) {
          installmentsForCategory.add(plan);
        }
      }

      // crédito avulso por pessoa
      final Map<String, double> byPerson = {};
      for (final c in creditsPeriod) {
        byPerson[c.person] = (byPerson[c.person] ?? 0) + c.amount;
      }

      // crédito + parcelas (por ocorrência no período)
      final Map<String, double> byPersonWithInst = {...byPerson};
      for (final p in installmentsOccurrences) {
        byPersonWithInst[p.person] =
            (byPersonWithInst[p.person] ?? 0) + p.installmentValue;
      }

      final categoryMap = sumByCategory([
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erro ao carregar resumo: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final filter = context.watch<DateFilterController>();

    if (loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final debitCurrent = debitInitial - debitSpent;
    final creditInvoice = creditSpent + creditInstallments;
    final projected = debitCurrent - creditInvoice;

    return Scaffold(
      appBar: AppBar(title: const Text('Resumo')),
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
            const SizedBox(height: 8),
            Text('Filtro: ${filter.labelPtBr()}'),
            const SizedBox(height: 12),

            if (errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  errorMessage!,
                  style: const TextStyle(color: Colors.red),
                ),
              ),

            _sectionTitle('Débito'),
            _cardInfo('Saldo inicial', debitInitial),
            _cardInfo('Gasto débito', debitSpent),
            _cardInfo('Saldo atual', debitCurrent),
            const SizedBox(height: 12),

            _sectionTitle('Crédito'),
            _cardInfo(
              filter.useRange ? 'Gastos do período' : 'Gastos do mês',
              creditSpent,
            ),
            _cardInfo(
              filter.useRange ? 'Parcelas do período' : 'Parcelas do mês',
              creditInstallments,
            ),
            _cardInfo(
              filter.useRange ? 'Fatura total (período)' : 'Fatura total (mês)',
              creditInvoice,
            ),
            const SizedBox(height: 12),

            _sectionTitle('Resumo geral'),
            _cardInfo('Saldo projetado (débito - fatura)', projected),
            const SizedBox(height: 12),

            _sectionTitle(
              filter.useRange
                  ? 'Crédito por pessoa (período)'
                  : 'Crédito por pessoa (mês)',
            ),
            if (creditByPerson.isEmpty)
              const Text('Sem lançamentos no filtro atual.')
            else
              ...creditByPerson.entries.map((e) => _infoRow(e.key, e.value)),
            const SizedBox(height: 8),

            _sectionTitle(
              filter.useRange
                  ? 'Crédito + parcelas por pessoa (período)'
                  : 'Crédito + parcelas por pessoa (mês)',
            ),
            if (creditByPersonWithInstallments.isEmpty)
              const Text('Sem lançamentos no filtro atual.')
            else
              ...creditByPersonWithInstallments.entries.map(
                (e) => _infoRow(e.key, e.value),
              ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text, style: Theme.of(context).textTheme.titleMedium),
    );
  }

  Widget _cardInfo(String label, double value) {
    return Card(
      child: ListTile(
        title: Text(label),
        trailing: Text(currency.format(value)),
      ),
    );
  }

  Widget _infoRow(String label, double value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Text(currency.format(value)),
        ],
      ),
    );
  }
}
