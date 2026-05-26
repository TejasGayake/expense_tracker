import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../services/database_service.dart';
import 'add_person_screen.dart';

class SplitTransactionScreen extends StatefulWidget {
  final double totalAmount;
  final String transactionId;
  final String transactionDescription;

  const SplitTransactionScreen({
    super.key,
    required this.totalAmount,
    required this.transactionId,
    required this.transactionDescription,
  });

  @override
  State<SplitTransactionScreen> createState() => _SplitTransactionScreenState();
}

class _SplitTransactionScreenState extends State<SplitTransactionScreen> {
  final DatabaseService _db = DatabaseService();
  List<Map<String, dynamic>> _people = [];
  List<Map<String, dynamic>> _selectedPeople = [];
  
  // Split types
  String _splitType = 'equal'; // 'equal', 'custom', 'percentage'
  double _remainingAmount = 0;

  @override
  void initState() {
    super.initState();
    _loadPeople();
    _remainingAmount = widget.totalAmount;
  }

  Future<void> _loadPeople() async {
    final people = await _db.getPeople();
    setState(() {
      _people = people;
    });
  }

  void _addPersonToSplit(Map<String, dynamic> person) {
    setState(() {
      _selectedPeople.add({
        'personId': person['id'],
        'name': person['name'],
        'amount': 0.0, // Make sure this is double
        'direction': 'owes', // Default: they owe money
        'status': 'pending',
        'settledAmount': 0.0, // Add settledAmount as double
      });
      _updateSplitAmounts();
    });
  }

  void _removePersonFromSplit(int index) {
    setState(() {
      _selectedPeople.removeAt(index);
      _updateSplitAmounts();
    });
  }

  void _updateSplitAmounts() {
    if (_splitType == 'equal' && _selectedPeople.isNotEmpty) {
      double equalShare = widget.totalAmount / (_selectedPeople.length + 1); // +1 for yourself
      for (var person in _selectedPeople) {
        person['amount'] = equalShare; // This is already double
      }
    }
    
    // Calculate remaining (your share)
    double totalAssigned = 0.0;
    for (var person in _selectedPeople) {
      totalAssigned += (person['amount'] as double);
    }
    _remainingAmount = widget.totalAmount - totalAssigned;
  }

  Future<void> _saveSplit() async {
    try {
      // Create transaction_people entries for each selected person
      for (var person in _selectedPeople) {
        // Ensure amount is double
        double amount = (person['amount'] is int) 
            ? (person['amount'] as int).toDouble() 
            : (person['amount'] as double);
        
        await _db.addTransactionPerson({
          'transactionId': widget.transactionId,
          'personId': person['personId'],
          'amount': amount, // Now guaranteed to be double
          'direction': person['direction'] as String,
          'status': person['status'] as String,
          'settledAmount': 0.0, // Make sure this is double
        });
      }
      
      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Split saved successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error saving split: $e');
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving split: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Split Transaction'),
      ),
      body: Column(
        children: [
          // Header with total
          Container(
            padding: const EdgeInsets.all(16),
            color: Theme.of(context).primaryColor.withOpacity(0.1),
            child: Column(
              children: [
                Text(
                  'Total Amount',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '₹${widget.totalAmount.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.transactionDescription,
                  style: TextStyle(
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),

          // Split type selector
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Text(
                  'Split Type:',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                const SizedBox(width: 16),
                ChoiceChip(
                  label: const Text('Equal'),
                  selected: _splitType == 'equal',
                  onSelected: (selected) {
                    setState(() {
                      _splitType = 'equal';
                      _updateSplitAmounts();
                    });
                  },
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('Custom'),
                  selected: _splitType == 'custom',
                  onSelected: (selected) {
                    setState(() {
                      _splitType = 'custom';
                    });
                  },
                ),
              ],
            ),
          ),

          // Selected people list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _selectedPeople.length,
              itemBuilder: (context, index) {
                final person = _selectedPeople[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                      child: Text(
                        person['name'][0].toUpperCase(),
                        style: TextStyle(
                          color: Theme.of(context).primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(person['name']),
                    subtitle: DropdownButton<String>(
                      value: person['direction'],
                      items: const [
                        DropdownMenuItem(
                          value: 'owes',
                          child: Text('Owes me'),
                        ),
                        DropdownMenuItem(
                          value: 'lent',
                          child: Text('I owe them'),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() {
                          person['direction'] = value!;
                        });
                      },
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_splitType == 'custom')
                          SizedBox(
                            width: 100,
                            child: TextFormField(
                              initialValue: person['amount'].toString(),
                              decoration: const InputDecoration(
                                prefixText: '₹',
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              onChanged: (value) {
                                setState(() {
                                  person['amount'] = double.tryParse(value) ?? 0.0;
                                  _updateSplitAmounts();
                                });
                              },
                            ),
                          )
                        else
                          Text(
                            '₹${(person['amount'] as double).toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        IconButton(
                          icon: const Icon(Icons.close, size: 20),
                          onPressed: () => _removePersonFromSplit(index),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // Your share and add person button
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: Column(
              children: [
                // Your share
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Your share:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      '₹${_remainingAmount.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: _remainingAmount >= 0 
                            ? Colors.green 
                            : Colors.red,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Add person button
                OutlinedButton.icon(
                  onPressed: () => _showPersonSelector(),
                  icon: const Icon(Icons.person_add),
                  label: const Text('Add Person'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 45),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Save button
                ElevatedButton(
                  onPressed: _selectedPeople.isEmpty ? null : _saveSplit,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                  ),
                  child: const Text('Save Split'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showPersonSelector() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          height: 400,
          child: Column(
            children: [
              const Text(
                'Select Person',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  itemCount: _people.length,
                  itemBuilder: (context, index) {
                    final person = _people[index];
                    final isSelected = _selectedPeople.any(
                      (p) => p['personId'] == person['id']
                    );
                    
                    return ListTile(
                      title: Text(person['name']),
                      subtitle: Text(person['phone'] ?? 'No phone'),
                      trailing: isSelected 
                          ? const Icon(Icons.check_circle, color: Colors.green)
                          : null,
                      onTap: () {
                        if (!isSelected) {
                          _addPersonToSplit(person);
                          Navigator.pop(context);
                        }
                      },
                    );
                  },
                ),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.pop(context);
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AddPersonScreen(),
                    ),
                  );
                  if (result == true) {
                    _loadPeople();
                  }
                },
                child: const Text('+ Add New Person'),
              ),
            ],
          ),
        );
      },
    );
  }
}