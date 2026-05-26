import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/database_service.dart';
import '../services/settings_service.dart';

class SpendingHeatmap extends StatefulWidget {
  final int weeksToShow;
  final VoidCallback? onTap;

  const SpendingHeatmap({
    super.key,
    this.weeksToShow = 13,
    this.onTap,
  });

  @override
  State<SpendingHeatmap> createState() => _SpendingHeatmapState();
}

class _SpendingHeatmapState extends State<SpendingHeatmap> {
  final DatabaseService _db = DatabaseService();
  Map<String, double> _dailySpending = {};
  bool _isLoading = true;
  double _maxSpending = 0;

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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        height: 160,
        alignment: Alignment.center,
        child: const SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    final today = DateTime.now();
    final endSunday = today.subtract(Duration(days: today.weekday % 7));
    final startDate = endSunday.subtract(Duration(days: (widget.weeksToShow - 1) * 7));

    List<List<MapEntry<String, double>>> grid = [];
    DateTime current = startDate;

    for (int week = 0; week < widget.weeksToShow; week++) {
      List<MapEntry<String, double>> weekData = [];
      for (int day = 0; day < 7; day++) {
        final dateKey = DateFormat('yyyy-MM-dd').format(current);
        final spending = _dailySpending[dateKey] ?? 0;
        weekData.add(MapEntry(dateKey, spending));
        current = current.add(const Duration(days: 1));
      }
      grid.add(weekData);
    }

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
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
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Spending Activity',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Text(
                  'Last 3 months',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Heatmap grid
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Day labels
                Column(
                  children: ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat']
                      .map((day) => Container(
                            height: 16,
                            margin: const EdgeInsets.only(bottom: 2),
                            alignment: Alignment.centerRight,
                            child: Text(
                              day,
                              style: TextStyle(
                                fontSize: 9,
                                color: Colors.grey[500],
                              ),
                            ),
                          ))
                      .toList(),
                ),
                const SizedBox(width: 6),
                // Grid
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
                                width: 16,
                                height: 16,
                                margin: const EdgeInsets.only(
                                  right: 2,
                                  bottom: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: isFuture
                                      ? Colors.grey.shade50
                                      : _getHeatColor(entry.value),
                                  borderRadius: BorderRadius.circular(3),
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

            const SizedBox(height: 8),

            // Legend
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Less',
                  style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                ),
                const SizedBox(width: 4),
                _legendSquare(Colors.grey.shade100),
                _legendSquare(const Color(0xFF9BE9A8)),
                _legendSquare(const Color(0xFF40C463)),
                _legendSquare(const Color(0xFF30A14E)),
                _legendSquare(const Color(0xFF216E39)),
                const SizedBox(width: 4),
                Text(
                  'More',
                  style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _legendSquare(Color color) {
    return Container(
      width: 12,
      height: 12,
      margin: const EdgeInsets.symmetric(horizontal: 1),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}
