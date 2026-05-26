import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/goal_service.dart';
import '../services/settings_service.dart';

class GoalsScreen extends StatefulWidget {
  const GoalsScreen({super.key});

  @override
  State<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends State<GoalsScreen> {
  final GoalService _goalService = GoalService();
  final SettingsService _settings = SettingsService();

  List<SavingsGoal> _goals = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadGoals();
  }

  Future<void> _loadGoals() async {
    setState(() => _isLoading = true);
    try {
      final goals = await _goalService.getAll();
      setState(() {
        _goals = goals;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _showAddGoalDialog() {
    final nameController = TextEditingController();
    final amountController = TextEditingController();
    String selectedIcon = '🎯';

    final icons = ['🎯', '🏠', '🚗', '📱', '✈️', '💻', '🎓', '💍', '🏖️', '💊', '📚', '🎮'];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add New Goal'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Goal Name',
                    border: OutlineInputBorder(),
                  ),
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Target Amount',
                    prefixText: _settings.currencySymbol,
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                const Text('Icon', style: TextStyle(fontWeight: FontWeight.w500)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: icons.map((icon) {
                    final isSelected = icon == selectedIcon;
                    return GestureDetector(
                      onTap: () => setDialogState(() => selectedIcon = icon),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Theme.of(context).primaryColor.withOpacity(0.2)
                              : Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                          border: isSelected
                              ? Border.all(color: Theme.of(context).primaryColor, width: 2)
                              : null,
                        ),
                        child: Center(child: Text(icon, style: const TextStyle(fontSize: 20))),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final name = nameController.text.trim();
                final amount = double.tryParse(amountController.text.trim());
                if (name.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter a name')),
                  );
                  return;
                }
                if (amount == null || amount <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter a valid amount')),
                  );
                  return;
                }
                await _goalService.add(SavingsGoal(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  name: name,
                  targetAmount: amount,
                  icon: selectedIcon,
                ));
                if (context.mounted) Navigator.pop(context);
                _loadGoals();
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _showContributeDialog(SavingsGoal goal) {
    final amountController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add to ${goal.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Current: ${_settings.currencySymbol}${goal.currentAmount.toStringAsFixed(0)} of ${_settings.currencySymbol}${goal.targetAmount.toStringAsFixed(0)}',
              style: TextStyle(color: Colors.grey[600], fontSize: 13),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'Contribution Amount',
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
              final amount = double.tryParse(amountController.text.trim());
              if (amount != null && amount > 0) {
                await _goalService.addToGoal(goal.id, amount);
                if (context.mounted) Navigator.pop(context);
                _loadGoals();
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

  Color _getProgressColor(double progress) {
    if (progress >= 1.0) return Colors.green;
    if (progress >= 0.7) return Colors.blue;
    if (progress >= 0.4) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Financial Goals'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _goals.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.savings_outlined, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        'No goals yet',
                        style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tap + to set your first financial goal',
                        style: TextStyle(fontSize: 13, color: Colors.grey[500]),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadGoals,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _goals.length,
                    itemBuilder: (context, index) {
                      final goal = _goals[index];
                      return _buildGoalCard(goal);
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddGoalDialog,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildGoalCard(SavingsGoal goal) {
    final progress = goal.progress;
    final progressColor = _getProgressColor(progress);
    final remaining = goal.targetAmount - goal.currentAmount;

    return Dismissible(
      key: Key(goal.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (direction) async {
        return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete Goal'),
            content: Text('Remove "${goal.name}" from your goals?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('Delete'),
              ),
            ],
          ),
        );
      },
      onDismissed: (direction) async {
        await _goalService.delete(goal.id);
        _loadGoals();
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: InkWell(
          onTap: () => _showContributeDialog(goal),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                SizedBox(
                  width: 56,
                  height: 56,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CircularProgressIndicator(
                        value: progress,
                        strokeWidth: 5,
                        backgroundColor: Colors.grey[200],
                        valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                      ),
                      Text(
                        '${(progress * 100).toInt()}%',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: progressColor,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(goal.icon, style: const TextStyle(fontSize: 18)),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              goal.name,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (goal.isCompleted)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                'Done!',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.green,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${_settings.currencySymbol}${goal.currentAmount.toStringAsFixed(0)} of ${_settings.currencySymbol}${goal.targetAmount.toStringAsFixed(0)}',
                        style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: progress.clamp(0.0, 1.0),
                          minHeight: 6,
                          backgroundColor: Colors.grey[200],
                          valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                        ),
                      ),
                      if (!goal.isCompleted) ...[
                        const SizedBox(height: 4),
                        Text(
                          '${_settings.currencySymbol}${remaining.toStringAsFixed(0)} remaining',
                          style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
