import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/database_service.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> with SingleTickerProviderStateMixin {
  final DatabaseService _db = DatabaseService();
  
  // Time period filter
  String _selectedPeriod = 'Month'; // 'Week', 'Month', 'Year'
  late TabController _tabController;
  
  // Data
  List<Map<String, dynamic>> _transactions = [];
  Map<String, double> _categoryTotals = {};
  double _totalSpent = 0;
  List<double> _weeklyData = [0, 0, 0, 0, 0, 0, 0];
  List<String> _weekDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final transactions = await _db.getTransactions();
    
    setState(() {
      _transactions = transactions;
      _processData();
    });
  }

  void _processData() {
    _categoryTotals.clear();
    _totalSpent = 0;
    
    // Reset weekly data
    for (int i = 0; i < 7; i++) {
      _weeklyData[i] = 0;
    }
    
    final now = DateTime.now();
    
    for (var txn in _transactions) {
      final amount = (txn['amount'] as num).toDouble();
      final category = txn['category'] ?? 'Other';
      final date = DateTime.fromMillisecondsSinceEpoch(txn['date']);
      
      // Filter by selected period
      bool includeTransaction = false;
      
      switch (_selectedPeriod) {
        case 'Week':
          includeTransaction = date.isAfter(now.subtract(const Duration(days: 7)));
          // Add to weekly data
          if (includeTransaction) {
            final dayDiff = now.difference(date).inDays;
            if (dayDiff < 7) {
              _weeklyData[6 - dayDiff] += amount;
            }
          }
          break;
        case 'Month':
          includeTransaction = date.month == now.month && date.year == now.year;
          break;
        case 'Year':
          includeTransaction = date.year == now.year;
          break;
      }
      
      if (includeTransaction) {
        _totalSpent += amount;
        _categoryTotals[category] = (_categoryTotals[category] ?? 0) + amount;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Statistics'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Overview', icon: Icon(Icons.pie_chart)),
            Tab(text: 'Trends', icon: Icon(Icons.show_chart)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(),
          _buildTrendsTab(),
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Period Selector
        _buildPeriodSelector(),
        
        const SizedBox(height: 16),
        
        // Total Spent Card
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const Text(
                  'Total Spent',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '₹${_totalSpent.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'This $_selectedPeriod',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Pie Chart
        if (_categoryTotals.isNotEmpty) ...[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Spending by Category',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 200,
                    child: PieChart(
                      PieChartData(
                        sections: _buildPieSections(),
                        centerSpaceRadius: 40,
                        sectionsSpace: 2,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Category List
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Category Breakdown',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ..._buildCategoryList(),
                ],
              ),
            ),
          ),
        ] else ...[
          Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  Icon(
                    Icons.pie_chart,
                    size: 80,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No data for this period',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildTrendsTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildPeriodSelector(),
        
        const SizedBox(height: 16),
        
        // Weekly Bar Chart
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Weekly Spending',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 200,
                  child: BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: _weeklyData.reduce((a, b) => a > b ? a : b) * 1.1,
                      barGroups: _buildBarGroups(),
                      titlesData: FlTitlesData(
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              if (value >= 0 && value < 7) {
                                return Text(_weekDays[value.toInt()]);
                              }
                              return const Text('');
                            },
                          ),
                        ),
                        leftTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                      ),
                      gridData: const FlGridData(show: false),
                      borderData: FlBorderData(show: false),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Insights Card
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Insights',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                _buildInsightItem(
                  icon: Icons.trending_up,
                  label: 'Highest spending day',
                  value: _getHighestSpendingDay(),
                  color: Colors.orange,
                ),
                const Divider(),
                _buildInsightItem(
                  icon: Icons.category,
                  label: 'Top category',
                  value: _getTopCategory(),
                  color: Colors.green,
                ),
                const Divider(),
                _buildInsightItem(
                  icon: Icons.calendar_today,
                  label: 'Average per day',
                  value: '₹${(_totalSpent / 7).toStringAsFixed(2)}',
                  color: Colors.blue,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPeriodSelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          _buildPeriodButton('Week'),
          _buildPeriodButton('Month'),
          _buildPeriodButton('Year'),
        ],
      ),
    );
  }

  Widget _buildPeriodButton(String period) {
    final isSelected = _selectedPeriod == period;
    
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedPeriod = period;
            _processData();
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? Theme.of(context).primaryColor : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            period,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.grey[700],
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  List<PieChartSectionData> _buildPieSections() {
    final colors = [
      Colors.blue,
      Colors.orange,
      Colors.green,
      Colors.red,
      Colors.purple,
      Colors.teal,
      Colors.pink,
      Colors.amber,
    ];
    
    int colorIndex = 0;
    List<PieChartSectionData> sections = [];
    
    _categoryTotals.forEach((category, amount) {
      final percentage = (amount / _totalSpent * 100).toStringAsFixed(1);
      
      sections.add(
        PieChartSectionData(
          value: amount,
          title: '$percentage%',
          color: colors[colorIndex % colors.length],
          radius: 80,
          titleStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      );
      colorIndex++;
    });
    
    return sections;
  }

  List<BarChartGroupData> _buildBarGroups() {
    return List.generate(7, (index) {
      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: _weeklyData[index],
            color: Theme.of(context).primaryColor,
            width: 16,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(4),
              topRight: Radius.circular(4),
            ),
          ),
        ],
      );
    });
  }

  List<Widget> _buildCategoryList() {
    List<Widget> items = [];
    int index = 0;
    final colors = [
      Colors.blue,
      Colors.orange,
      Colors.green,
      Colors.red,
      Colors.purple,
      Colors.teal,
    ];
    
    _categoryTotals.forEach((category, amount) {
      final percentage = (amount / _totalSpent * 100).toStringAsFixed(1);
      
      items.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: colors[index % colors.length],
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: Text(
                  category,
                  style: const TextStyle(fontSize: 14),
                ),
              ),
              Expanded(
                flex: 1,
                child: Text(
                  '₹${amount.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.right,
                ),
              ),
              Expanded(
                flex: 1,
                child: Text(
                  '$percentage%',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
        ),
      );
      index++;
    });
    
    return items;
  }

  Widget _buildInsightItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _getHighestSpendingDay() {
    if (_weeklyData.every((value) => value == 0)) return 'No data';
    
    int maxIndex = 0;
    double maxValue = 0;
    
    for (int i = 0; i < _weeklyData.length; i++) {
      if (_weeklyData[i] > maxValue) {
        maxValue = _weeklyData[i];
        maxIndex = i;
      }
    }
    
    return '${_weekDays[maxIndex]}: ₹${maxValue.toStringAsFixed(2)}';
  }

  String _getTopCategory() {
    if (_categoryTotals.isEmpty) return 'No data';
    
    String topCategory = '';
    double topAmount = 0;
    
    _categoryTotals.forEach((category, amount) {
      if (amount > topAmount) {
        topAmount = amount;
        topCategory = category;
      }
    });
    
    return '$topCategory (₹${topAmount.toStringAsFixed(2)})';
  }
}