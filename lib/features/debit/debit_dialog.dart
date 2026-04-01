import 'package:finance_control/data/models.dart';
import 'package:finance_control/data/repository.dart';
import 'package:finance_control/shared/utils/expense_validators.dart';
import 'package:finance_control/shared/utils/input_parses.dart';
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

  String? _selectedCategoryId;
  DateTime selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      descCtrl.text = e.description;
      personCtrl.text = e.person;
      valueCtrl.text = e.amount.toStringAsFixed(2);
      _selectedCategoryId = e.categoryId;
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
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() => selectedDate = picked);
    }
  }

  Future<void> _save() async {
    final value = parsePtBrToDouble(valueCtrl.text);
    final descError = validateDescription(descCtrl.text);
    final valueError = validatePositiveAmount(value);
    final categoryError =
        (_selectedCategoryId == null || _selectedCategoryId!.isEmpty)
        ? 'Selecione uma categoria'
        : null;

    final message =
        descError ?? valueError ?? categoryError ?? 'Dados inválidos';

    if (descError != null || valueError != null || categoryError != null) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
      return;
    }

    final entry = DebitEntry(
      id:
          widget.existing?.id ??
          DateTime.now().microsecondsSinceEpoch.toString(),
      date: selectedDate,
      description: descCtrl.text.trim(),
      categoryId: _selectedCategoryId!,
      person: personCtrl.text.trim().isEmpty ? 'Você' : personCtrl.text.trim(),
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
          const SizedBox(height: 12),
          TextField(
            controller: personCtrl,
            decoration: const InputDecoration(labelText: 'Pessoa'),
          ),
          const SizedBox(height: 12),
          CategoryDropdownField(
            value: _selectedCategoryId,
            onChanged: (v) => setState(() => _selectedCategoryId = v),
          ),
          const SizedBox(height: 12),
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
                  'Data: ${DateFormat.yMd('pt_BR').format(selectedDate)}',
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
