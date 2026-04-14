import 'package:finance_control/data/models.dart';
import 'package:finance_control/data/repository.dart';
import 'package:finance_control/features/categories/presentation/categories_controller.dart';
import 'package:finance_control/features/credit/credit_month_dialog.dart';
import 'package:finance_control/shared/state/date_filter_controller.dart';
import 'package:finance_control/shared/theme/app_colors.dart';
import 'package:finance_control/shared/theme/app_spacing.dart';
import 'package:finance_control/shared/theme/gradient_scaffold.dart';
import 'package:finance_control/shared/widgets/app_card.dart';
import 'package:finance_control/shared/widgets/app_loading.dart';
import 'package:finance_control/shared/widgets/empty_state.dart';
import 'package:finance_control/shared/widgets/section_title.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class CreditPage extends StatefulWidget {
  const CreditPage({super.key});

  @override
  State<CreditPage> createState() => _CreditPageState();
}

class _CreditPageState extends State<CreditPage> {
  late final FinanceRepository repo;
  late final DateFilterController filter;

  bool loading = true;
  List<CreditEntry> credits = [];
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

      final start = filter.effectiveStart;
      final end = filter.effectiveEnd;
      bool inRange(DateTime d) => !d.isBefore(start) && !d.isAfter(end);

      final list = await repo.getCredits();

      if (!mounted) return;
      setState(() {
        credits = list.where((e) => inRange(e.date)).toList();
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => loading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erro ao carregar créditos: $e')));
    }
  }

  Future<void> _addOrEdit({CreditEntry? existing}) async {
    final changed = await showDialog<bool>(
      context: context,
      builder: (_) => CreditMonthDialog(existing: existing, repo: repo),
    );
    if (changed == true) _load();
  }

  Future<void> _remove(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Remover crédito'),
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
      await repo.removeCredit(id);
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentFilter = context.watch<DateFilterController>();
    final categoriesCtrl = context.watch<CategoriesController>();

    if (loading) return const AppLoading();

    final total = credits.fold<double>(0, (p, e) => p + e.amount);

    return AppGradientScaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text('Crédito'),
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
              title: const Text('Total no filtro'),
              trailing: Text(
                '- ${currency.format(total)}',
                style: const TextStyle(color: AppColors.warning),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          SectionTitle(
            title: 'Lançamentos',
            subtitle: '${credits.length} item(ns)',
          ),
          if (credits.isEmpty)
            const AppCard(
              child: EmptyState(
                icon: Icons.credit_card_off_outlined,
                title: 'Sem gastos no crédito',
                message: 'Adicione um lançamento de crédito para começar.',
              ),
            )
          else
            ...credits.map(
              (c) => AppCard(
                onTap: () => _addOrEdit(existing: c),
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(c.description),
                  subtitle: Text(
                    '${categoriesCtrl.nameOf(c.categoryId)} • ${c.person} • ${dateFmt.format(c.date)}',
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '- ${currency.format(c.amount)}',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        tooltip: 'Editar',
                        onPressed: () => _addOrEdit(existing: c),
                        icon: const Icon(Icons.edit_outlined),
                      ),
                      IconButton(
                        tooltip: 'Excluir',
                        onPressed: () => _remove(c.id),
                        icon: const Icon(Icons.delete_forever_outlined),
                      ),
                    ],
                  ),
                  onTap: () => _addOrEdit(existing: c),
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
