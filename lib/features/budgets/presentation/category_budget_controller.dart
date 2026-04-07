import 'package:finance_control/data/category_budget_repository.dart';
import 'package:flutter/foundation.dart';

class CategoryBudgetController extends ChangeNotifier {
  final CategoryBudgetRepository repository;

  CategoryBudgetController(this.repository);

  Map<String, double> _limits = {};
  Map<String, double> get limits => _limits;

  Future<void> load() async {
    final all = await repository.getAll();
    _limits = {for (final b in all) b.categoryId: b.monthlyLimit};
    notifyListeners();
  }

  double? limitOf(String categoryId) => _limits[categoryId];

  Future<void> upsert(String categoryId, double monthlyLimit) async {
    await repository.upsert(categoryId: categoryId, monthlyLimit: monthlyLimit);
    _limits[categoryId] = monthlyLimit;
    notifyListeners();
  }
}
