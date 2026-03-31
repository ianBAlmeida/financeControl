import 'package:finance_control/data/category.dart';
import 'package:finance_control/data/models.dart';
import 'package:finance_control/data/repository.dart';
import 'package:finance_control/features/credit/installments_dialog.dart';
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

class InstallmentsPage extends StatefulWidget {
  const InstallmentsPage({super.key});

  @override
  State<InstallmentsPage> createState() => _InstallmentsPageState();
}

class _InstallmentsPageState extends State<InstallmentsPage> {
  late final FinanceRepository repo;
  late final DateFilterController filter;

  bool loading = true;
  List<InstallmentPlan> plans = [];
  final currency = NumberFormat.simpleCurrency(locale: 'pt_BR');
  final dateFmt = DateFormat.yMd('pt_BR');

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
    try {
      setState(() => loading = true);
      await repo.reload();
      final all = await repo.getInstallments();

      if (!mounted) return;
      setState(() {
        plans = all;
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao carregar parcelamentos: $e')),
      );
    }
  }

  Future<void> _addOrEdit({InstallmentPlan? existing}) async {
    final changed = await showDialog<bool>(
      context: context,
      builder: (_) => InstallmentsDialog(existing: existing, repo: repo),
    );
    if (changed == true) _load();
  }

  Future<void> _remove(String id) async {
    await repo.removeInstallment(id);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final currentFilter = context.watch<DateFilterController>();
    final start = currentFilter.effectiveStart;
    final end = currentFilter.effectiveEnd;

    bool inRange(DateTime d) => !d.isBefore(start) && !d.isAfter(end);

    double periodTotal = 0;
    final visible = <InstallmentPlan>[];

    for (final p in plans) {
      bool hasInPeriod = false;
      for (int i = 0; i < p.totalInstallments; i++) {
        final due = DateTime(
          p.startDate.year,
          p.startDate.month + i,
          p.startDate.day,
        );
        if (inRange(due)) {
          hasInPeriod = true;
          periodTotal += p.installmentValue;
        }
      }
      if (hasInPeriod) visible.add(p);
    }

    if (loading) return const AppLoading();

    return Scaffold(
      appBar: AppBar(title: const Text('Parcelamentos')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.sm),
        children: [
          SectionTitle(
            title: 'Filtro global ativo',
            subtitle: currentFilter.labelPtBr(),
          ),
          AppCard(
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Total de parcelas no filtro'),
              trailing: Text(
                '- ${currency.format(periodTotal)}',
                style: const TextStyle(color: AppColors.warning),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          SectionTitle(
            title: 'Planos no período',
            subtitle: '${visible.length} plano(s)',
          ),
          if (visible.isEmpty)
            const AppCard(
              child: EmptyState(
                icon: Icons.payments_outlined,
                title: 'Sem parcelas no período',
                message: 'Nenhuma parcela cai no filtro selecionado.',
              ),
            )
          else
            ...visible.map(
              (p) => AppCard(
                onTap: () => _addOrEdit(existing: p),
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(p.description),
                  subtitle: Text(
                    '${p.category.label} • ${p.person}\n'
                    'Início: ${dateFmt.format(p.startDate)} • ${p.currentInstallment}/${p.totalInstallments}',
                  ),
                  isThreeLine: true,
                  trailing: Text(currency.format(p.installmentValue)),
                  onLongPress: () => _remove(p.id),
                ),
              ),
            ),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addOrEdit(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
