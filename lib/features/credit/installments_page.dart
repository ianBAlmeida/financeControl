import 'package:finance_control/data/category.dart';
import 'package:finance_control/data/local_storage.dart';
import 'package:finance_control/data/models.dart';
import 'package:finance_control/data/repository.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class InstallmentsPage extends StatefulWidget {
  const InstallmentsPage({super.key});

  @override
  State<InstallmentsPage> createState() => _InstallmentsPageState();
}

class _InstallmentsPageState extends State<InstallmentsPage> {
  late final FinanceRepository repo;
  List<InstallmentPlan> plans = [];
  bool loading = true;
  final currency = NumberFormat.simpleCurrency(locale: 'pt_BR');

  @override
  void initState() {
    super.initState();
    repo = FinanceRepository(LocalStorage());
    _load();
  }

  Future<void> _load() async {
    setState(() => loading = true);
    final list = await repo.getInstallments();
    setState(() {
      plans = list;
      loading = false;
    });
  }

  Future<void> _addOrEdit(InstallmentPlan? existing) async {
    final descCtrl = TextEditingController(text: existing?.description ?? '');
    final personCtrl = TextEditingController(text: existing?.person ?? '');
    final valueCtrl = TextEditingController(
      text: existing?.installmentValue.toString() ?? '',
    );
    final totalCtrl = TextEditingController(
      text: existing?.totalInstallments.toString() ?? '',
    );
    final currentCtrl = TextEditingController(
      text: existing?.currentInstallment.toString() ?? '1',
    );
    Category selected = existing?.category ?? Category.outros;
    DateTime startDate = existing?.startDate ?? DateTime.now();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsetsGeometry.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: 16 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              existing == null ? 'Novo Parcelamento' : 'Editar Parcelamento',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            SizedBox(height: 12),
            TextField(
              controller: descCtrl,
              decoration: const InputDecoration(labelText: 'Descrição'),
            ),
            SizedBox(height: 12),
            TextField(
              controller: personCtrl,
              decoration: const InputDecoration(labelText: 'Pessoa'),
            ),
            SizedBox(height: 12),
            DropdownButtonFormField<Category>(
              value: selected,
              items: Category.values
                  .map((c) => DropdownMenuItem(value: c, child: Text(c.label)))
                  .toList(),
              onChanged: (c) => selected = c ?? selected,
              decoration: const InputDecoration(labelText: 'Categoria'),
            ),
            SizedBox(height: 12),
            TextField(
              controller: valueCtrl,
              decoration: InputDecoration(labelText: 'Valor da parcela'),
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 12),
            TextField(
              controller: totalCtrl,
              decoration: InputDecoration(labelText: 'Total de parcelas'),
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 12),
            TextField(
              controller: currentCtrl,
              decoration: const InputDecoration(
                labelText: 'Parcela atual (1 = primeira)',
              ),
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 12),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Início: ${DateFormat.yMd('pt_BR').format(startDate)}',
                  ),
                ),
                TextButton(
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: startDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2100),
                    );

                    if (picked != null) {
                      setState(() => startDate = picked);
                    }
                  },
                  child: Text('Selecionar'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () async {
                final value =
                    double.tryParse(valueCtrl.text.replaceAll(',', ',')) ?? 0;
                final total = int.tryParse(totalCtrl.text) ?? 0;
                final current = int.tryParse(currentCtrl.text) ?? 1;
                if (value <= 0 || total < 0 || descCtrl.text.isEmpty) return;
                final plan = InstallmentPlan(
                  id: existing?.id ?? 'temp',
                  description: descCtrl.text,
                  category: selected,
                  person: personCtrl.text.isEmpty ? 'Você' : personCtrl.text,
                  installmentValue: value,
                  totalInstallments: total,
                  currentInstallment: current.clamp(1, total),
                  startDate: startDate,
                );

                if (existing == null) {
                  await repo.addInstallment(plan);
                } else {
                  repo.updateInstallment(plan);
                }
                Navigator.pop(context);
                _load();
              },
              child: const Text('Salvar'),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (loading)
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    return Scaffold(
      appBar: AppBar(title: const Text('Parcelamentos')),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          ...plans.map((p) {
            final progress = '${p.currentInstallment}/${p.totalInstallments}';
            return Card(
              child: ListTile(
                title: Text(p.description),
                subtitle: Text(
                  '${p.category.label} • ${p.person} • ${progress} • Início: • ${DateFormat.yMd('pt_BR').format(p.startDate)}',
                ),
                trailing: Text(currency.format(p.installmentValue)),
                onTap: () => _addOrEdit(p),
                onLongPress: () async {
                  await repo.removeInstallment(p.id);
                  _load();
                },
              ),
            );
          }),
          const SizedBox(height: 64),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addOrEdit(null),
        child: const Icon(Icons.add),
      ),
    );
  }
}
