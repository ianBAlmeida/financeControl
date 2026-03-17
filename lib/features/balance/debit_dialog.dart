import 'package:finance_control/data/category.dart';
import 'package:finance_control/data/models.dart';
import 'package:finance_control/data/repository.dart';
import 'package:finance_control/shared/widgets/category_dropdown_field.dart';
import 'package:finance_control/shared/widgets/expense_dialog.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DebitDialog extends StatefulWidget {
  const DebitDialog({super.key, required this.existing, required this.repo});

  final FinanceRepository repo;
  final DebitEntry? existing;

  @override
  State<DebitDialog> createState() => _DebitDialogState();
}

class _DebitDialogState extends State<DebitDialog> {
  final descCtrl = TextEditingController();
  final personCtrl = TextEditingController();
  final valueCtrl = TextEditingController();

  Category selected = Category.outros;
  DateTime selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      descCtrl.text = e.description;
      personCtrl.text = e.person;
      valueCtrl.text = e.amount.toStringAsFixed(2);
      selected = e.category;
      selectedDate = e.date;
    }
  }

  @override
  void dispose() {
    descCtrl.dispose();
    personCtrl.dispose();
    valueCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() => selectedDate = picked);
    }
  }

  Future<void> _save() async {
    final value = double.tryParse(valueCtrl.text.replaceAll(',', '.')) ?? 0;
    if (value <= 0 || descCtrl.text.trim().isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Preencha a descrição e valor corretamente'),
        ),
      );
      return;
    }

    final entry = DebitEntry(
      id: widget.existing?.id ?? 'plan',
      date: selectedDate,
      description: descCtrl.text,
      category: selected,
      person: personCtrl.text.isEmpty ? 'Você' : personCtrl.text.trim(),
      amount: value,
    );

    if (widget.existing == null) {
      await widget.repo.addDebit(entry);
    } else {
      await widget.repo.updateDebit(entry);
    }
    if (!mounted) return;
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return ExpenseDialog(
      onSave: _save,
      title: widget.existing == null ? 'Novo débito' : 'Editar débito',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: descCtrl,
            decoration: const InputDecoration(labelText: 'Descrição'),
          ),
          TextField(
            controller: personCtrl,
            decoration: const InputDecoration(labelText: 'Pessoa'),
          ),
          const SizedBox(height: 12),
          CategoryDropdownField(
            value: selected,
            onChanged: (v) => setState(() => selected = v),
          ),
          TextField(
            controller: valueCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'Valor'),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Data ${DateFormat.yMd('pt_BR').format(selectedDate)}',
                ),
              ),
              TextButton(onPressed: _pickDate, child: const Text('Selecionar')),
            ],
          ),
        ],
      ),
    );
  }
}
