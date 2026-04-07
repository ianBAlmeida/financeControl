class CategoryBudget {
  final String categoryId;
  final double monthlyLimit;

  const CategoryBudget({required this.categoryId, required this.monthlyLimit});

  Map<String, dynamic> toMap() => {
    'categoryId': categoryId,
    'monthlyLimit': monthlyLimit,
  };

  factory CategoryBudget.fromMap(Map<String, dynamic> map) => CategoryBudget(
    categoryId: map['categoryId'] as String,
    monthlyLimit: (map['maonthlyLimit'] as num).toDouble(),
  );
}
