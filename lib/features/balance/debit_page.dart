import 'package:finance_control/data/category.dart';
import 'package:finance_control/data/local_storage.dart';
import 'package:finance_control/data/models.dart';
import 'package:finance_control/data/repository.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DebitPage extends StatefulWidget {
  const DebitPage({super.key});

  @override
  State<DebitPage> createState() => _DebitPageState();
}

class _DebitPageState extends State<DebitPage> {
  late final FinanceRepository repo;
  List<DebitEntry> debits = [];
  double initialBalance = 0;
  bool loading = true;
  final currency = NumberFormat.simpleCurrency(locale: 'pt_BR');

  @override
  void initState() {
    super.initState();
    repo = FinanceRepository(LocalStorage());
    _load();
  }

  //Carrega os lançamentos e saldo do mês corrente
  Future<void> _load() async {
    setState(() => loading = true);
    final now = DateTime.now();
    final list = await repo.getDebits();
    final bal = await repo.getInitialBalance(now.year, now.month);
    setState(() {
      debits = list
          .where((e) => e.date.year == now.year && e.date.month == now.month)
          .toList();
      initialBalance = bal;
      loading = false;
    });
  }

  double get totalSpent => debits.fold(0, (p, e) => p + e.amount);
  double get currentBalance => initialBalance - totalSpent;

  //Cria ou edita um lançamento de débito
  Future<void> _editInitialBalance() async {
    final controller = TextEditingController(
      text: initialBalance.toStringAsFixed(2),
    );
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Saldo inicial do mês'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Valor'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              final v =
                  double.tryParse(controller.text.replaceAll(',', '.')) ??
                  initialBalance;
              final now = DateTime.now();
              await repo.setInitialBalance(now.year, now.month, v);
              Navigator.pop(context);
              _load();
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }

  Future<void> _addOrEdit({DebitEntry? existing}) async {
    final now = existing?.date ?? DateTime.now();
    final descCtrl = TextEditingController(text: existing?.description ?? '');
    final personCtrl = TextEditingController(text: existing?.person ?? '');
    final amountCtlr = TextEditingController(
      text: existing?.amount.toString() ?? '',
    );
    Category selected = existing?.category ?? Category.outros;
    DateTime selectedDate = now;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: 16 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              existing == null ? 'Novo débito' : 'Editar débito',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            SizedBox(height: 16),
            TextField(
              controller: descCtrl,
              decoration: const InputDecoration(labelText: 'Descrição'),
            ),
            SizedBox(height: 16),
            TextField(
              controller: personCtrl,
              decoration: const InputDecoration(labelText: 'Pessoa'),
            ),
            SizedBox(height: 16),
            DropdownButtonFormField<Category>(
              value: selected,
              items: Category.values
                  .map((c) => DropdownMenuItem(value: c, child: Text(c.label)))
                  .toList(),
              onChanged: (c) => selected = c ?? selected,
              decoration: const InputDecoration(labelText: 'Categoria'),
            ),
            SizedBox(height: 16),
            TextField(
              controller: amountCtlr,
              decoration: const InputDecoration(labelText: 'Valor'),
            ),
            SizedBox(height: 16),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Data: ${DateFormat.yMd('pt_BR').format(selectedDate)}',
                  ),
                ),
                TextButton(
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: ctx,
                      initialDate: selectedDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) {
                      setState(() => selectedDate = picked);
                    }
                  },
                  child: const Text('Selecionar'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              style: ElevatedButton.styleFrom(),
              onPressed: () async {
                final amount =
                    double.tryParse(amountCtlr.text.replaceAll(',', '.')) ?? 0;
                if (amount <= 0 || descCtrl.text.isEmpty) return;
                final entry = DebitEntry(
                  id: existing?.id ?? 'temp',
                  date: selectedDate,
                  description: descCtrl.text,
                  category: selected,
                  person: personCtrl.text.isEmpty ? 'Você' : personCtrl.text,
                  amount: amount,
                );
                if (existing == null) {
                  await repo.addDebit(entry);
                } else {
                  await repo.updateDebit(entry);
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
      appBar: AppBar(
        title: const Text('Débito'),
        actions: [
          IconButton(
            onPressed: _editInitialBalance,
            icon: const Icon(Icons.edit),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          Card(
            child: ListTile(
              title: const Text('Saldo inicial (mês)'),
              trailing: Text(currency.format(initialBalance)),
              subtitle: Text('Saldo Atual: ${currency.format(currentBalance)}'),
            ),
          ),
          const SizedBox(height: 8),
          ...debits.map(
            (d) => Card(
              child: ListTile(
                title: Text(d.description),
                subtitle: Text(
                  '${d.category.label} - ${d.person} - ${DateFormat.yMd('pt_BR').format(d.date)}',
                ),
                trailing: Text('- ${currency.format(d.amount)}'),
                onTap: () => _addOrEdit(existing: d),
                onLongPress: () async {
                  await repo.removeDebit(d.id);
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
