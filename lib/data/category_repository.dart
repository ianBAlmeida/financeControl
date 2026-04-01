import 'dart:convert';

import 'package:finance_control/features/categories/domain/category_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CategoryRepository {
  static const _key = 'categories_v2';

  Future<List<CategoryModel>> getAll() async {
    final sp = await SharedPreferences.getInstance();
    final raw = sp.getString(_key);
    if (raw == null || raw.isEmpty) {
      return <CategoryModel>[];
    }

    final decoded = jsonDecode(raw) as List<dynamic>;

    return decoded
        .map(
          (item) =>
              CategoryModel.fromMap(Map<String, dynamic>.from(item as Map)),
        )
        .toList();
  }

  Future<void> saveAll(List<CategoryModel> categories) async {
    final sp = await SharedPreferences.getInstance();

    final encoded = jsonEncode(categories.map((c) => c.toMap()).toList());

    await sp.setString(_key, encoded);
  }
}
