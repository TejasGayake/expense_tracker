import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/database_service.dart';
import '../services/settings_service.dart';

class SpendingHeatmapScreen extends StatefulWidget {
  const SpendingHeatmapScreen({super.key});

  @override
  State<SpendingHeatmapScreen> createState() => _SpendingHeatmapScreenState();
}

class _SpendingHeatmapScreenState extends State<SpendingHeatmapScreen> {
  final DatabaseService _db = DatabaseService();
  Map<String, double> _dailySpending = {};
  bool _isLoading = true;
  double _maxSpending = 0;
  int _weeksToShow = 13; // ~3 months

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final transactions = await _db.getTransactions();
      Map<String, double> spending = {};

      for (var txn in transactions) {
        final type = txn['type'] as String? ?? 'expense';
        if (type != 'expense') continue;

        final date = DateTime.fromMillisecondsSinceEpoch(txn['date'] as int);
        final dateKey = DateFormat('yyyy-MM-dd').format(date);
        final amount = (txn['amount'] as num).toDouble();
        spending[dateKey] = (spending[dateKey] ?? 0) + amount;
      }

      double maxVal = 0;
      for (var val in spending.values) {
        if (val > maxVal) maxVal = val;
      }

      setState(() {
        _dailySpending = spending;
        _maxSpending = maxVal;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Color _getHeatColor(double amount) {
    if (amount == 0) return Colors.grey.shade100;
    final ratio = _maxSpending > 0 ? (amount / _maxSpending).clamp(0.0, 1.0) : 0.0;

    if (ratio < 0.25) return const Color(0xFF9BE9A8);
    if (ratio < 0.50) return const Color(0xFF40C463);
    if (ratio < 0.75) return const Color(0xFF30A14E);
    return const Color(0xFF216E39);
  }

  @override
  Widget build(BuildContext context) {
    final currency = SettingsService().currencySymbol;
    final today = DateTime.now();
    // Start from the most recent Sunday (or today if Sunday)
    final endDate = today;
    // Go back _weeksToShow weeks from the start of the current week
    final endSunday = endDate.subtract(Duration(days: endDate.weekday % 7));
    final startDate = endSunday.subtract(Duration(days: (_weeksToShow - 1) * 7));

    // Build the grid data: 7 rows (days of week) x N columns (weeks)
    List<List<MapEntry<String, double>>> grid = [];
    DateTime current = startDate;

    for (int week = 0; week < _weeksToShow; week++) {
      List<MapEntry<String, double>> weekData = [];
      for (int day = 0; day < 7; day++) {
        final dateKey = DateFormat('yyyy-MM-dd').format(current);
        final spending = _dailySpending[dateKey] ?? 0;
        weekData.add(MapEntry(dateKey, spending));
        current = current.add(const Duration(days: 1));
      }
      grid.add(weekData);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Spending Heatmap'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title and description
                  Text(
                    'Last 3 Months',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Darker squares indicate higher spending',
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                  const SizedBox(height: 24),

                  // Day of week labels + heatmap
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Day labels
                      Column(
                        children: ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat']
                            .map((day) => Container(
                                  height: 20,
                                  margin: const EdgeInsets.only(bottom: 3),
                                  alignment: Alignment.centerRight,
                                  child: Text(
                                    day,
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.grey[500],
                                    ),
                                  ),
                                ))
                            .toList(),
                      ),
                      const SizedBox(width: 8),
                      // Heatmap grid
                      Expanded(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          reverse: true,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: grid.map((week) {
                              return Column(
                                children: week.map((entry) {
                                  final dateParts = entry.key.split('-');
                                  final date = DateTime(
                                    int.parse(dateParts[0]),
                                    int.parse(dateParts[1]),
                                    int.parse(dateParts[2]),
                                  );
                                  final isFuture = date.isAfter(today);
                                  final isToday = date.year == today.year &&
                                      date.month == today.month &&
                                      date.day == today.day;

                                  return GestureDetector(
                                    onTap: () {
                                      if (entry.value > 0) {
                                        _showDayDetail(entry.key, entry.value);
                                      }
                                    },
                                    child: Container(
                                      width: 20,
                                      height: 20,
                                      margin: const EdgeInsets.only(
                                        right: 3,
                                        bottom: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isFuture
                                            ? Colors.grey.shade50
                                            : _getHeatColor(entry.value),
                                        borderRadius: BorderRadius.circular(4),
                                        border: isToday
                                            ? Border.all(
                                                color: Theme.of(context).primaryColor,
                                                width: 1.5,
                                              )
                                            : null,
                                      ),
                                    ),
                                  );
                                }).toList(),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Month labels
                  _buildMonthLabels(grid, startDate),

                  const SizedBox(height: 24),

                  // Legend
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Less',
                        style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                      ),
                      const SizedBox(width: 6),
                      _legendSquare(Colors.grey.shade100),
                      _legendSquare(const Color(0xFF9BE9A8)),
                      _legendSquare(const Color(0xFF40C463)),
                      _legendSquare(const Color(0xFF30A14E)),
                      _legendSquare(const Color(0xFF216E39)),
                      const SizedBox(width: 6),
                      Text(
                        'More',
                        style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),

                  // Summary stats
                  _buildSummaryStats(currency),
                ],
              ),
            ),
    );
  }

  Widget _legendSquare(Color color) {
    return Container(
      width: 14,
      height: 14,
      margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(3),
      ),
    );
  }

  Widget _buildMonthLabels(
      List<List<MapEntry<String, double>>> grid, DateTime startDate) {
    List<Widget> labels = [];
    String? lastMonth;

    for (int week = 0; week < grid.length; week++) {
      final firstDay = grid[week].first.key;
      final dateParts = firstDay.split('-');
      final date = DateTime(
          int.parse(dateParts[0]), int.parse(dateParts[1]), int.parse(dateParts[2]));
      final month = DateFormat('MMM').format(date);

      if (month != lastMonth) {
        labels.add(
          Padding(
            padding: const EdgeInsets.only(right: 20),
            child: Text(
              month,
              style: TextStyle(fontSize: 11, color: Colors.grey[500]),
            ),
          ),
        );
        lastMonth = month;
      } else {
        labels.add(const SizedBox(width: 23));
      }
    }

    return Padding(
      padding: const EdgeInsets.only(left: 36), // Align with grid
      child: Row(children: labels),
    );
  }

  void _showDayDetail(String dateKey, double amount) {
    final currency = SettingsService().currencySymbol;
    final dateParts = dateKey.split('-');
    final date = DateTime(
      int.parse(dateParts[0]),
      int.parse(dateParts[1]),
      int.parse(dateParts[2]),
    );

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                DateFormat('EEEE, MMMM d, yyyy').format(date),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Total Spending',
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
              ),
              const SizedBox(height: 4),
              Text(
                '$currency${amount.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSummaryStats(String currency) {
    final expenses = _dailySpending.values.where((v) => v > 0).toList();
    if (expenses.isEmpty) {
      return const SizedBox();
    }

    final total = expenses.fold<double>(0, (s, v) => s + v);
    final avg = total / expenses.length;
    final maxVal = expenses.reduce((a, b) => a > b ? a : b);
    final activeDays = expenses.length;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
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
          const Text(
            'Statistics',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _statItem('Total', '$currency${total.toStringAsFixed(0)}'),
              ),
              Expanded(
                child: _statItem('Daily Avg', '$currency${avg.toStringAsFixed(0)}'),
              ),
              Expanded(
                child: _statItem('Peak Day', '$currency${maxVal.toStringAsFixed(0)}'),
              ),
              Expanded(
                child: _statItem('Active Days', '$activeDays'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey[500],
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
