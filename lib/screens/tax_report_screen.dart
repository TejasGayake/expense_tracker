import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/tax_service.dart';
import '../services/settings_service.dart';

class TaxReportScreen extends StatefulWidget {
  const TaxReportScreen({super.key});

  @override
  State<TaxReportScreen> createState() => _TaxReportScreenState();
}

class _TaxReportScreenState extends State<TaxReportScreen> {
  final TaxService _taxService = TaxService();
  final SettingsService _settings = SettingsService();

  List<Map<String, dynamic>> _transactions = [];
  Map<String, double> _categoryTotals = {};
  double _totalDeductible = 0;
  int _selectedYear = 0;
  List<int> _availableYears = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initYears();
    _loadData();
  }

  void _initYears() {
    final now = DateTime.now();
    final currentFY = now.month >= 4 ? now.year : now.year - 1;
    _selectedYear = currentFY;
    _availableYears = List.generate(5, (i) => currentFY - i);
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final txns = await _taxService.getDeductibleTransactions(year: _selectedYear);
      final total = await _taxService.getTotalDeductible(year: _selectedYear);

      // Group by category
      Map<String, double> catTotals = {};
      for (var txn in txns) {
        final category = txn['category'] as String? ?? 'Other';
        final amount = (txn['amount'] as num).toDouble();
        catTotals[category] = (catTotals[category] ?? 0) + amount;
      }

      // Sort transactions by date descending
      txns.sort((a, b) => (b['date'] as int).compareTo(a['date'] as int));

      setState(() {
        _transactions = txns;
        _categoryTotals = catTotals;
        _totalDeductible = total;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  String _getFYLabel(int year) {
    return 'Apr $year - Mar ${year + 1}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tax Report'),
        actions: [
          PopupMenuButton<int>(
            icon: const Icon(Icons.calendar_today),
            onSelected: (year) {
              setState(() => _selectedYear = year);
              _loadData();
            },
            itemBuilder: (context) {
              return _availableYears.map((year) {
                return PopupMenuItem(
                  value: year,
                  child: Row(
                    children: [
                      if (year == _selectedYear)
                        Icon(Icons.check, size: 18, color: Theme.of(context).primaryColor)
                      else
                        const SizedBox(width: 18),
                      const SizedBox(width: 8),
                      Text(_getFYLabel(year)),
                    ],
                  ),
                );
              }).toList();
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildTotalCard(),
                  const SizedBox(height: 16),
                  _buildFYSelector(),
                  const SizedBox(height: 20),
                  if (_categoryTotals.isNotEmpty) ...[
                    Text(
                      'By Category',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                    const SizedBox(height: 12),
                    ..._categoryTotals.entries.map((entry) => _buildCategoryTile(entry.key, entry.value)),
                    const SizedBox(height: 24),
                  ],
                  Text(
                    'Transactions (${_transactions.length})',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (_transactions.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.receipt_long_outlined, size: 48, color: Colors.grey[400]),
                          const SizedBox(height: 12),
                          Text(
                            'No deductible transactions found',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Transactions in categories: ${TaxService.deductibleCategories.join(", ")}\nare automatically considered tax-deductible.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                          ),
                        ],
                      ),
                    )
                  else
                    ..._transactions.map((txn) => _buildTransactionTile(txn)),
                ],
              ),
            ),
    );
  }

  Widget _buildTotalCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.indigo,
            Colors.indigo.withOpacity(0.7),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Text(
            'Total Tax Deductible',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${_settings.currencySymbol}${_totalDeductible.toStringAsFixed(2)}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _getFYLabel(_selectedYear),
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${_transactions.length} transactions',
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFYSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: _selectedYear > _availableYears.last
                ? () {
                    setState(() => _selectedYear--);
                    _loadData();
                  }
                : null,
            icon: const Icon(Icons.chevron_left),
          ),
          Column(
            children: [
              const Text(
                'Financial Year',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              Text(
                _getFYLabel(_selectedYear),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          IconButton(
            onPressed: _selectedYear < _availableYears.first
                ? () {
                    setState(() => _selectedYear++);
                    _loadData();
                  }
                : null,
            icon: const Icon(Icons.chevron_right),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryTile(String category, double amount) {
    final percentage = _totalDeductible > 0 ? (amount / _totalDeductible * 100) : 0.0;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _getCategoryColor(category).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(
                  _getCategoryIcon(category),
                  style: const TextStyle(fontSize: 18),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    category,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: (percentage / 100).clamp(0.0, 1.0),
                      minHeight: 4,
                      backgroundColor: Colors.grey[200],
                      valueColor: AlwaysStoppedAnimation<Color>(_getCategoryColor(category)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${_settings.currencySymbol}${amount.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${percentage.toStringAsFixed(1)}%',
                  style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionTile(Map<String, dynamic> txn) {
    final date = DateTime.fromMillisecondsSinceEpoch(txn['date'] as int);
    final amount = (txn['amount'] as num).toDouble();
    final category = txn['category'] as String? ?? 'Other';
    final description = txn['description'] as String? ?? '';

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: _getCategoryColor(category).withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(child: Text(categoryIcon, style: const TextStyle(fontSize: 18))),
        ),
        title: Text(
          description.isNotEmpty ? description : category,
          style: const TextStyle(fontWeight: FontWeight.w500),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          '${DateFormat('MMM dd, yyyy').format(date)} \u2022 $categoryName',
          style: TextStyle(fontSize: 12, color: Colors.grey[500]),
        ),
        trailing: Text(
          '${_settings.currencySymbol}${amount.toStringAsFixed(2)}',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'medical':
      case 'healthcare':
        return Colors.red;
      case 'education':
        return Colors.blue;
      case 'insurance':
        return Colors.purple;
      case 'donations':
        return Colors.green;
      case 'business':
        return Colors.orange;
      case 'taxes':
        return Colors.indigo;
      default:
        return Colors.grey;
    }
  }

  String _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'medical':
      case 'healthcare':
        return '🏥';
      case 'education':
        return '📚';
      case 'insurance':
        return '🛡️';
      case 'donations':
        return '🤝';
      case 'business':
        return '💼';
      case 'taxes':
        return '📋';
      default:
        return '📦';
    }
  }
}
