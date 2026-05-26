import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/database_service.dart';
import '../services/settings_service.dart';

class AddIncomeScreen extends StatefulWidget {
  const AddIncomeScreen({super.key});

  @override
  State<AddIncomeScreen> createState() => _AddIncomeScreenState();
}

class _AddIncomeScreenState extends State<AddIncomeScreen> {
  final _formKey = GlobalKey<FormState>();
  final DatabaseService _db = DatabaseService();

  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  String _selectedCategory = 'Salary';
  String _selectedPaymentMode = 'Cash';

  final List<String> _incomeCategories = [
    'Salary',
    'Freelance',
    'Gifts',
    'Interest',
    'Refunds',
    'Other',
  ];

  final List<String> _paymentModes = [
    'Cash',
    'UPI',
    'Credit Card',
    'Debit Card',
    'Net Banking',
  ];

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currency = SettingsService().currencySymbol;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Income'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Amount Field
            TextFormField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Amount',
                prefixText: '$currency ',
                hintText: '0.00',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter amount';
                }
                final parsed = double.tryParse(value);
                if (parsed == null || parsed <= 0) {
                  return 'Please enter a valid amount';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            // Description Field
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                hintText: 'e.g. May salary, freelance payment',
              ),
            ),

            const SizedBox(height: 16),

            // Date Picker
            InkWell(
              onTap: _selectDate,
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Date',
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      DateFormat('MMM dd, yyyy - hh:mm a').format(_selectedDate),
                    ),
                    const Icon(Icons.calendar_today),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Income Category Dropdown
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              decoration: const InputDecoration(
                labelText: 'Income Category',
                prefixIcon: Icon(Icons.category),
              ),
              isExpanded: true,
              items: _incomeCategories.map((cat) {
                return DropdownMenuItem(
                  value: cat,
                  child: Text(cat),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedCategory = value!;
                });
              },
            ),

            const SizedBox(height: 16),

            // Payment Mode Dropdown
            DropdownButtonFormField<String>(
              value: _selectedPaymentMode,
              decoration: const InputDecoration(
                labelText: 'Payment Mode',
              ),
              items: _paymentModes.map((mode) {
                return DropdownMenuItem(
                  value: mode,
                  child: Text(mode),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedPaymentMode = value!;
                });
              },
            ),

            const SizedBox(height: 32),

            // Save Button
            ElevatedButton.icon(
              onPressed: _saveIncome,
              icon: const Icon(Icons.savings),
              label: const Text('Save Income'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      final TimeOfDay? time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_selectedDate),
      );

      if (time != null) {
        setState(() {
          _selectedDate = DateTime(
            picked.year,
            picked.month,
            picked.day,
            time.hour,
            time.minute,
          );
        });
      }
    }
  }

  Future<void> _saveIncome() async {
    if (_formKey.currentState!.validate()) {
      final amount = double.parse(_amountController.text);

      final transaction = {
        'amount': amount,
        'date': _selectedDate.millisecondsSinceEpoch,
        'description': _descriptionController.text.isEmpty
            ? 'Income: $_selectedCategory'
            : _descriptionController.text,
        'category': _selectedCategory,
        'categoryId': '',
        'paymentMode': _selectedPaymentMode,
        'type': 'income',
      };

      try {
        await _db.insertTransaction(transaction);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Income added successfully'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}
