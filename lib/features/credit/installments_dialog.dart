import 'package:finance_control/data/models.dart';
import 'package:finance_control/data/repository.dart';
import 'package:finance_control/shared/utils/expense_validators.dart';
import 'package:finance_control/shared/utils/input_parses.dart';
import 'package:finance_control/shared/widgets/category_dropdown_field.dart';
import 'package:finance_control/shared/widgets/expense_dialog.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class InstallmentsDialog extends StatefulWidget {
  const InstallmentsDialog({
    super.key,
    required this.existing,
    required this.repo,
  });

  final FinanceRepository repo;
  final InstallmentPlan? existing;

  @override
  State<InstallmentsDialog> createState() => _InstallmentsDialogState();
}

class _InstallmentsDialogState extends State<InstallmentsDialog> {
  final descCtrl = TextEditingController();
  final personCtrl = TextEditingController(text: 'Você');
  final valueCtrl = TextEditingController();
  final totalCtrl = TextEditingController(text: '1');
  final currentCtrl = TextEditingController(text: '1');
  String? _selectedCategoryId;
  DateTime selectedDate = DateTime.now();
  final currency = NumberFormat.simpleCurrency(locale: 'pt_BR');

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      descCtrl.text = e.description;
      personCtrl.text = e.person;
      valueCtrl.text = e.installmentValue.toStringAsFixed(2);
      totalCtrl.text = e.totalInstallments.toString();
      currentCtrl.text = e.currentInstallment.toString();
      _selectedCategoryId = e.categoryId;
      selectedDate = e.startDate;
    }
  }

  @override
  void dispose() {
    descCtrl.dispose();
    personCtrl.dispose();
    valueCtrl.dispose();
    totalCtrl.dispose();
    currentCtrl.dispose();
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
    final total = int.tryParse(totalCtrl.text) ?? 0;
    final current = int.tryParse(currentCtrl.text) ?? 0;

    final value = parsePtBrToDouble(valueCtrl.text);

    final descError = validateDescription(descCtrl.text);
    final valueError = validatePositiveAmount(value);
    final installmentError = validateIntallmentRange(current, total);

    final message =
        descError ?? valueError ?? installmentError ?? 'Dados inválidos';

    if (descError != null || valueError != null || installmentError != null) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }

    final plan = InstallmentPlan(
      id: widget.existing?.id ?? 'temp',
      description: descCtrl.text,
      categoryId: _selectedCategoryId!,
      person: personCtrl.text.isEmpty ? 'Você' : personCtrl.text,
      installmentValue: value,
      totalInstallments: total,
      currentInstallment: current,
      startDate: selectedDate,
    );

    if (widget.existing == null) {
      await widget.repo.addInstallment(plan);
    } else {
      await widget.repo.updateInstallment(plan);
    }
    if (!mounted) return;
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return ExpenseDialog(
      title: widget.existing == null
          ? 'Novo Parcelamento'
          : 'Editar Parcelamento',
      onSave: _save,
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
            decoration: const InputDecoration(labelText: 'Valor da parcela'),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: totalCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Total de parcelas',
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: currentCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Parcela Atual'),
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Início ${DateFormat.yMd('pt_BR').format(selectedDate)}',
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
