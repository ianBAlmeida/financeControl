import 'dart:convert';
import 'category.dart';

//dinheiro de débito
class DebitEntry {
  final String id;
  final DateTime date;
  final String description;
  final Category category;
  final String person;
  final double amount;

  DebitEntry({
    required this.id,
    required this.date,
    required this.description,
    required this.category,
    required this.person,
    required this.amount,
  });

  //mapeia para salvar em JSON (map)
  Map<String, dynamic> toMap() => {
    'id': id,
    'date': date.toIso8601String(),
    'description': description,
    'category': category.name,
    'person': person,
    'amount': amount,
  };

  //a partir do map, faz uma criação
  factory DebitEntry.fromMap(Map<String, dynamic> map) => DebitEntry(
    id: map['id'],
    date: DateTime.parse(map['date']),
    description: map['description'],
    category: categoryFormString(map['category']),
    person: map['person'],
    amount: (map['amount'] as num).toDouble(),
  );

  //copia apenas alterando o que for passado
  DebitEntry copyWith({
    String? id,
    DateTime? date,
    String? description,
    Category? category,
    String? person,
    double? amount,
  }) {
    return DebitEntry(
      id: id ?? this.id,
      date: date ?? this.date,
      description: description ?? this.description,
      category: category ?? this.category,
      person: person ?? this.person,
      amount: amount ?? this.amount,
    );
  }
}

//gastos no crédito
class CreditEntry {
  final String id;
  final DateTime date;
  final String description;
  final Category category;
  final String person;
  final double amount;

  CreditEntry({
    required this.id,
    required this.date,
    required this.description,
    required this.category,
    required this.person,
    required this.amount,
  });

  //mapeia para salvar em JSON
  Map<String, dynamic> toMap() => {
    'id': id,
    'date': date.toIso8601String(),
    'description': description,
    'category': category.name,
    'person': person,
    'amount': amount,
  };

  //faz a criação
  factory CreditEntry.fromMap(Map<String, dynamic> map) => CreditEntry(
    id: map['id'],
    date: DateTime.parse(map['date']),
    description: map['description'],
    category: categoryFormString(map['category']),
    person: map['person'],
    amount: (map['amount'] as num).toDouble(),
  );

  //copia alterando apenas o que for passado
  CreditEntry copyWith({
    String? id,
    DateTime? date,
    String? description,
    Category? category,
    String? person,
    double? amount,
  }) {
    return CreditEntry(
      id: id ?? this.id,
      date: date ?? this.date,
      description: description ?? this.description,
      category: category ?? this.category,
      person: person ?? this.person,
      amount: amount ?? this.amount,
    );
  }
}

//gastos parcelados (parcela no cartão)
class InstallmentPlan {
  final String id;
  final String description;
  final Category category;
  final String person;
  final double installmentValue;
  final int totalInstallments;
  final int currentInstallment; // parcela atual (1-index)
  final DateTime startDate;

  InstallmentPlan({
    required this.id,
    required this.description,
    required this.category,
    required this.person,
    required this.installmentValue,
    required this.totalInstallments,
    required this.currentInstallment,
    required this.startDate,
  });

  //mapeia para o JSON
  Map<String, dynamic> toMap() => {
    'id': id,
    'description': description,
    'category': category.name,
    'person': person,
    'installmentValue': installmentValue,
    'totalInstallments': totalInstallments,
    'currentInstallment': currentInstallment,
    'startDate': startDate.toIso8601String(),
  };

  //faz a criação
  factory InstallmentPlan.fromMap(Map<String, dynamic> map) => InstallmentPlan(
    id: map['id'],
    description: map['description'],
    category: categoryFormString(map['category']),
    person: map['person'],
    installmentValue: (map['installmentValue'] as num).toDouble(),
    totalInstallments: map['totalInstallments'],
    currentInstallment: map['currentInstallment'],
    startDate: DateTime.parse(map['startDate']),
  );

  //copia alterando somente o que foi passado
  InstallmentPlan copyWith({
    String? id,
    String? description,
    Category? category,
    String? person,
    double? installmentValue,
    int? totalInstallments,
    int? currentInstallment,
    DateTime? startDate,
  }) {
    return InstallmentPlan(
      id: id ?? this.id,
      description: description ?? this.description,
      category: category ?? this.category,
      person: person ?? this.person,
      installmentValue: installmentValue ?? this.installmentValue,
      totalInstallments: totalInstallments ?? this.totalInstallments,
      currentInstallment: currentInstallment ?? this.currentInstallment,
      startDate: startDate ?? this.startDate,
    );
  }
}

// Saldo inicial por mês
class MonthlyBalance {
  final int year;
  final int month;
  final double initialBalance;

  MonthlyBalance({
    required this.year,
    required this.month,
    required this.initialBalance,
  });

  //mesma ideia, deve passar pelo JSON
  Map<String, dynamic> toMap() => {
    'year': year,
    'month': month,
    'initialBalance': initialBalance,
  };

  //criação
  factory MonthlyBalance.fromMap(Map<String, dynamic> map) => MonthlyBalance(
    year: map['year'],
    month: map['month'],
    initialBalance: (map['initialBalance'] as num).toDouble(),
  );
}

//helpers para salvar/listar listas em json
String encodeList<T>(List<T> items, Map<String, dynamic> Function(T) toMap) {
  return jsonEncode(items.map(toMap).toList());
}

List<T> decodeList<T>(
  String? source,
  T Function(Map<String, dynamic>) fromMap,
) {
  if (source == null || source.isEmpty) return [];
  final list = jsonDecode(source) as List<dynamic>;
  return list.map((e) => fromMap(e as Map<String, dynamic>)).toList();
}
