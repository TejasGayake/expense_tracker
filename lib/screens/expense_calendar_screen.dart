import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/database_service.dart';
import '../services/settings_service.dart';

class ExpenseCalendarScreen extends StatefulWidget {
  const ExpenseCalendarScreen({super.key});

  @override
  State<ExpenseCalendarScreen> createState() => _ExpenseCalendarScreenState();
}

class _ExpenseCalendarScreenState extends State<ExpenseCalendarScreen> {
  final DatabaseService _db = DatabaseService();
  DateTime _currentMonth = DateTime(DateTime.now().year, DateTime.now().month);
  Map<String, double> _dailySpending = {};
  Map<String, List<Map<String, dynamic>>> _dailyTransactions = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    setState(() => _isLoading = true);
    try {
      final transactions = await _db.getTransactions();
      Map<String, double> spending = {};
      Map<String, List<Map<String, dynamic>>> dailyTxns = {};

      for (var txn in transactions) {
        final date = DateTime.fromMillisecondsSinceEpoch(txn['date'] as int);
        final dateKey = DateFormat('yyyy-MM-dd').format(date);
        final amount = (txn['amount'] as num).toDouble();
        final type = txn['type'] as String? ?? 'expense';

        // Only count expenses for spending levels
        if (type == 'expense') {
          spending[dateKey] = (spending[dateKey] ?? 0) + amount;
        }
        dailyTxns.putIfAbsent(dateKey, () => []).add(txn);
      }

      setState(() {
        _dailySpending = spending;
        _dailyTransactions = dailyTxns;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Color _getSpendingColor(double amount) {
    if (amount == 0) return Colors.transparent;
    if (amount < 500) return Colors.green.shade200;
    if (amount < 2000) return Colors.yellow.shade300;
    if (amount < 5000) return Colors.orange.shade300;
    return Colors.red.shade400;
  }

  void _previousMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1);
    });
  }

  List<Widget> _buildCalendarDays() {
    final firstDay = DateTime(_currentMonth.year, _currentMonth.month, 1);
    final lastDay = DateTime(_currentMonth.year, _currentMonth.month + 1, 0);
    final startWeekday = firstDay.weekday % 7; // Sunday = 0
    final today = DateTime.now();

    List<Widget> dayWidgets = [];

    // Empty cells for days before the 1st
    for (int i = 0; i < startWeekday; i++) {
      dayWidgets.add(const SizedBox());
    }

    // Day cells
    for (int day = 1; day <= lastDay.day; day++) {
      final date = DateTime(_currentMonth.year, _currentMonth.month, day);
      final dateKey = DateFormat('yyyy-MM-dd').format(date);
      final spending = _dailySpending[dateKey] ?? 0;
      final isToday = date.year == today.year &&
          date.month == today.month &&
          date.day == today.day;

      dayWidgets.add(
        GestureDetector(
          onTap: () {
            final txns = _dailyTransactions[dateKey] ?? [];
            if (txns.isNotEmpty) {
              _showDayTransactions(date, txns);
            }
          },
          child: Container(
            margin: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: _getSpendingColor(spending),
              borderRadius: BorderRadius.circular(8),
              border: isToday
                  ? Border.all(color: Theme.of(context).primaryColor, width: 2)
                  : null,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '$day',
                  style: TextStyle(
                    fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                    fontSize: 14,
                    color: spending > 2000 ? Colors.white : Colors.black87,
                  ),
                ),
                if (spending > 0)
                  Text(
                    _formatAmount(spending),
                    style: TextStyle(
                      fontSize: 9,
                      color: spending > 2000 ? Colors.white70 : Colors.black54,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
        ),
      );
    }

    return dayWidgets;
  }

  String _formatAmount(double amount) {
    if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(1)}k';
    }
    return amount.toStringAsFixed(0);
  }

  void _showDayTransactions(DateTime date, List<Map<String, dynamic>> transactions) {
    final currency = SettingsService().currencySymbol;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.5,
          minChildSize: 0.3,
          maxChildSize: 0.8,
          expand: false,
          builder: (context, scrollController) {
            final totalDay = transactions
                .where((t) => (t['type'] ?? 'expense') == 'expense')
                .fold<double>(0, (sum, t) => sum + (t['amount'] as num).toDouble());

            return Column(
              children: [
                // Handle bar
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Text(
                        DateFormat('EEEE, MMMM d, yyyy').format(date),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Total spent: $currency${totalDay.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: transactions.length,
                    itemBuilder: (context, index) {
                      final txn = transactions[index];
                      final amount = (txn['amount'] as num).toDouble();
                      final type = txn['type'] as String? ?? 'expense';
                      final desc = txn['description'] ?? 'No description';
                      final catName = txn['categoryName'] ?? txn['category'] ?? 'Other';
                      final catIcon = txn['categoryIcon'] ?? '';

                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: (type == 'income' ? Colors.green : Colors.red)
                              .withOpacity(0.1),
                          child: Text(catIcon, style: const TextStyle(fontSize: 20)),
                        ),
                        title: Text(desc),
                        subtitle: Text(catName),
                        trailing: Text(
                          '${type == 'income' ? '+' : '-'}$currency${amount.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: type == 'income' ? Colors.green : Colors.red,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Expense Calendar'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Month navigator
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chevron_left),
                        onPressed: _previousMonth,
                      ),
                      Text(
                        DateFormat('MMMM yyyy').format(_currentMonth),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.chevron_right),
                        onPressed: _nextMonth,
                      ),
                    ],
                  ),
                ),

                // Day of week headers
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    children: ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat']
                        .map((day) => Expanded(
                              child: Center(
                                child: Text(
                                  day,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey[600],
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ))
                        .toList(),
                  ),
                ),
                const SizedBox(height: 8),

                // Calendar grid
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: GridView.count(
                      crossAxisCount: 7,
                      childAspectRatio: 1.0,
                      children: _buildCalendarDays(),
                    ),
                  ),
                ),

                // Legend
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _legendItem(Colors.transparent, 'None'),
                      const SizedBox(width: 12),
                      _legendItem(Colors.green.shade200, '<500'),
                      const SizedBox(width: 12),
                      _legendItem(Colors.yellow.shade300, '<2K'),
                      const SizedBox(width: 12),
                      _legendItem(Colors.orange.shade300, '<5K'),
                      const SizedBox(width: 12),
                      _legendItem(Colors.red.shade400, '5K+'),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _legendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: color == Colors.transparent ? Colors.grey[200] : color,
            borderRadius: BorderRadius.circular(4),
            border: color == Colors.transparent
                ? Border.all(color: Colors.grey[400]!)
                : null,
          ),
        ),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
      ],
    );
  }
}
