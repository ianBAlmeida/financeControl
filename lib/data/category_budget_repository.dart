import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:finance_control/features/budgets/domain/category_budget.dart';

class CategoryBudgetRepository {
  static const _key = 'category_budgets_v1';

  Future<List<CategoryBudget>> getAll() async {
    final sp = await SharedPreferences.getInstance();
    final raw = sp.getString(_key);
    if (raw == null || raw.isEmpty) return [];

    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .map((e) => CategoryBudget.fromMap(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<void> saveAll(List<CategoryBudget> budgets) async {
    final sp = await SharedPreferences.getInstance();
    final raw = jsonEncode(budgets.map((e) => e.toMap()).toList());
    await sp.setString(_key, raw);
  }

  Future<void> upsert({
    required String categoryId,
    required double monthlyLimit,
  }) async {
    final all = await getAll();
    final i = all.indexWhere((e) => e.categoryId == categoryId);

    final item = CategoryBudget(
      categoryId: categoryId,
      monthlyLimit: monthlyLimit,
    );

    if (i >= 0) {
      all[i] = item;
    } else {
      all.add(item);
    }

    await saveAll(all);
  }

  Future<double?> limitOf(String categoryId) async {
    final all = await getAll();
    for (final b in all) {
      if (b.categoryId == categoryId) return b.monthlyLimit;
    }
    return null;
  }
}
