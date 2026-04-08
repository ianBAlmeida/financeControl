class InstallmentSlice {
  final int installmentNumber;
  final int totalInstallments;

  const InstallmentSlice({
    required this.installmentNumber,
    required this.totalInstallments,
  });
}

int _monthDiff(DateTime from, DateTime to) {
  return (to.year - from.year) * 12 + (to.month - from.month);
}

InstallmentSlice? installmentForMonth({
  required DateTime startDate,
  required int totalInstallments,
  required int currentInstallment,
  required DateTime monthRef,
}) {
  final start = DateTime(startDate.year, startDate.month);
  final ref = DateTime(monthRef.year, monthRef.month);

  final delta = _monthDiff(start, ref);
  final number = currentInstallment + delta;

  if (number < 1 || number > totalInstallments) return null;

  return InstallmentSlice(
    totalInstallments: totalInstallments,
    installmentNumber: number,
  );
}
