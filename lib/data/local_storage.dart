import 'package:shared_preferences/shared_preferences.dart';
import 'models.dart';

//Aonde salva/carrega as listas como strings json no dispositivo
class LocalStorage {
  static const _debitsKey = 'debits';
  static const _creditsKey = 'credits';
  static const _installmentsKey = 'installments';
  static const _balancesKey = 'balances';

  //salva
  Future<void> saveDebits(List<DebitEntry> debits) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_debitsKey, encodeList(debits, (e) => e.toMap()));
  }

  //carrega
  Future<List<DebitEntry>> loadDebits() async {
    final prefs = await SharedPreferences.getInstance();
    return decodeList(prefs.getString(_debitsKey), DebitEntry.fromMap);
  }

  Future<void> saveCredits(List<CreditEntry> credits) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_creditsKey, encodeList(credits, (e) => e.toMap()));
  }

  Future<List<CreditEntry>> loadCredits() async {
    final prefs = await SharedPreferences.getInstance();
    return decodeList(prefs.getString(_creditsKey), CreditEntry.fromMap);
  }

  Future<void> saveInstallments(List<InstallmentPlan> plans) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _installmentsKey,
      encodeList(plans, (e) => e.toMap()),
    );
  }

  Future<List<InstallmentPlan>> loadInstallments() async {
    final prefs = await SharedPreferences.getInstance();
    return decodeList(
      prefs.getString(_installmentsKey),
      InstallmentPlan.fromMap,
    );
  }

  Future<void> saveBalances(List<MonthlyBalance> balances) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_balancesKey, encodeList(balances, (e) => e.toMap()));
  }

  Future<List<MonthlyBalance>> loadBalances() async {
    final prefs = await SharedPreferences.getInstance();
    return decodeList(prefs.getString(_balancesKey), MonthlyBalance.fromMap);
  }
}
