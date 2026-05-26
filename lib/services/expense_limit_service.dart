import 'package:shared_preferences/shared_preferences.dart';

class ExpenseLimitService {
  static final ExpenseLimitService _instance = ExpenseLimitService._internal();
  factory ExpenseLimitService() => _instance;
  ExpenseLimitService._internal();

  static const String _dailyKey = 'daily_expense_limit';
  static const String _weeklyKey = 'weekly_expense_limit';

  Future<double?> getDailyLimit() async {
    final prefs = await SharedPreferences.getInstance();
    final v = prefs.getDouble(_dailyKey);
    return v;
  }

  Future<void> setDailyLimit(double? amount) async {
    final prefs = await SharedPreferences.getInstance();
    if (amount == null) { await prefs.remove(_dailyKey); } else { await prefs.setDouble(_dailyKey, amount); }
  }

  Future<double?> getWeeklyLimit() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_weeklyKey);
  }

  Future<void> setWeeklyLimit(double? amount) async {
    final prefs = await SharedPreferences.getInstance();
    if (amount == null) { await prefs.remove(_weeklyKey); } else { await prefs.setDouble(_weeklyKey, amount); }
  }

  Future<double> getTodaySpending(List<Map<String, dynamic>> transactions) async {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    double total = 0;
    for (var txn in transactions) {
      final date = DateTime.fromMillisecondsSinceEpoch(txn['date'] as int);
      if (date.isAfter(todayStart) && (txn['type'] ?? 'expense') != 'income') {
        total += (txn['amount'] as num).toDouble();
      }
    }
    return total;
  }

  Future<double> getWeekSpending(List<Map<String, dynamic>> transactions) async {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final weekStartDate = DateTime(weekStart.year, weekStart.month, weekStart.day);
    double total = 0;
    for (var txn in transactions) {
      final date = DateTime.fromMillisecondsSinceEpoch(txn['date'] as int);
      if (date.isAfter(weekStartDate) && (txn['type'] ?? 'expense') != 'income') {
        total += (txn['amount'] as num).toDouble();
      }
    }
    return total;
  }
}
