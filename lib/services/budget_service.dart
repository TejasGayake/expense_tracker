import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class BudgetService {
  static final BudgetService _instance = BudgetService._internal();
  factory BudgetService() => _instance;
  BudgetService._internal();

  static const String _budgetKey = 'category_budgets';

  Map<String, double> _budgets = {};

  /// Cached budgets (read-only view)
  Map<String, double> get budgets => Map.unmodifiable(_budgets);

  /// Pre-load budgets into memory (call at app startup)
  Future<void> loadBudgets() async {
    _budgets = await _fetchBudgets();
  }

  /// Set budget for a category (monthly)
  Future<void> setBudget(String category, double amount) async {
    _budgets[category] = amount;
    await _saveBudgets(_budgets);
  }

  /// Remove budget for a category
  Future<void> removeBudget(String category) async {
    _budgets.remove(category);
    await _saveBudgets(_budgets);
  }

  /// Get budget for a category (synchronous, uses cache)
  double? getBudget(String category) => _budgets[category];

  /// Get all budgets (synchronous, uses cache)
  Map<String, double> getAllBudgets() => Map.unmodifiable(_budgets);

  /// Fetch budgets from SharedPreferences
  Future<Map<String, double>> _fetchBudgets() async {
    final prefs = await SharedPreferences.getInstance();
    final json_str = prefs.getString(_budgetKey);
    if (json_str == null) return {};
    final Map<String, dynamic> decoded = json.decode(json_str);
    return decoded.map((key, value) => MapEntry(key, (value as num).toDouble()));
  }

  /// Check if a category is over budget
  BudgetStatus checkBudget(String category, double spent) {
    final budget = _budgets[category];
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
