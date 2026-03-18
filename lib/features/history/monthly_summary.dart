class MonthlySummary {
  final int year;
  final int month;
  final double initialBalance;
  final double debitTotal;
  final double creditTotal;
  final double installmentsTotal;

  const MonthlySummary({
    required this.year,
    required this.month,
    required this.initialBalance,
    required this.debitTotal,
    required this.creditTotal,
    required this.installmentsTotal,
  });

  double get totalOut => debitTotal + creditTotal + installmentsTotal;
  double get finalBalance => initialBalance - totalOut;
}
