import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../services/database_service.dart';
import '../services/budget_service.dart';
import '../services/settings_service.dart';

class BudgetScreen extends StatefulWidget {
  const BudgetScreen({super.key});

  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen> {
  final DatabaseService _db = DatabaseService();
  final BudgetService _budgetService = BudgetService();
  final SettingsService _settings = SettingsService();

  List<Map<String, dynamic>> _budgetItems = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final categories = await _db.getCategories();
      final budgets = _budgetService.getAllBudgets();
      final transactions = await _db.getTransactions();

      final now = DateTime.now();
      final currentMonthTransactions = transactions.where((txn) {
        final date = DateTime.fromMillisecondsSinceEpoch(txn['date']);
        return date.month == now.month && date.year == now.year;
      }).toList();

      // Calculate spending per category ID
      Map<String, double> categorySpending = {};
      for (var txn in currentMonthTransactions) {
        final catId = txn['categoryId'] as String? ?? '';
        final amount = (txn['amount'] as num).toDouble();
        if (catId.isNotEmpty) {
          categorySpending[catId] = (categorySpending[catId] ?? 0) + amount;
        }
      }

      List<Map<String, dynamic>> items = [];
      for (var cat in categories) {
        final catId = cat['id'] as String;
        final name = cat['name'] as String;
        final budget = budgets[catId];
        final spent = categorySpending[catId] ?? 0.0;
        final icon = cat['icon'] as String? ?? '📦';
        final color = Color(cat['color'] as int);

        items.add({
          'id': catId,
          'name': name,
          'icon': icon,
          'color': color,
          'budget': budget,
          'spent': spent,
          'progress': budget != null && budget > 0 ? (spent / budget).clamp(0.0, 1.0) : 0.0,
        });
      }

      // Sort: items with budgets first, then by spending percentage descending
      items.sort((a, b) {
        final aHas = a['budget'] != null;
        final bHas = b['budget'] != null;
        if (aHas && !bHas) return -1;
        if (!aHas && bHas) return 1;
        if (aHas && bHas) {
          return (b['progress'] as double).compareTo(a['progress'] as double);
        }
        return (a['name'] as String).compareTo(b['name'] as String);
      });

      setState(() {
        _budgetItems = items;
        _isLoading = false;
      });
    } catch (e) {
      if (kDebugMode) {
        print('Error loading budget data: $e');
      }
      setState(() => _isLoading = false);
    }
  }

  Color _getProgressColor(double progress) {
    if (progress >= 1.0) return Colors.red;
    if (progress >= 0.8) return Colors.orange;
    return Colors.green;
  }

  void _showBudgetDialog(Map<String, dynamic> item) {
    final TextEditingController amountController = TextEditingController();
    final existingBudget = item['budget'] as double?;
    if (existingBudget != null) {
      amountController.text = existingBudget.toStringAsFixed(0);
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Set Budget for ${item['name']}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Set a monthly budget for ${item['name']}. You will get warnings when spending approaches the limit.',
              style: TextStyle(color: Colors.grey[600], fontSize: 13),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'Monthly Budget Amount',
                prefixText: _settings.currencySymbol,
                border: const OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          if (existingBudget != null)
            TextButton(
              onPressed: () async {
                await _budgetService.removeBudget(item['id']);
                if (context.mounted) Navigator.pop(context);
                _loadData();
              },
              child: const Text('Remove Budget', style: TextStyle(color: Colors.red)),
            ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final text = amountController.text.trim();
              final amount = double.tryParse(text);
              if (amount != null && amount > 0) {
                await _budgetService.setBudget(item['id'], amount);
                if (context.mounted) Navigator.pop(context);
                _loadData();
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter a valid amount')),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Budgets'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _budgetItems.isEmpty
              ? const Center(child: Text('No categories found'))
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _budgetItems.length,
                    itemBuilder: (context, index) {
                      final item = _budgetItems[index];
                      return _buildBudgetCard(item);
                    },
                  ),
                ),
    );
  }

  Widget _buildBudgetCard(Map<String, dynamic> item) {
    final name = item['name'] as String;
    final icon = item['icon'] as String;
    final color = item['color'] as Color;
    final budget = item['budget'] as double?;
    final spent = item['spent'] as double;
    final progress = item['progress'] as double;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _showBudgetDialog(item),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(icon, style: const TextStyle(fontSize: 22)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          budget != null
                              ? '${_settings.currencySymbol}${spent.toStringAsFixed(0)} of ${_settings.currencySymbol}${budget.toStringAsFixed(0)}'
                              : 'No budget set - tap to set one',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (budget != null) ...[
                    Text(
                      '${(progress * 100).toStringAsFixed(0)}%',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: _getProgressColor(progress),
                      ),
                    ),
                  ] else
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: Colors.grey[400],
                    ),
                ],
              ),
              if (budget != null) ...[
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: progress.clamp(0.0, 1.0),
                    minHeight: 10,
                    backgroundColor: Colors.grey[200],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _getProgressColor(progress),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Spent: ${_settings.currencySymbol}${spent.toStringAsFixed(2)}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                    if (budget > spent)
                      Text(
                        'Remaining: ${_settings.currencySymbol}${(budget - spent).toStringAsFixed(2)}',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      )
                    else
                      Text(
                        'Over budget: ${_settings.currencySymbol}${(spent - budget).toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.red,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
