import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/database_service.dart';
import '../services/settings_service.dart';

class MonthlySummaryCard extends StatefulWidget {
  const MonthlySummaryCard({super.key});

  @override
  State<MonthlySummaryCard> createState() => _MonthlySummaryCardState();
}

class _MonthlySummaryCardState extends State<MonthlySummaryCard> {
  final DatabaseService _db = DatabaseService();
  final PageController _pageController = PageController(initialPage: 100);
  List<Map<String, dynamic>> _allTransactions = [];
  bool _isLoading = true;
  int _currentOffset = 0;

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadTransactions() async {
    setState(() => _isLoading = true);
    try {
      final transactions = await _db.getTransactions();
      setState(() {
        _allTransactions = transactions;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  DateTime _monthForOffset(int offset) {
    final now = DateTime.now();
    return DateTime(now.year, now.month + offset);
  }

  Map<String, dynamic> _calculateMonthStats(DateTime month) {
    final monthStart = DateTime(month.year, month.month, 1);
    final monthEnd = DateTime(month.year, month.month + 1, 0, 23, 59, 59);

    double totalSpent = 0;
    double totalIncome = 0;
    Map<String, double> categoryTotals = {};
    double biggestAmount = 0;
    String biggestDesc = '';

    for (var txn in _allTransactions) {
      final date = DateTime.fromMillisecondsSinceEpoch(txn['date'] as int);
      if (date.isBefore(monthStart) || date.isAfter(monthEnd)) continue;

      final amount = (txn['amount'] as num).toDouble();
      final type = txn['type'] as String? ?? 'expense';

      if (type == 'income') {
        totalIncome += amount;
      } else {
        totalSpent += amount;
        final catName = txn['categoryName'] ?? txn['category'] ?? 'Other';
        categoryTotals[catName] = (categoryTotals[catName] ?? 0) + amount;

        if (amount > biggestAmount) {
          biggestAmount = amount;
          biggestDesc = txn['description'] ?? 'No description';
        }
      }
    }

    // Find top category
    String topCategory = 'None';
    if (categoryTotals.isNotEmpty) {
      topCategory = categoryTotals.entries
          .reduce((a, b) => a.value > b.value ? a : b)
          .key;
    }

    return {
      'totalSpent': totalSpent,
      'totalIncome': totalIncome,
      'netBalance': totalIncome - totalSpent,
      'topCategory': topCategory,
      'biggestAmount': biggestAmount,
      'biggestDesc': biggestDesc,
    };
  }

  double? _calculateChangePercent(double current, double previous) {
    if (previous == 0) return current > 0 ? 100.0 : null;
    return ((current - previous) / previous) * 100;
  }

  Widget _buildChangeIndicator(double? percent) {
    if (percent == null) {
      return Text(
        'N/A',
        style: TextStyle(
          fontSize: 12,
          color: Colors.grey[500],
        ),
      );
    }

    final isPositive = percent > 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: (isPositive ? Colors.red : Colors.green).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isPositive ? Icons.arrow_upward : Icons.arrow_downward,
            size: 12,
            color: isPositive ? Colors.red : Colors.green,
          ),
          const SizedBox(width: 2),
          Text(
            '${percent.abs().toStringAsFixed(1)}%',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isPositive ? Colors.red : Colors.green,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        height: 200,
        alignment: Alignment.center,
        child: const SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    return Column(
      children: [
        // Page indicator dots
        SizedBox(
          height: 200,
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentOffset = index - 100;
              });
            },
            itemBuilder: (context, index) {
              final offset = index - 100;
              final month = _monthForOffset(offset);
              final stats = _calculateMonthStats(month);
              final prevStats = _calculateMonthStats(
                DateTime(month.year, month.month - 1),
              );

              return _buildMonthCard(
                context,
                month,
                stats,
                prevStats,
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        // Swipe hint
        Text(
          '${_monthForOffset(_currentOffset).month == DateTime.now().month && _monthForOffset(_currentOffset).year == DateTime.now().year ? "Swipe left/right for other months" : DateFormat('MMMM yyyy').format(_monthForOffset(_currentOffset))}',
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey[500],
          ),
        ),
      ],
    );
  }

  Widget _buildMonthCard(
    BuildContext context,
    DateTime month,
    Map<String, dynamic> stats,
    Map<String, dynamic> prevStats,
  ) {
    final currency = SettingsService().currencySymbol;
    final totalSpent = stats['totalSpent'] as double;
    final totalIncome = stats['totalIncome'] as double;
    final netBalance = stats['netBalance'] as double;
    final topCategory = stats['topCategory'] as String;
    final biggestAmount = stats['biggestAmount'] as double;
    final biggestDesc = stats['biggestDesc'] as String;

    final prevSpent = prevStats['totalSpent'] as double;
    final changePercent = _calculateChangePercent(totalSpent, prevSpent);

    final isCurrentMonth = month.month == DateTime.now().month &&
        month.year == DateTime.now().year;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Month title + change indicator
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    DateFormat('MMMM yyyy').format(month),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (isCurrentMonth)
                    Text(
                      'Current Month',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[500],
                      ),
                    ),
                ],
              ),
              _buildChangeIndicator(changePercent),
            ],
          ),

          const SizedBox(height: 12),

          // Stats row
          Row(
            children: [
              Expanded(
                child: _buildStatColumn(
                  'Spent',
                  '$currency${_formatCompact(totalSpent)}',
                  Colors.red,
                ),
              ),
              Expanded(
                child: _buildStatColumn(
                  'Income',
                  '$currency${_formatCompact(totalIncome)}',
                  Colors.green,
                ),
              ),
              Expanded(
                child: _buildStatColumn(
                  'Net',
                  '$currency${_formatCompact(netBalance)}',
                  netBalance >= 0 ? Colors.green : Colors.red,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 12),

          // Top category & biggest transaction
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Top Category',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[500],
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      topCategory,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Biggest Expense',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[500],
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      biggestAmount > 0
                          ? '$currency${_formatCompact(biggestAmount)}'
                          : 'None',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (biggestDesc.isNotEmpty)
                      Text(
                        biggestDesc,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[500],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatColumn(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey[500],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15,
            color: color,
          ),
        ),
      ],
    );
  }

  String _formatCompact(double amount) {
    if (amount >= 100000) {
      return '${(amount / 100000).toStringAsFixed(1)}L';
    }
    if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(1)}K';
    }
    return amount.toStringAsFixed(0);
  }
}
