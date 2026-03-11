import 'package:finance_control/data/category.dart';
import 'package:finance_control/data/local_storage.dart';
import 'package:finance_control/data/models.dart';
import 'package:finance_control/data/repository.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CreditPage extends StatefulWidget {
  const CreditPage({super.key});

  @override
  State<CreditPage> createState() => _CreditPageState();
}

class _CreditPageState extends State<CreditPage> {
  late final FinanceRepository repo;
  List<CreditEntry> credits = [];
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
    try {
      await repo.reload();
      final now = DateTime.now();
      final list = await repo.getCredits();
      setState(() {
        credits = list
            .where((e) => e.date.year == now.year && e.date.month == now.month)
            .toList();
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

  double get total => credits.fold(0, (p, e) => p + e.amount);

  Future<void> _addOrEdit({CreditEntry? existing}) async {
    final now = existing?.date ?? DateTime.now();
    final descCtrl = TextEditingController(text: existing?.description ?? '');
    final personCtrl = TextEditingController(text: existing?.person ?? '');
    final amountCtrl = TextEditingController(
      text: existing?.amount.toString() ?? '',
    );
    Category selected = existing?.category ?? Category.outros;
    DateTime selecteDate = now;

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
              existing == null ? 'Novo crédito (gasto)' : 'Editar gasto',
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
              decoration: InputDecoration(labelText: 'Pessoa'),
            ),
            SizedBox(height: 12),
            DropdownButtonFormField<Category>(
              value: selected,
              items: Category.values
                  .map((c) => DropdownMenuItem(value: c, child: Text(c.label)))
                  .toList(),
              onChanged: (c) => selected = c ?? selected,
              decoration: InputDecoration(labelText: 'Categoria'),
            ),
            SizedBox(height: 12),
            TextField(
              controller: amountCtrl,
              decoration: const InputDecoration(labelText: 'Valor'),
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 12),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Data: ${DateFormat.yMd('pt_BR').format(selecteDate)}',
                  ),
                ),
                TextButton(
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: selecteDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) {
                      setState(() => selecteDate = picked);
                    }
                  },
                  child: const Text('Selecionar'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () async {
                final amount =
                    double.tryParse(amountCtrl.text.replaceAll(',', '.')) ?? 0;
                if (amount <= 0 || descCtrl.text.isEmpty) return;
                final entry = CreditEntry(
                  id: existing?.id ?? 'temp',
                  date: selecteDate,
                  description: descCtrl.text,
                  category: selected,
                  person: personCtrl.text.isEmpty ? 'Você' : personCtrl.text,
                  amount: amount,
                );
                if (existing == null) {
                  await repo.addCredit(entry);
                } else {
                  await repo.updateCredit(entry);
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
      appBar: AppBar(title: const Text('Crédito (gastos do mês)')),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          Card(
            child: ListTile(
              title: const Text('Total do mês'),
              trailing: Text(currency.format(total)),
            ),
          ),
          ...credits.map(
            (c) => Card(
              child: ListTile(
                title: Text(c.description),
                subtitle: Text(
                  '${c.category.label} - ${c.person} - ${DateFormat.yMd('pt_BR').format(c.date)}',
                ),
                trailing: Text(currency.format(c.amount)),
                onTap: () => _addOrEdit(existing: c),
                onLongPress: () async {
                  await repo.removeCredit(c.id);
                  _load();
                },
              ),
            ),
          ),
          const SizedBox(height: 64),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addOrEdit(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
