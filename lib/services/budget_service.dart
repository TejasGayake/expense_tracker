import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class BudgetService {
  static final BudgetService _instance = BudgetService._internal();
  factory BudgetService() => _instance;
  BudgetService._internal();

  static const String _budgetKey = 'category_budgets';

  /// Set budget for a category (monthly)
  Future<void> setBudget(String category, double amount) async {
    final budgets = await getAllBudgets();
    budgets[category] = amount;
    await _saveBudgets(budgets);
  }

  /// Remove budget for a category
  Future<void> removeBudget(String category) async {
    final budgets = await getAllBudgets();
    budgets.remove(category);
    await _saveBudgets(budgets);
  }

  /// Get budget for a category
  Future<double?> getBudget(String category) async {
    final budgets = await getAllBudgets();
    return budgets[category];
  }

  /// Get all budgets
  Future<Map<String, double>> getAllBudgets() async {
    final prefs = await SharedPreferences.getInstance();
    final json_str = prefs.getString(_budgetKey);
    if (json_str == null) return {};
    final Map<String, dynamic> decoded = json.decode(json_str);
    return decoded.map((key, value) => MapEntry(key, (value as num).toDouble()));
  }

  /// Check if a category is over budget
  Future<BudgetStatus> checkBudget(String category, double spent) async {
    final budget = await getBudget(category);
    if (budget == null) return BudgetStatus.noBudget;
    if (spent >= budget) return BudgetStatus.exceeded;
    if (spent >= budget * 0.8) return BudgetStatus.warning;
    return BudgetStatus.underBudget;
  }

  Future<void> _saveBudgets(Map<String, double> budgets) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_budgetKey, json.encode(budgets));
  }
}

enum BudgetStatus {
  noBudget,
  underBudget,
  warning,
  exceeded,
}
