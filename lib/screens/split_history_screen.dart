import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/database_service.dart';
import '../services/settings_service.dart';

class SplitHistoryScreen extends StatefulWidget {
  const SplitHistoryScreen({super.key});

  @override
  State<SplitHistoryScreen> createState() => _SplitHistoryScreenState();
}

class _SplitHistoryScreenState extends State<SplitHistoryScreen> {
  final DatabaseService _db = DatabaseService();
  List<Map<String, dynamic>> _transactionsWithPeople = [];
  List<Map<String, dynamic>> _pendingAmounts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final txnsWithPeople = await _db.getTransactionsWithPeople();
      final pendingAmounts = await _db.getPendingAmounts();

      // Filter only transactions that have splits
      final splitTxns = txnsWithPeople
          .where((t) => t['peopleInfo'] != null && (t['peopleInfo'] as String).isNotEmpty)
          .toList();

      setState(() {
        _transactionsWithPeople = splitTxns;
        _pendingAmounts = pendingAmounts;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  double get _totalOwedToMe {
    return _pendingAmounts.fold(0.0, (sum, p) => sum + ((p['owedToMe'] as num?)?.toDouble() ?? 0));
  }

  double get _totalIOwe {
    return _pendingAmounts.fold(0.0, (sum, p) => sum + ((p['iOwe'] as num?)?.toDouble() ?? 0));
  }

  @override
  Widget build(BuildContext context) {
    final currency = SettingsService().currencySymbol;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Split History'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Outstanding balance summary
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Theme.of(context).primaryColor,
                        Theme.of(context).primaryColor.withOpacity(0.7),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'Outstanding Balances',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              children: [
                                const Text(
                                  'Owed to Me',
                                  style: TextStyle(color: Colors.white70, fontSize: 12),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '$currency${_totalOwedToMe.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            width: 1,
                            height: 40,
                            color: Colors.white30,
                          ),
                          Expanded(
                            child: Column(
                              children: [
                                const Text(
                                  'I Owe',
                                  style: TextStyle(color: Colors.white70, fontSize: 12),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '$currency${_totalIOwe.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Net: $currency${(_totalOwedToMe - _totalIOwe).toStringAsFixed(2)}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Pending people list
                if (_pendingAmounts.isNotEmpty)
                  SizedBox(
                    height: 90,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _pendingAmounts.length,
                      itemBuilder: (context, index) {
                        final person = _pendingAmounts[index];
                        final owedToMe = (person['owedToMe'] as num?)?.toDouble() ?? 0;
                        final iOwe = (person['iOwe'] as num?)?.toDouble() ?? 0;

                        return Container(
                          width: 140,
                          margin: const EdgeInsets.only(right: 12),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Theme.of(context).cardColor,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 14,
                                    backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                                    child: Text(
                                      (person['name'] as String)[0].toUpperCase(),
                                      style: TextStyle(
                                        color: Theme.of(context).primaryColor,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      person['name'],
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              if (owedToMe > 0)
                                Text(
                                  'Owes: $currency${owedToMe.toStringAsFixed(0)}',
                                  style: TextStyle(
                                    color: Colors.green[600],
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              if (iOwe > 0)
                                Text(
                                  'You owe: $currency${iOwe.toStringAsFixed(0)}',
                                  style: TextStyle(
                                    color: Colors.red[600],
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),

                const SizedBox(height: 8),

                // Timeline header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      const Icon(Icons.timeline, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        'Split Timeline',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${_transactionsWithPeople.length} splits',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ),

                // Transaction list
                Expanded(
                  child: _transactionsWithPeople.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.people_outline, size: 64, color: Colors.grey[400]),
                              const SizedBox(height: 16),
                              Text(
                                'No split transactions yet',
                                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _transactionsWithPeople.length,
                          itemBuilder: (context, index) {
                            final txn = _transactionsWithPeople[index];
                            return _buildSplitTimelineItem(txn);
                          },
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildSplitTimelineItem(Map<String, dynamic> txn) {
    final currency = SettingsService().currencySymbol;
    final date = DateTime.fromMillisecondsSinceEpoch(txn['date'] as int);
    final amount = (txn['amount'] as num).toDouble();
    final description = txn['description'] ?? 'No description';
    final catIcon = txn['categoryIcon'] ?? '';
    final peopleInfo = txn['peopleInfo'] as String? ?? '';

    // Parse peopleInfo: "name:amount:direction:status,name:amount:direction:status"
    final peopleParts = peopleInfo.split(',').where((s) => s.isNotEmpty).toList();
    int settledCount = peopleParts.where((p) {
      final parts = p.split(':');
      return parts.length >= 4 && parts[3] == 'settled';
    }).length;
    bool allSettled = settledCount == peopleParts.length && peopleParts.isNotEmpty;
    bool anyPartial = peopleParts.any((p) {
      final parts = p.split(':');
      return parts.length >= 4 && parts[3] == 'partial';
    });

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Timeline line and dot
            Column(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: allSettled
                        ? Colors.green
                        : anyPartial
                            ? Colors.orange
                            : Colors.red,
                  ),
                ),
                Expanded(
                  child: Container(
                    width: 2,
                    color: Colors.grey[300],
                  ),
                ),
              ],
            ),
            const SizedBox(width: 12),
            // Transaction content
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(catIcon, style: const TextStyle(fontSize: 20)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            description,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                        ),
                        Text(
                          '$currency${amount.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      DateFormat('MMM d, yyyy h:mm a').format(date),
                      style: TextStyle(color: Colors.grey[500], fontSize: 12),
                    ),
                    if (peopleParts.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: peopleParts.map((p) {
                          final parts = p.split(':');
                          if (parts.length < 4) return const SizedBox();
                          final name = parts[0];
                          final pAmount = parts[1];
                          final direction = parts[2];
                          final status = parts[3];

                          Color chipColor;
                          IconData chipIcon;
                          if (status == 'settled') {
                            chipColor = Colors.green;
                            chipIcon = Icons.check_circle;
                          } else if (status == 'partial') {
                            chipColor = Colors.orange;
                            chipIcon = Icons.adjust;
                          } else {
                            chipColor = direction == 'owes' ? Colors.blue : Colors.red;
                            chipIcon = Icons.pending;
                          }

                          return Chip(
                            avatar: Icon(chipIcon, size: 14, color: Colors.white),
                            label: Text(
                              '$name ($currency$pAmount)',
                              style: const TextStyle(color: Colors.white, fontSize: 11),
                            ),
                            backgroundColor: chipColor,
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            visualDensity: VisualDensity.compact,
                            padding: EdgeInsets.zero,
                          );
                        }).toList(),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
