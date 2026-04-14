import 'package:finance_control/data/models.dart';
import 'package:finance_control/data/repository.dart';
import 'package:finance_control/features/categories/presentation/categories_controller.dart';
import 'package:finance_control/features/credit/installments_dialog.dart';
import 'package:finance_control/shared/state/date_filter_controller.dart';
import 'package:finance_control/shared/theme/app_colors.dart';
import 'package:finance_control/shared/theme/app_spacing.dart';
import 'package:finance_control/shared/theme/gradient_scaffold.dart';
import 'package:finance_control/shared/utils/installment_period_helper.dart';
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
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Remover parcelamento'),
        content: const Text('Tem certeza que deseja remover esse lançamento?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remover'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await repo.removeInstallment(id);
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentFilter = context.watch<DateFilterController>();
    final categoriesCtrl = context.watch<CategoriesController>();

    // Mês de referência do filtro atual
    final selected = currentFilter.effectiveStart;
    final monthRef = DateTime(selected.year, selected.month, 1);

    double periodTotal = 0;
    final visible = <InstallmentPlan>[];
    final Map<String, InstallmentSlice> currentSliceByPlanId = {};

    for (final p in plans) {
      final slice = installmentForMonth(
        startDate: p.startDate,
        totalInstallments: p.totalInstallments,
        currentInstallment: p.currentInstallment,
        monthRef: monthRef,
      );

      if (slice != null) {
        visible.add(p);
        periodTotal += p.installmentValue;
        currentSliceByPlanId[p.id] = slice;
      }
    }

    if (loading) return const AppLoading();

    return AppGradientScaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text('Parcelamentos'),
      ),
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
              title: const Text('Total de parcelas no mês'),
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
            ...visible.map((p) {
              final slice = currentSliceByPlanId[p.id];
              final dueLabel = slice == null
                  ? '-'
                  : '${slice.installmentNumber}/${slice.totalInstallments}';

              return AppCard(
                onTap: () => _addOrEdit(existing: p),
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(p.description),
                  subtitle: Text(
                    '${categoriesCtrl.nameOf(p.categoryId)} • ${p.person}\n'
                    'Início: ${dateFmt.format(p.startDate)}\n• Parcela atual: $dueLabel',
                  ),
                  isThreeLine: true,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        currency.format(p.installmentValue),
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        tooltip: 'Editar',
                        onPressed: () => _addOrEdit(existing: p),
                        icon: const Icon(Icons.edit_outlined),
                      ),
                      IconButton(
                        tooltip: 'Excluir',
                        onPressed: () => _remove(p.id),
                        icon: const Icon(Icons.delete_forever_outlined),
                      ),
                    ],
                  ),
                ),
              );
            }),
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
