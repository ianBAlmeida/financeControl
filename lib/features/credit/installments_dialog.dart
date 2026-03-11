import 'package:finance_control/data/category.dart';
import 'package:finance_control/data/models.dart';
import 'package:finance_control/data/repository.dart';
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
  Category selected = Category.outros;
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
      selected = e.category;
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
    final value = double.tryParse(valueCtrl.text.replaceAll(',', '.')) ?? 0;
    final total = int.tryParse(totalCtrl.text) ?? 0;
    final current = int.tryParse(currentCtrl.text) ?? 1;
    if (value <= 0 || total <= 0 || descCtrl.text.isEmpty) return;

    final plan = InstallmentPlan(
      id: widget.existing?.id ?? 'temp',
      description: descCtrl.text,
      category: selected,
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
    final textTheme = Theme.of(context).textTheme;
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ClipRRect(
        borderRadius: BorderRadiusGeometry.circular(16),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.72),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.10),
              width: 1,
            ),
          ),
          child: SingleChildScrollView(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 18,
              bottom: MediaQuery.of(context).viewInsets.bottom + 16,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.existing == null
                      ? 'Novo Parcelamento'
                      : 'Editar Parcelamento',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descCtrl,
                  decoration: const InputDecoration(labelText: 'Descrição'),
                ),
                TextField(
                  controller: personCtrl,
                  decoration: const InputDecoration(labelText: 'Pessoa'),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<Category>(
                  value: selected,
                  decoration: const InputDecoration(labelText: 'Categoria'),
                  items: Category.values
                      .map(
                        (c) => DropdownMenuItem(value: c, child: Text(c.label)),
                      )
                      .toList(),
                  onChanged: (v) =>
                      setState(() => selected = v ?? Category.outros),
                ),
                TextField(
                  controller: valueCtrl,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Valor da parcela',
                  ),
                ),
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
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: currentCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Parcela atual',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Início: ${DateFormat.yMd('pt_BR').format(selectedDate)}',
                        style: textTheme.bodyMedium,
                      ),
                    ),
                    TextButton(
                      onPressed: _pickDate,
                      child: const Text('Selecionar'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _save,
                    child: const Text('Salvar'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
