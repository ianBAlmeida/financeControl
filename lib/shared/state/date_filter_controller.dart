import 'package:flutter/material.dart';

class DateFilterController extends ChangeNotifier {
  bool useRange = false;
  late DateTime selectedMonth;
  DateTime? rangeStart;
  DateTime? rangeEnd;

  DateFilterController() {
    final now = DateTime.now();
    selectedMonth = DateTime(now.year, now.month, 1);
    rangeStart = DateTime(now.year, now.month, 1);
    rangeEnd = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
  }

  DateTime get effectiveStart {
    if (!useRange) return DateTime(selectedMonth.year, selectedMonth.month, 1);
    return rangeStart ?? DateTime(selectedMonth.year, selectedMonth.month, 1);
  }

  DateTime get effectiveEnd {
    if (!useRange) {
      return DateTime(
        selectedMonth.year,
        selectedMonth.month + 1,
        0,
        23,
        59,
        59,
      );
    }
    return rangeEnd ??
        DateTime(selectedMonth.year, selectedMonth.month + 1, 0, 23, 59, 59);
  }

  void setUseRange(bool value) {
    useRange = value;
    notifyListeners();
  }

  void setMonth(DateTime date) {
    selectedMonth = DateTime(date.year, date.month, 1);
    useRange = false;
    notifyListeners();
  }

  void setRange(DateTime start, DateTime end) {
    rangeStart = DateTime(start.year, start.month, start.day);
    rangeEnd = DateTime(end.year, end.month, end.day, 23, 59, 59);
    useRange = true;
    notifyListeners();
  }

  String labelPtBr() {
    if (!useRange) {
      const months = [
        '',
        'janeiro',
        'fevereiro',
        'março',
        'abril',
        'maio',
        'junho',
        'julho',
        'agosto',
        'setembro',
        'outubro',
        'novembro',
        'dezembro',
      ];
      return '${months[selectedMonth.month]} de ${selectedMonth.year}';
    }
    String two(int n) => n.toString().padLeft(2, '0');
    final s = effectiveStart;
    final e = effectiveEnd;
    return '${two(s.day)}/${two(s.month)}/${s.year} até ${two(e.day)}/${two(e.month)}/${e.year}';
  }
}
