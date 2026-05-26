import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/template_service.dart';
import '../services/settings_service.dart';
import '../services/database_service.dart';
import '../models/category_model.dart';
import 'add_transaction_screen.dart';

class TemplatesScreen extends StatefulWidget {
  const TemplatesScreen({super.key});

  @override
  State<TemplatesScreen> createState() => _TemplatesScreenState();
}

class _TemplatesScreenState extends State<TemplatesScreen> {
  final TemplateService _templateService = TemplateService();
  final SettingsService _settings = SettingsService();
  final DatabaseService _db = DatabaseService();

  List<TransactionTemplate> _templates = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTemplates();
  }

  Future<void> _loadTemplates() async {
    setState(() => _isLoading = true);
    try {
      final templates = await _templateService.getAll();
      setState(() {
        _templates = templates;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _showAddTemplateDialog() {
    final nameController = TextEditingController();
    final amountController = TextEditingController();
    final descriptionController = TextEditingController();
    String selectedCategory = 'Other';
    String selectedPaymentMode = 'Cash';

    final categories = ['Food', 'Transport', 'Shopping', 'Bills', 'Healthcare', 'Education', 'Entertainment', 'Other'];
    final paymentModes = ['Cash', 'UPI', 'Credit Card', 'Debit Card', 'Net Banking'];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Save as Template'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Template Name',
                    hintText: 'e.g., Monthly Rent, Coffee',
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
                  value: selectedCategory,
                  decoration: const InputDecoration(
                    labelText: 'Category',
                    border: OutlineInputBorder(),
                  ),
                  items: categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                  onChanged: (value) {
                    if (value != null) setDialogState(() => selectedCategory = value);
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedPaymentMode,
                  decoration: const InputDecoration(
                    labelText: 'Payment Mode',
                    border: OutlineInputBorder(),
                  ),
                  items: paymentModes.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                  onChanged: (value) {
                    if (value != null) setDialogState(() => selectedPaymentMode = value);
                  },
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
                    const SnackBar(content: Text('Please enter a template name')),
                  );
                  return;
                }
                if (amount == null || amount <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter a valid amount')),
                  );
                  return;
                }
                await _templateService.add(TransactionTemplate(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  name: name,
                  amount: amount,
                  category: selectedCategory,
                  paymentMode: selectedPaymentMode,
                ));
                if (context.mounted) Navigator.pop(context);
                _loadTemplates();
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _useTemplate(TransactionTemplate template) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddTransactionScreen(
          transactionToEdit: {
            'amount': template.amount,
            'description': template.name,
            'category': template.category,
            'paymentMode': template.paymentMode,
            'date': DateTime.now().millisecondsSinceEpoch,
          },
        ),
      ),
    ).then((_) => _loadTemplates());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transaction Templates'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _templates.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.description_outlined, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        'No templates yet',
                        style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Save frequently used transactions\nas templates for quick entry.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 13, color: Colors.grey[500]),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadTemplates,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _templates.length,
                    itemBuilder: (context, index) {
                      final template = _templates[index];
                      return _buildTemplateCard(template);
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddTemplateDialog,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildTemplateCard(TransactionTemplate template) {
    return Dismissible(
      key: Key(template.id),
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
            title: const Text('Delete Template'),
            content: Text('Remove "${template.name}" from your templates?'),
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
        await _templateService.delete(template.id);
        _loadTemplates();
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: InkWell(
          onTap: () => _useTemplate(template),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.receipt_long,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        template.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              template.category,
                              style: TextStyle(fontSize: 11, color: Colors.grey[700]),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            template.paymentMode,
                            style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${_settings.currencySymbol}${template.amount.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Tap to use',
                      style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
