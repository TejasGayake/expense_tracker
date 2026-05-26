import 'package:flutter/material.dart';
import '../services/emergency_fund_service.dart';
import '../services/settings_service.dart';

class EmergencyFundScreen extends StatefulWidget {
  const EmergencyFundScreen({super.key});

  @override
  State<EmergencyFundScreen> createState() => _EmergencyFundScreenState();
}

class _EmergencyFundScreenState extends State<EmergencyFundScreen> {
  final EmergencyFundService _fundService = EmergencyFundService();
  final SettingsService _settings = SettingsService();

  double _balance = 0;
  double _target = 0;
  double _progress = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final balance = await _fundService.getBalance();
      final target = await _fundService.getTarget();
      final progress = await _fundService.getProgress();
      setState(() {
        _balance = balance;
        _target = target;
        _progress = progress;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _showSetTargetDialog() {
    final controller = TextEditingController(
      text: _target > 0 ? _target.toStringAsFixed(0) : '',
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Set Emergency Fund Target'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Financial experts recommend saving 3-6 months of expenses as an emergency fund.',
              style: TextStyle(color: Colors.grey[600], fontSize: 13),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'Target Amount',
                prefixText: _settings.currencySymbol,
                border: const OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final amount = double.tryParse(controller.text.trim());
              if (amount != null && amount > 0) {
                await _fundService.setTarget(amount);
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

  void _showContributeDialog() {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add to Emergency Fund'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Current balance: ${_settings.currencySymbol}${_balance.toStringAsFixed(0)}',
              style: TextStyle(color: Colors.grey[600], fontSize: 13),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'Amount to Add',
                prefixText: _settings.currencySymbol,
                border: const OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final amount = double.tryParse(controller.text.trim());
              if (amount != null && amount > 0) {
                await _fundService.addToFund(amount);
                if (context.mounted) Navigator.pop(context);
                _loadData();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Added ${_settings.currencySymbol}${amount.toStringAsFixed(0)} to emergency fund'),
                    backgroundColor: Colors.green,
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter a valid amount')),
                );
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showWithdrawDialog() {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Withdraw from Emergency Fund'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Available: ${_settings.currencySymbol}${_balance.toStringAsFixed(0)}',
              style: TextStyle(color: Colors.grey[600], fontSize: 13),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: Colors.orange[700]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Only withdraw for genuine emergencies.',
                      style: TextStyle(fontSize: 12, color: Colors.orange[700]),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'Amount to Withdraw',
                prefixText: _settings.currencySymbol,
                border: const OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final amount = double.tryParse(controller.text.trim());
              if (amount != null && amount > 0) {
                if (amount > _balance) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Insufficient balance')),
                  );
                  return;
                }
                await _fundService.addToFund(-amount);
                if (context.mounted) Navigator.pop(context);
                _loadData();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Withdrew ${_settings.currencySymbol}${amount.toStringAsFixed(0)}'),
                    backgroundColor: Colors.orange,
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter a valid amount')),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Withdraw'),
          ),
        ],
      ),
    );
  }

  Color _getProgressColor(double progress) {
    if (progress >= 1.0) return Colors.green;
    if (progress >= 0.6) return Colors.blue;
    if (progress >= 0.3) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    final progressColor = _getProgressColor(_progress);
    final remaining = _target - _balance;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Emergency Fund'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Main progress card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          progressColor,
                          progressColor.withOpacity(0.7),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.security, color: Colors.white, size: 40),
                        const SizedBox(height: 12),
                        const Text(
                          'Emergency Fund',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${_settings.currencySymbol}${_balance.toStringAsFixed(2)}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (_target > 0) ...[
                          const SizedBox(height: 8),
                          Text(
                            'of ${_settings.currencySymbol}${_target.toStringAsFixed(0)} target',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 16),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: LinearProgressIndicator(
                              value: _progress.clamp(0.0, 1.0),
                              minHeight: 10,
                              backgroundColor: Colors.white.withOpacity(0.3),
                              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${(_progress * 100).toStringAsFixed(1)}% achieved',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ] else ...[
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: _showSetTargetDialog,
                            style: TextButton.styleFrom(
                              backgroundColor: Colors.white.withOpacity(0.2),
                            ),
                            child: const Text(
                              'Set a target',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Action buttons
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _showContributeDialog,
                          icon: const Icon(Icons.add),
                          label: const Text('Add Funds'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _balance > 0 ? _showWithdrawDialog : null,
                          icon: const Icon(Icons.remove),
                          label: const Text('Withdraw'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Stats cards
                  if (_target > 0 && remaining > 0) ...[
                    _buildStatCard(
                      icon: Icons.flag,
                      label: 'Remaining to goal',
                      value: '${_settings.currencySymbol}${remaining.toStringAsFixed(0)}',
                      color: Colors.blue,
                    ),
                    const SizedBox(height: 10),
                  ],
                  _buildStatCard(
                    icon: Icons.shield,
                    label: 'Status',
                    value: _progress >= 1.0
                        ? 'Fully funded!'
                        : _progress >= 0.5
                            ? 'On track'
                            : 'Needs attention',
                    color: progressColor,
                  ),
                  const SizedBox(height: 20),

                  // Tips
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
                    'Aim for 3-6 months of living expenses as your emergency fund.',
                  ),
                  const SizedBox(height: 8),
                  _buildTipCard(
                    Icons.savings_outlined,
                    'Set up automatic monthly contributions to build your fund consistently.',
                  ),
                  const SizedBox(height: 8),
                  _buildTipCard(
                    Icons.do_not_disturb,
                    'Only use this fund for genuine emergencies like medical bills or job loss.',
                  ),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showSetTargetDialog,
        icon: const Icon(Icons.flag),
        label: Text(_target > 0 ? 'Edit Target' : 'Set Target'),
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTipCard(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.blue[700], size: 20),
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
