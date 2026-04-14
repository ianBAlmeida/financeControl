class CategoryModel {
  final String id;
  final String name;
  final String colorHex;
  final int order;
  final bool isArchived;

  const CategoryModel({
    required this.id,
    required this.name,
    required this.colorHex,
    required this.order,
    this.isArchived = false,
  });

  CategoryModel copyWith({
    String? id,
    String? name,
    String? colorHex,
    int? order,
    bool? isArchived,
  }) {
    return CategoryModel(
      id: id ?? this.id,
      name: name ?? this.name,
      colorHex: colorHex ?? this.colorHex,
      order: order ?? this.order,
      isArchived: isArchived ?? this.isArchived,
    );
  }

  // Compatibilidade com chamadas antigas
  CategoryModel copywith({
    String? id,
    String? name,
    String? colorHex,
    int? order,
    bool? isArchived,
  }) {
    return copyWith(
      id: id,
      name: name,
      colorHex: colorHex,
      order: order,
      isArchived: isArchived,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'colorHex': colorHex,
    'order': order,
    'isArchived': isArchived, // corrigido
  };

  factory CategoryModel.fromMap(Map<String, dynamic> map) => CategoryModel(
    id: map['id'],
    name: map['name'],
    colorHex: map['colorHex'],
    order: map['order'] ?? 0,
    isArchived: map['isArchived'] ?? false,
  );
}
