import 'package:finance_control/data/category.dart';
import 'package:finance_control/data/models.dart';

Map<Category, double> sumByCategory(Iterable<dynamic> entries) {
  final Map<Category, double> totals = {};
  for (final e in entries) {
    final cat = switch (e) {
      DebitEntry d => d.category,
      CreditEntry c => c.category,
      InstallmentPlan p => p.category,
      _ => Category.outros,
    };
    final value = switch (e) {
      DebitEntry d => d.amount,
      CreditEntry c => c.amount,
      InstallmentPlan p => p.installmentValue,
      _ => 0.0,
    };
    totals[cat] = (totals[cat] ?? 0) + value;
  }
  return totals;
}
