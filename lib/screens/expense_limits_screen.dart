import 'package:flutter/material.dart';
import '../services/expense_limit_service.dart';
import '../services/settings_service.dart';

class ExpenseLimitsScreen extends StatefulWidget {
  const ExpenseLimitsScreen({super.key});

  @override
  State<ExpenseLimitsScreen> createState() => _ExpenseLimitsScreenState();
}

class _ExpenseLimitsScreenState extends State<ExpenseLimitsScreen> {
  final ExpenseLimitService _limitService = ExpenseLimitService();
  final SettingsService _settings = SettingsService();

  double? _dailyLimit;
  double? _weeklyLimit;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLimits();
  }

  Future<void> _loadLimits() async {
    setState(() => _isLoading = true);
    try {
      final daily = await _limitService.getDailyLimit();
      final weekly = await _limitService.getWeeklyLimit();
      setState(() {
        _dailyLimit = daily;
        _weeklyLimit = weekly;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _showSetLimitDialog(String type, double? currentValue) {
    final controller = TextEditingController(
      text: currentValue != null ? currentValue.toStringAsFixed(0) : '',
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Set ${type[0].toUpperCase()}${type.substring(1)} Limit'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Set a $type expense limit. You will get warnings when spending approaches this limit.',
              style: TextStyle(color: Colors.grey[600], fontSize: 13),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              autofocus: true,
              decoration: InputDecoration(
                labelText: '${type[0].toUpperCase()}${type.substring(1)} Limit',
                prefixText: _settings.currencySymbol,
                border: const OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          if (currentValue != null)
            TextButton(
              onPressed: () async {
                if (type == 'daily') {
                  await _limitService.setDailyLimit(null);
                } else {
                  await _limitService.setWeeklyLimit(null);
                }
                if (context.mounted) Navigator.pop(context);
                _loadLimits();
              },
              child: const Text('Remove', style: TextStyle(color: Colors.red)),
            ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final amount = double.tryParse(controller.text.trim());
              if (amount == null || amount <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter a valid amount')),
                );
                return;
              }
              if (type == 'daily') {
                await _limitService.setDailyLimit(amount);
              } else {
                await _limitService.setWeeklyLimit(amount);
              }
              if (context.mounted) Navigator.pop(context);
              _loadLimits();
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
        title: const Text('Expense Limits'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildInfoCard(),
                const SizedBox(height: 20),
                _buildLimitCard(
                  title: 'Daily Limit',
                  icon: Icons.today,
                  color: Colors.blue,
                  value: _dailyLimit,
                  subtitle: 'Maximum spending per day',
                  type: 'daily',
                ),
                const SizedBox(height: 12),
                _buildLimitCard(
                  title: 'Weekly Limit',
                  icon: Icons.view_week,
                  color: Colors.purple,
                  value: _weeklyLimit,
                  subtitle: 'Maximum spending per week',
                  type: 'weekly',
                ),
                const SizedBox(height: 24),
                Text(
                  'Tips',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 12),
                _buildTipCard(
                  Icons.lightbulb_outline,
                  'Start with a daily limit based on your average spending, then adjust as needed.',
                ),
                const SizedBox(height: 8),
                _buildTipCard(
                  Icons.trending_down,
                  'Weekly limits help control impulse spending over the weekend.',
                ),
                const SizedBox(height: 8),
                _buildTipCard(
                  Icons.notifications_active_outlined,
                  'You will receive warnings when your spending reaches 80% of the limit.',
                ),
              ],
            ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      width: double.infinity,
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
          const Icon(Icons.speed_outlined, color: Colors.white, size: 40),
          const SizedBox(height: 12),
          const Text(
            'Expense Limits',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Set spending limits to stay on track with your financial goals.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withOpacity(0.85),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLimitCard({
    required String title,
    required IconData icon,
    required Color color,
    required double? value,
    required String subtitle,
    required String type,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _showSetLimitDialog(type, value),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (value != null) ...[
                    Text(
                      '${_settings.currencySymbol}${value.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                    Text(
                      'per $type',
                      style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                    ),
                  ] else ...[
                    Text(
                      'Not set',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[500],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Tap to set',
                      style: TextStyle(fontSize: 11, color: Colors.grey[400]),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTipCard(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.amber[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber[200]!),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.amber[700], size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 13, color: Colors.grey[700]),
            ),
          ),
        ],
      ),
    );
  }
}
