import 'package:finance_control/data/models.dart';

Map<String, double> sumByCategoryId(Iterable<dynamic> entries) {
  final Map<String, double> totals = {};
  for (final e in entries) {
    final cat = switch (e) {
      DebitEntry d => d.categoryId,
      CreditEntry c => c.categoryId,
      InstallmentPlan p => p.categoryId,
      _ => 'outros',
    };
    final double value = switch (e) {
      DebitEntry d => d.amount,
      CreditEntry c => c.amount,
      InstallmentPlan p => p.installmentValue,
      _ => 0.0,
    };
    totals[cat] = (totals[cat] ?? 0) + value;
  }
  return totals;
}
