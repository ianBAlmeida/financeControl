import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class MigrationV2Categories {
  static const _schemaKey = 'schema_version';
  static const _target = 2;

  static const _debitKey = 'debits';
  static const _creditKey = 'credits';
  static const _installmentsKey = 'installments';
  static const _categoriesKey = 'categories_v2';

  Future<void> run() async {
    final sp = await SharedPreferences.getInstance();
    final current = sp.getInt(_schemaKey) ?? 1;
    if (current >= _target) return;

    final categories = [
      _cat('moradia', 'Moradia', '#4F46E5', 0),
      _cat('alimentacao', 'Alimentação', '#06B6D4', 1),
      _cat('transporte', 'Transporte', '#10B981', 2),
      _cat('lazer', 'Lazer', '#F59E0B', 3),
      _cat('saude', 'Saúde', '#EF4444', 4),
      _cat('educacao', 'Educação', '#8B5CF6', 5),
      _cat('outros', 'Outros', '#9CA3AF', 99),
    ];
    await sp.setString(_categoriesKey, jsonEncode(categories));

    await _migrateList(sp, _debitKey);
    await _migrateList(sp, _creditKey);
    await _migrateList(sp, _installmentsKey);

    await sp.setInt(_schemaKey, _target);
  }

  Future<void> _migrateList(SharedPreferences sp, String key) async {
    final raw = sp.getString(key);
    if (raw == null || raw.isEmpty) return;

    final list = (jsonDecode(raw) as List<dynamic>)
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();

    for (final item in list) {
      final oldCategory = (item['category'] ?? '').toString();
      item['category'] = _mapOldCategoryToId(oldCategory);
    }
    await sp.setString(key, jsonEncode(list));
  }

  String _mapOldCategoryToId(String value) {
    final v = value.trim().toLowerCase();

    if (v.contains('moradia') || v.contains('casa')) return 'moradia';
    if (v.contains('aliment')) return 'alimentacao';
    if (v.contains('transporte') || v.contains('combust')) return 'transporte';
    if (v.contains('lazer') || v.contains('entreten')) return 'lazer';
    if (v.contains('saude') || v.contains('saúde') || v.contains('farm'))
      return 'saude';
    if (v.contains('educ')) return 'educacao';

    return 'outros';
  }

  Map<String, dynamic> _cat(
    String id,
    String name,
    String colorHex,
    int order,
  ) {
    return {
      'id': id,
      'name': name,
      'colorHex': colorHex,
      'order': order,
      'isArchived': false,
    };
  }
}
