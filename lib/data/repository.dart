import 'package:finance_control/features/history/monthly_summary.dart';
import 'package:finance_control/shared/utils/installment_period_helper.dart';
import 'package:uuid/uuid.dart';
import 'local_storage.dart';
import 'models.dart';

//Mantém cache em memória e persiste via LocalStorage
class FinanceRepository {
  FinanceRepository(this._storage);

  final LocalStorage _storage;
  final _uuid = const Uuid();

  //Cache em memória
  List<DebitEntry> _debits = [];
  List<CreditEntry> _credits = [];
  List<InstallmentPlan> _installments = [];
  List<MonthlyBalance> _balances = [];
  bool _loaded = false;

  Future<void> reload() async {
    _loaded = false;
    await ensureLoaded();
  }

  //Garante que os dados foram carregados uma vez
  Future<void> ensureLoaded() async {
    if (_loaded) return;
    _debits = await _storage.loadDebits();
    _credits = await _storage.loadCredits();
    _installments = await _storage.loadInstallments();
    _balances = await _storage.loadBalances();
    _loaded = true;
  }

  // Débito
  Future<List<DebitEntry>> getDebits() async {
    await ensureLoaded();
    return _debits;
  }

  Future<void> addDebit(DebitEntry entry) async {
    await ensureLoaded();
    final newEntry = entry.copyWith(id: _uuid.v4());
    _debits = [..._debits, newEntry];
    await _storage.saveDebits(_debits);
  }

  Future<void> updateDebit(DebitEntry entry) async {
    await ensureLoaded();
    _debits = _debits.map((e) => e.id == entry.id ? entry : e).toList();
    await _storage.saveDebits(_debits);
  }

  Future<void> removeDebit(String id) async {
    await ensureLoaded();
    _debits = _debits.where((e) => e.id != id).toList();
    await _storage.saveDebits(_debits);
  }

  // Crédito
  Future<List<CreditEntry>> getCredits() async {
    await ensureLoaded();
    return _credits;
  }

  Future<void> addCredit(CreditEntry entry) async {
    await ensureLoaded();
    final newEntry = entry.copyWith(id: _uuid.v4());
    _credits = [..._credits, newEntry];
    await _storage.saveCredits(_credits);
  }

  Future<void> updateCredit(CreditEntry entry) async {
    await ensureLoaded();
    _credits = _credits.map((e) => e.id == entry.id ? entry : e).toList();
    await _storage.saveCredits(_credits);
  }

  Future<void> removeCredit(String id) async {
    await ensureLoaded();
    _credits = _credits.where((e) => e.id != id).toList();
    await _storage.saveCredits(_credits);
  }

  // Parcelamentos
  Future<List<InstallmentPlan>> getInstallments() async {
    await ensureLoaded();
    return _installments;
  }

  Future<void> addInstallment(InstallmentPlan plan) async {
    await ensureLoaded();
    final newEntry = plan.copyWith(id: _uuid.v4());
    _installments = [..._installments, newEntry];
    await _storage.saveInstallments(_installments);
  }

  Future<void> updateInstallment(InstallmentPlan plan) async {
    await ensureLoaded();
    _installments = _installments
        .map((e) => e.id == plan.id ? plan : e)
        .toList();
    await _storage.saveInstallments(_installments);
  }

  Future<void> removeInstallment(String id) async {
    await ensureLoaded();
    _installments = _installments.where((e) => e.id != id).toList();
    await _storage.saveInstallments(_installments);
  }

  // Saldo inicial por mês
  Future<double> getInitialBalance(int year, int month) async {
    await ensureLoaded();
    final found = _balances.firstWhere(
      (b) => b.year == year && b.month == month,
      orElse: () => MonthlyBalance(year: year, month: month, initialBalance: 0),
    );
    return found.initialBalance;
  }

  Future<void> setInitialBalance(int year, int month, double value) async {
    await ensureLoaded();
    final idx = _balances.indexWhere((b) => b.year == year && b.month == month);
    if (idx >= 0) {
      _balances[idx] = MonthlyBalance(
        year: year,
        month: month,
        initialBalance: value,
      );
    } else {
      _balances = [
        ..._balances,
        MonthlyBalance(year: year, month: month, initialBalance: value),
      ];
    }
    await _storage.saveBalances(_balances);
  }

  Future<MonthlySummary> getMonthlySummary(DateTime start, DateTime end) async {
    await ensureLoaded();

    bool inRange(DateTime d) => !d.isBefore(start) && !d.isAfter(end);

    final debitTotal = _debits
        .where((e) => inRange(e.date))
        .fold<double>(0, (p, e) => p + e.amount);

    final creditTotal = _credits
        .where((e) => inRange(e.date))
        .fold<double>(0, (p, e) => p + e.amount);

    DateTime monthCursor(DateTime d) => DateTime(d.year, d.month, 1);
    final startMonth = monthCursor(start);
    final endMonth = monthCursor(end);

    double installmentsTotal = 0;

    for (final p in _installments) {
      for (
        DateTime m = startMonth;
        !m.isAfter(endMonth);
        m = DateTime(m.year, m.month + 1)
      ) {
        final slice = installmentForMonth(
          startDate: p.startDate,
          totalInstallments: p.totalInstallments,
          currentInstallment: p.currentInstallment, // âncora da regra nova
          monthRef: m,
        );

        if (slice != null) {
          installmentsTotal += p.installmentValue;
        }
      }
    }

    final initial = await getInitialBalance(start.year, start.month);

    return MonthlySummary(
      year: start.year,
      month: start.month,
      initialBalance: initial,
      debitTotal: debitTotal,
      creditTotal: creditTotal,
      installmentsTotal: installmentsTotal,
    );
  }

  Future<MonthlySummary> getRangeSummary(DateTime start, DateTime end) async {
    await ensureLoaded();

    bool inRange(DateTime d) => !d.isBefore(start) && !d.isAfter(end);

    final debitTotal = _debits
        .where((e) => inRange(e.date))
        .fold<double>(0, (p, e) => p + e.amount);

    final creditTotal = _credits
        .where((e) => inRange(e.date))
        .fold<double>(0, (p, e) => p + e.amount);

    DateTime monthOnly(DateTime d) => DateTime(d.year, d.month, 1);
    final startMonth = monthOnly(start);
    final endMonth = monthOnly(end);

    double installmentTotal = 0;

    for (final p in _installments) {
      for (
        DateTime m = startMonth;
        !m.isAfter(endMonth);
        m = DateTime(m.year, m.month + 1)
      ) {
        final slice = installmentForMonth(
          startDate: p.startDate,
          totalInstallments: p.totalInstallments,
          currentInstallment: p.currentInstallment,
          monthRef: m,
        );

        if (slice != null) {
          installmentTotal += p.installmentValue;
        }
      }
    }

    final initial = await getInitialBalance(start.year, start.month);

    return MonthlySummary(
      year: start.year,
      month: start.month,
      initialBalance: initial,
      debitTotal: debitTotal,
      creditTotal: creditTotal,
      installmentsTotal: installmentTotal,
    );
  }
}
