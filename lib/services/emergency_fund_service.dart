import 'package:shared_preferences/shared_preferences.dart';

class EmergencyFundService {
  static final EmergencyFundService _instance = EmergencyFundService._internal();
  factory EmergencyFundService() => _instance;
  EmergencyFundService._internal();

  static const String _balanceKey = 'emergency_fund_balance';
  static const String _targetKey = 'emergency_fund_target';

  Future<double> getBalance() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_balanceKey) ?? 0;
  }

  Future<void> setBalance(double amount) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_balanceKey, amount);
  }

  Future<void> addToFund(double amount) async {
    final current = await getBalance();
    await setBalance(current + amount);
  }

  Future<double> getTarget() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_targetKey) ?? 0;
  }

  Future<void> setTarget(double amount) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_targetKey, amount);
  }

  Future<double> getProgress() async {
    final balance = await getBalance();
    final target = await getTarget();
    return target > 0 ? (balance / target).clamp(0, 1) : 0;
  }

  Future<void> setTargetFromMonthlySpending(double monthlyAvg) async {
    await setTarget(monthlyAvg * 6); // 6 months of expenses
  }
}
