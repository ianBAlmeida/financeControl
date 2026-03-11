import 'package:finance_control/data/category.dart';
import 'package:finance_control/data/local_storage.dart';
import 'package:finance_control/data/models.dart';
import 'package:finance_control/data/repository.dart';
import 'package:finance_control/features/summary/category_pie_chart.dart';
import 'package:finance_control/features/summary/category_totals.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
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
  double creditTotalMonth = 0;
  double creditInstallmentsMonth = 0;

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

  Future<void> _load() async {
    setState(() => loading = true);
    try {
      await repo.reload();
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

      final debitSpent = debitsMonth.fold<double>(0, (p, e) => p + e.amount);
      final creditSpent = creditsMonth.fold<double>(0, (p, e) => p + e.amount);

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

      final categoryMap = sumByCategory([
        ...debitsMonth,
        ...creditsMonth,
        ...installmentsInMonth,
      ]);

      setState(() {
        debitInitial = initial;
        debitTotalSpent = debitSpent;
        creditTotalMonth = creditSpent;
        creditInstallmentsMonth = installmentsThisMonth;
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
    if (loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final debitCurrent = debitInitial - debitTotalSpent;
    final creditInvoice = creditTotalMonth + creditInstallmentsMonth;

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text('Controle Financeiro'),
        titleTextStyle: TextStyle(fontSize: 22),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(12),
          children: [
            _InfoCard(
              title: 'Saldo (débito)',
              value: 'R\$ ${debitCurrent.toStringAsFixed(2)}',
              subtitle:
                  'Inicial: R\$ ${debitInitial.toStringAsFixed(2)} • Gasto: R\$ ${debitTotalSpent.toStringAsFixed(2)}',
              onTap: () => _openRouteAndRefresh('/debit'),
            ),
            _InfoCard(
              title: 'Crédito (gastos mês)',
              value: 'R\$ ${creditTotalMonth.toStringAsFixed(2)}',
              subtitle: 'Gastos avulsos do mês',
              onTap: () => _openRouteAndRefresh('/credit'),
            ),
            _InfoCard(
              title: 'Parcelas (mês)',
              value: 'R\$ ${creditInstallmentsMonth.toStringAsFixed(2)}',
              subtitle: 'Parcelas que caem este mês',
              onTap: () => _openRouteAndRefresh('/installments'),
            ),
            _InfoCard(
              title: 'Fatura total (mês)',
              value: 'R\$ ${creditInvoice.toStringAsFixed(2)}',
              subtitle: 'Crédito + parcelas do mês',
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
