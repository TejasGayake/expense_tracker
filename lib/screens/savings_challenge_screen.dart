import 'package:flutter/material.dart';
import '../services/savings_challenge_service.dart';
import '../services/settings_service.dart';

class SavingsChallengeScreen extends StatefulWidget {
  const SavingsChallengeScreen({super.key});

  @override
  State<SavingsChallengeScreen> createState() => _SavingsChallengeScreenState();
}

class _SavingsChallengeScreenState extends State<SavingsChallengeScreen> {
  final SavingsChallengeService _challengeService = SavingsChallengeService();
  final SettingsService _settings = SettingsService();

  List<SavingsChallenge> _challenges = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadChallenges();
  }

  Future<void> _loadChallenges() async {
    setState(() => _isLoading = true);
    try {
      final challenges = await _challengeService.getAll();
      setState(() {
        _challenges = challenges;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _create52WeekChallenge() async {
    final challenge = SavingsChallengeService.create52WeekChallenge();
    await _challengeService.add(challenge);
    _loadChallenges();
  }

  void _showAddChallengeDialog() {
    final nameController = TextEditingController();
    final amountController = TextEditingController();
    String selectedType = '52week';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('New Savings Challenge'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Challenge Name',
                    border: OutlineInputBorder(),
                  ),
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedType,
                  decoration: const InputDecoration(
                    labelText: 'Type',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: '52week', child: Text('52-Week Challenge')),
                    DropdownMenuItem(value: 'noSpend', child: Text('No-Spend Challenge')),
                    DropdownMenuItem(value: 'custom', child: Text('Custom Goal')),
                  ],
                  onChanged: (value) {
                    if (value != null) setDialogState(() => selectedType = value);
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Target Amount',
                    prefixText: _settings.currencySymbol,
                    border: const OutlineInputBorder(),
                    hintText: selectedType == '52week' ? '1378 (auto)' : '',
                  ),
                ),
                if (selectedType == '52week') ...[
                  const SizedBox(height: 8),
                  Text(
                    'Save increasing amounts each week: Week 1 = ${_settings.currencySymbol}1, Week 2 = ${_settings.currencySymbol}2, etc.',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
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
                final amount = double.tryParse(amountController.text.trim()) ?? (selectedType == '52week' ? 1378 : 0);

                if (name.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter a name')),
                  );
                  return;
                }
                if (amount <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter a valid target amount')),
                  );
                  return;
                }

                await _challengeService.add(SavingsChallenge(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  name: name,
                  type: selectedType,
                  targetAmount: amount,
                  startDate: DateTime.now(),
                ));
                if (context.mounted) Navigator.pop(context);
                _loadChallenges();
              },
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }

  void _toggleWeek(SavingsChallenge challenge, int week) async {
    final weeks = List<bool>.from(challenge.weeks);
    weeks[week] = !weeks[week];

    // Calculate saved amount based on checked weeks
    double saved = 0;
    for (int i = 0; i < weeks.length; i++) {
      if (weeks[i]) saved += (i + 1);
    }

    final updated = SavingsChallenge(
      id: challenge.id,
      name: challenge.name,
      type: challenge.type,
      targetAmount: challenge.targetAmount,
      savedAmount: challenge.type == '52week' ? saved : challenge.savedAmount,
      startDate: challenge.startDate,
      currentWeek: challenge.currentWeek,
      weeks: weeks,
    );

    await _challengeService.update(updated);
    _loadChallenges();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Savings Challenge'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _challenges.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _loadChallenges,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _challenges.length,
                    itemBuilder: (context, index) {
                      return _buildChallengeCard(_challenges[index]);
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddChallengeDialog,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.emoji_events_outlined, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No challenges yet',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'Start a savings challenge to build\nbetter money habits.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Colors.grey[500]),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _create52WeekChallenge,
            icon: const Icon(Icons.emoji_events),
            label: const Text('Start 52-Week Challenge'),
          ),
        ],
      ),
    );
  }

  Widget _buildChallengeCard(SavingsChallenge challenge) {
    final completedWeeks = challenge.weeks.where((w) => w).length;
    final progress = challenge.progress;

    return Dismissible(
      key: Key(challenge.id),
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
            title: const Text('Delete Challenge'),
            content: Text('Remove "${challenge.name}"?'),
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
        await _challengeService.delete(challenge.id);
        _loadChallenges();
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: 16),
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.amber.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(
                      child: Text('🏆', style: TextStyle(fontSize: 22)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          challenge.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '${challenge.type == '52week' ? '52-Week' : challenge.type == 'noSpend' ? 'No-Spend' : 'Custom'} \u2022 $completedWeeks/${challenge.weeks.length} weeks',
                          style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${(progress * 100).toInt()}%',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: progress >= 1.0 ? Colors.green : Theme.of(context).primaryColor,
                        ),
                      ),
                      Text(
                        '${_settings.currencySymbol}${challenge.savedAmount.toStringAsFixed(0)}',
                        style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress.clamp(0.0, 1.0),
                  minHeight: 8,
                  backgroundColor: Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation<Color>(
                    progress >= 1.0 ? Colors.green : Colors.amber,
                  ),
                ),
              ),
              if (challenge.type == '52week') ...[
                const SizedBox(height: 16),
                const Text(
                  'Weeks',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 13,
                    mainAxisSpacing: 4,
                    crossAxisSpacing: 4,
                    childAspectRatio: 1,
                  ),
                  itemCount: 52,
                  itemBuilder: (context, index) {
                    final isCompleted = challenge.weeks[index];
                    return GestureDetector(
                      onTap: () => _toggleWeek(challenge, index),
                      child: Container(
                        decoration: BoxDecoration(
                          color: isCompleted ? Colors.green : Colors.grey[200],
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Center(
                          child: Text(
                            '${index + 1}',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                              color: isCompleted ? Colors.white : Colors.grey[600],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Target: ${_settings.currencySymbol}${challenge.targetAmount.toStringAsFixed(0)}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                    Text(
                      'Streak: $completedWeeks weeks',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.amber[700],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
