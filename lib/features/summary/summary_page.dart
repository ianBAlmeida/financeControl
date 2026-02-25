import 'package:finance_control/data/category.dart';
import 'package:finance_control/data/local_storage.dart';
import 'package:finance_control/data/models.dart';
import 'package:finance_control/data/repository.dart';
import 'package:finance_control/features/summary/category_pie_chart.dart';
import 'package:finance_control/features/summary/category_totals.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class SummaryPage extends StatefulWidget {
  const SummaryPage({super.key});

  @override
  State<SummaryPage> createState() => _SummaryPageState();
}

class _SummaryPageState extends State<SummaryPage> {
  late final FinanceRepository repo;
  bool loading = true;
  double debitInitial = 0;
  double debitSpent = 0;
  double creditSpent = 0;
  double creditInstallments = 0;
  Map<String, double> creditByPerson = {};
  Map<String, double> creditByPersonWithInstallments = {};
  Map<Category, double> categoryTotals = {};
  final currency = NumberFormat.simpleCurrency(locale: 'pt_BR');

  @override
  void initState() {
    super.initState();
    repo = FinanceRepository(LocalStorage());
    _load();
  }

  Future<void> _load() async {
    setState(() => loading = true);
    final now = DateTime.now();
    final debits = await repo.getDebits();
    final credits = await repo.getCredits();
    final installments = await repo.getInstallments();
    final initial = await repo.getInitialBalance(now.year, now.month);

    final debitsMonth = debits.where(
      (e) => e.date.year == now.year && e.date.month == now.month,
    );
    final creditsMonth = credits.where(
      (e) => e.date.year == now.year && e.date.month == now.month,
    );

    final debitSpentLocal = debitsMonth.fold<double>(0, (p, e) => p + e.amount);
    final creditSpentLocal = creditsMonth.fold<double>(
      0,
      (p, e) => p + e.amount,
    );

    double installmentsThisMonth = 0;
    final List<InstallmentPlan> installmentsInMonth = [];
    for (final plan in installments) {
      final monthsDiff =
          (now.year - plan.startDate.year) * 12 +
          (now.month - plan.startDate.month);
      final current = monthsDiff + 1;
      if (current >= 1 && current <= plan.totalInstallments) {
        installmentsThisMonth += plan.installmentValue;
        installmentsInMonth.add(plan);
      }
    }

    Map<String, double> byPerson = {};
    for (final c in creditsMonth) {
      byPerson[c.person] = (byPerson[c.person] ?? 0) + c.amount;
    }

    Map<String, double> byPersonWithInst = {...byPerson};
    for (final p in installmentsInMonth) {
      byPersonWithInst[p.person] =
          (byPersonWithInst[p.person] ?? 0) + p.installmentValue;
    }

    final categoryMap = sumByCategory([
      ...debitsMonth,
      ...creditsMonth,
      ...installmentsInMonth,
    ]);

    setState(() {
      debitInitial = initial;
      debitSpent = debitSpentLocal;
      creditSpent = creditSpentLocal;
      creditInstallments = installmentsThisMonth;
      creditByPerson = byPerson;
      creditByPersonWithInstallments = byPersonWithInst;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (loading)
      return const Scaffold(body: Center(child: CircularProgressIndicator()));

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
            _selectionTitle('Débito'),
            _infoRow('Saldo inicial ', debitInitial),
            _infoRow('Gasto débito', creditSpent),
            _infoRow('Saldo atual', debitCurrent),
            const SizedBox(height: 12),

            _selectionTitle('Crédito'),
            _infoRow('Gastos do mês', creditSpent),
            _infoRow('Parcelas do mês', creditInstallments),
            _infoRow('Fatura Total (mês)', creditInvoice),
            const SizedBox(height: 12),

            _selectionTitle('Resumo geral'),
            _infoRow('Saldo projetado (débito - fatura)', projected),
            const SizedBox(height: 12),

            _selectionTitle('Crédito por pessoa (mês)'),
            ...creditByPerson.entries.map((e) => _infoRow(e.key, e.value)),
            const SizedBox(height: 12),

            _selectionTitle('Crédito + parcelas por pessoa (mês)'),
            ...creditByPersonWithInstallments.entries.map(
              (e) => _infoRow(e.key, e.value),
            ),
            const SizedBox(height: 12),

            _selectionTitle('Por categoria (mês)'),
            SizedBox(child: CategoryPieChart(totals: categoryTotals)),
            SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _selectionTitle(String text) {
    return Padding(
      padding: const EdgeInsetsGeometry.only(bottom: 6),
      child: Text(text, style: Theme.of(context).textTheme.titleMedium),
    );
  }

  Widget _infoRow(String label, double value) {
    return Padding(
      padding: const EdgeInsetsGeometry.symmetric(vertical: 4, horizontal: 8),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Text(currency.format(value)),
        ],
      ),
    );
  }
}
