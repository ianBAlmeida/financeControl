import 'package:finance_control/data/category_repository.dart';
import 'package:flutter/foundation.dart';
import 'package:finance_control/features/categories/domain/category_model.dart';

class CategoriesController extends ChangeNotifier {
  final CategoryRepository repository;
  CategoriesController(this.repository);

  List<CategoryModel> _all = [];
  List<CategoryModel> get all => _all;
  List<CategoryModel> get active =>
      _all.where((c) => !c.isArchived).toList()
        ..sort((a, b) => a.order.compareTo(b.order));

  Future<void> load() async {
    _all = await repository.getAll();
    notifyListeners();
  }

  CategoryModel? byId(String id) {
    for (final c in _all) {
      if (c.id == id) return c;
    }
    return null;
  }

  String nameOf(String id) => byId(id)?.name ?? 'Sem categoria';

  Future<void> create({required String name, required String colorHex}) async {
    final normalizedName = name.trim();
    if (normalizedName.isEmpty) return;

    final baseId = _slug(normalizedName);
    final uniqueId = _ensureUniqueId(baseId);

    final nextOrder = _all.isEmpty
        ? 0
        : (_all.map((e) => e.order).reduce((a, b) => a > b ? a : b) + 1);

    final created = CategoryModel(
      id: uniqueId,
      name: name,
      colorHex: colorHex,
      order: nextOrder,
      isArchived: false,
    );

    _all = [..._all, created];
    await repository.saveAll(_all);
    notifyListeners();
  }

  Future<void> update(CategoryModel updated) async {
    final index = _all.indexWhere((c) => c.id == updated.id);
    if (index < 0) return;

    _all[index] = updated;
    await repository.saveAll(_all);
    notifyListeners();
  }

  Future<void> archiveToggle(String id) async {
    final index = _all.indexWhere((c) => c.id == id);
    if (index < 0) return;

    final current = _all[index];
    _all[index] = current.copywith(isArchived: !current.isArchived);

    await repository.saveAll(_all);
    notifyListeners();
  }

  String _slug(String input) {
    final lower = input.toLowerCase().trim();

    final noAccents = lower
        .replaceAll('á', 'a')
        .replaceAll('à', 'a')
        .replaceAll('â', 'a')
        .replaceAll('ã', 'a')
        .replaceAll('é', 'e')
        .replaceAll('ê', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ô', 'o')
        .replaceAll('õ', 'o')
        .replaceAll('ú', 'u')
        .replaceAll('ç', 'c');

    final onlyValid = noAccents
        .replaceAll(RegExp(r'[^a-z0-9\s-]'), '')
        .replaceAll(RegExp(r'\s+'), '-')
        .replaceAll(RegExp(r'-+'), '-')
        .replaceAll(RegExp(r'^-|-$'), '');

    return onlyValid.isEmpty ? 'categoria' : onlyValid;
  }

  String _ensureUniqueId(String baseId) {
    var id = baseId;
    var i = 1;
    while (_all.any((c) => c.id == id)) {
      id = '$baseId-$i';
      i++;
    }
    return id;
  }
}
