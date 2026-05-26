import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/debt_service.dart';
import '../services/settings_service.dart';

class DebtTrackerScreen extends StatefulWidget {
  const DebtTrackerScreen({super.key});

  @override
  State<DebtTrackerScreen> createState() => _DebtTrackerScreenState();
}

class _DebtTrackerScreenState extends State<DebtTrackerScreen> with SingleTickerProviderStateMixin {
  final DebtService _debtService = DebtService();
  final SettingsService _settings = SettingsService();

  late TabController _tabController;
  List<DebtEntry> _debts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadDebts();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadDebts() async {
    setState(() => _isLoading = true);
    try {
      final debts = await _debtService.getAll();
      setState(() {
        _debts = debts;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  List<DebtEntry> get _givenDebts => _debts.where((d) => d.type == 'given').toList();
  List<DebtEntry> get _receivedDebts => _debts.where((d) => d.type == 'received').toList();

  void _showAddDebtDialog() {
    final personController = TextEditingController();
    final amountController = TextEditingController();
    final interestController = TextEditingController(text: '0');
    final notesController = TextEditingController();
    String selectedType = 'given';
    DateTime? selectedDueDate;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add Debt Entry'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: personController,
                  decoration: const InputDecoration(
                    labelText: 'Person Name',
                    border: OutlineInputBorder(),
                  ),
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Amount',
                    prefixText: _settings.currencySymbol,
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedType,
                  decoration: const InputDecoration(
                    labelText: 'Type',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'given', child: Text('Given (I lent money)')),
                    DropdownMenuItem(value: 'received', child: Text('Received (I borrowed)')),
                  ],
                  onChanged: (value) {
                    if (value != null) setDialogState(() => selectedType = value);
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: interestController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Interest Rate (% per annum)',
                    suffixText: '%',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: selectedDueDate ?? DateTime.now().add(const Duration(days: 30)),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365 * 10)),
                    );
                    if (picked != null) {
                      setDialogState(() => selectedDueDate = picked);
                    }
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Due Date (Optional)',
                      border: OutlineInputBorder(),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          selectedDueDate != null
                              ? DateFormat('MMM dd, yyyy').format(selectedDueDate!)
                              : 'No due date',
                          style: TextStyle(
                            color: selectedDueDate != null ? null : Colors.grey[500],
                          ),
                        ),
                        Icon(Icons.calendar_today, size: 18, color: Colors.grey[600]),
                      ],
                    ),
                  ),
                ),
                if (selectedDueDate != null) ...[
                  const SizedBox(height: 4),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => setDialogState(() => selectedDueDate = null),
                      child: const Text('Clear', style: TextStyle(fontSize: 12)),
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                TextField(
                  controller: notesController,
                  decoration: const InputDecoration(
                    labelText: 'Notes (Optional)',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
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
                final person = personController.text.trim();
                final amount = double.tryParse(amountController.text.trim());
                final interest = double.tryParse(interestController.text.trim()) ?? 0;

                if (person.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter person name')),
                  );
                  return;
                }
                if (amount == null || amount <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter a valid amount')),
                  );
                  return;
                }

                await _debtService.add(DebtEntry(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  personName: person,
                  amount: amount,
                  interestRate: interest,
                  type: selectedType,
                  startDate: DateTime.now(),
                  dueDate: selectedDueDate,
                  notes: notesController.text.trim(),
                ));
                if (context.mounted) Navigator.pop(context);
                _loadDebts();
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _showPaymentDialog(DebtEntry debt) {
    final amountController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Record Payment for ${debt.personName}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Amount: ${_settings.currencySymbol}${debt.amount.toStringAsFixed(0)}',
              style: TextStyle(color: Colors.grey[600], fontSize: 13),
            ),
            Text(
              'Notes: ${debt.notes.isEmpty ? "None" : debt.notes}',
              style: TextStyle(color: Colors.grey[600], fontSize: 13),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'Payment Amount',
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
                await _debtService.delete(debt.id);
                if (context.mounted) Navigator.pop(context);
                _loadDebts();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Debt entry removed')),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter a valid amount')),
                );
              }
            },
            child: const Text('Record'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Debt Tracker'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Given', icon: Icon(Icons.arrow_upward)),
            Tab(text: 'Received', icon: Icon(Icons.arrow_downward)),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildDebtList(_givenDebts, 'given'),
                _buildDebtList(_receivedDebts, 'received'),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDebtDialog,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildDebtList(List<DebtEntry> debts, String type) {
    if (debts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              type == 'given' ? Icons.arrow_upward : Icons.arrow_downward,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              type == 'given' ? 'No debts given' : 'No debts received',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              type == 'given'
                  ? 'Money you have lent to others'
                  : 'Money you have borrowed',
              style: TextStyle(fontSize: 13, color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    final totalAmount = debts.fold<double>(0, (sum, d) => sum + d.amount);
    final totalInterest = debts.fold<double>(0, (sum, d) => sum + (d.amount * d.interestRate / 100));

    return Column(
      children: [
        Container(
          width: double.infinity,
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: type == 'given'
                ? Colors.orange.withOpacity(0.1)
                : Colors.green.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: type == 'given'
                  ? Colors.orange.withOpacity(0.3)
                  : Colors.green.withOpacity(0.3),
            ),
          ),
          child: Column(
            children: [
              Text(
                type == 'given' ? 'Total Given' : 'Total Received',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${_settings.currencySymbol}${totalAmount.toStringAsFixed(0)}',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: type == 'given' ? Colors.orange : Colors.green,
                ),
              ),
              if (totalInterest > 0) ...[
                const SizedBox(height: 4),
                Text(
                  '+ ${_settings.currencySymbol}${totalInterest.toStringAsFixed(0)} interest',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: debts.length,
            itemBuilder: (context, index) {
              return _buildDebtCard(debts[index]);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDebtCard(DebtEntry debt) {
    final isOverdue = debt.dueDate != null && debt.dueDate!.isBefore(DateTime.now());
    final totalWithInterest = debt.amount * (1 + debt.interestRate / 100);

    return Dismissible(
      key: Key(debt.id),
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
            title: const Text('Delete Debt'),
            content: Text('Remove debt entry for "${debt.personName}"?'),
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
        await _debtService.delete(debt.id);
        _loadDebts();
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: InkWell(
          onTap: () => _showPaymentDialog(debt),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: debt.type == 'given'
                          ? Colors.orange.withOpacity(0.2)
                          : Colors.green.withOpacity(0.2),
                      child: Text(
                        debt.personName.isNotEmpty ? debt.personName[0].toUpperCase() : '?',
                        style: TextStyle(
                          color: debt.type == 'given' ? Colors.orange : Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            debt.personName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (debt.notes.isNotEmpty)
                            Text(
                              debt.notes,
                              style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${_settings.currencySymbol}${debt.amount.toStringAsFixed(0)}',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: debt.type == 'given' ? Colors.orange : Colors.green,
                          ),
                        ),
                        if (debt.interestRate > 0)
                          Text(
                            '${debt.interestRate}% p.a.',
                            style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                          ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.calendar_today, size: 14, color: Colors.grey[500]),
                    const SizedBox(width: 6),
                    Text(
                      'Started: ${DateFormat('MMM dd, yyyy').format(debt.startDate)}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                    ),
                    const Spacer(),
                    if (debt.dueDate != null) ...[
                      Icon(
                        isOverdue ? Icons.warning : Icons.event,
                        size: 14,
                        color: isOverdue ? Colors.red : Colors.grey[500],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isOverdue ? 'Overdue!' : 'Due: ${DateFormat('MMM dd, yyyy').format(debt.dueDate!)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: isOverdue ? Colors.red : Colors.grey[500],
                          fontWeight: isOverdue ? FontWeight.w600 : null,
                        ),
                      ),
                    ],
                  ],
                ),
                if (debt.interestRate > 0) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.info_outline, size: 14, color: Colors.blue[700]),
                        const SizedBox(width: 6),
                        Text(
                          'Total with interest: ${_settings.currencySymbol}${totalWithInterest.toStringAsFixed(0)}',
                          style: TextStyle(fontSize: 12, color: Colors.blue[700]),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
