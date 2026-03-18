import 'package:finance_control/features/history/monthly_summary.dart';
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

  Future<MonthlySummary> getMonthlySummary(int year, int month) async {
    await ensureLoaded();

    final initial = await getInitialBalance(year, month);

    final debitTotal = _debits
        .where((e) => e.date.year == year && e.date.month == month)
        .fold<double>(0, (p, e) => p + e.amount);

    final crefitTotal = _credits
        .where((e) => e.date.year == year && e.date.month == month)
        .fold<double>(0, (p, e) => p + e.amount);

    final installmentsTotal = _installments
        .where((e) {
          final start = DateTime(e.startDate.year, e.startDate.month);
          final target = DateTime(year, month);
          final diffMonths = (target.year) * 12 + (target.month - start.month);
          return diffMonths >= 0 && diffMonths < e.totalInstallments;
        })
        .fold<double>(0, (p, e) => p + e.installmentValue);

    return MonthlySummary(
      year: year,
      month: month,
      initialBalance: initial,
      debitTotal: debitTotal,
      creditTotal: crefitTotal,
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

    final installmentTotal = _installments
        .where((p) {
          for (int i = 0; i < p.totalInstallments; i++) {
            final due = DateTime(
              p.startDate.year,
              p.startDate.month,
              p.startDate.day,
            );
            if (inRange(due)) return true;
          }
          return false;
        })
        .fold<double>(0, (sum, p) {
          int count = 0;
          for (int i = 0; i < p.totalInstallments; i++) {
            final due = DateTime(
              p.startDate.year,
              p.startDate.month,
              p.startDate.day,
            );
            if (inRange(due)) count++;
          }
          return sum + (count * p.installmentValue);
        });

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
