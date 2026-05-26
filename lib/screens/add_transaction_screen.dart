import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import '../services/database_service.dart';
import '../services/attachment_service.dart';
import '../widgets/attachment_picker.dart';
import '../models/category_model.dart';
import 'split_transaction_screen.dart';

class AddTransactionScreen extends StatefulWidget {
  final Map<String, dynamic>? transactionToEdit;
  const AddTransactionScreen({super.key, this.transactionToEdit});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final DatabaseService _db = DatabaseService();
  final AttachmentService _attachmentService = AttachmentService();
  
  // Form fields
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _notesController = TextEditingController();
  
  DateTime _selectedDate = DateTime.now();
  
  // Dynamic categories from database
  List<CategoryModel> _categories = [];
  String? _selectedCategoryId;
  bool _isLoadingCategories = false;
  
  String _selectedPaymentMode = 'Cash';
  
  // Split flag
  bool _willSplit = false;
  
  // Attachments
  List<File> _selectedImages = [];
  
  final List<String> _paymentModes = [
    'Cash',
    'UPI',
    'Credit Card',
    'Debit Card',
    'Net Banking',
  ];

  @override
  void initState() {
    super.initState();
    _loadCategories();
    // If we're editing an existing transaction, populate fields
    if (widget.transactionToEdit != null) {
      _loadTransactionForEdit();
    }
  }

  // Load categories from database
  Future<void> _loadCategories() async {
    if (kDebugMode) {
      print('🔍 _loadCategories() called');
    }
    setState(() => _isLoadingCategories = true);

    try {
      final categoriesData = await _db.getCategories();
      if (kDebugMode) {
        print('📊 Raw categories data: $categoriesData');
      }

      final categories = categoriesData.map((c) => CategoryModel.fromMap(c)).toList();

      if (kDebugMode) {
        print('✅ Converted ${categories.length} categories');
      }

      setState(() {
        _categories = categories;
        if (_categories.isNotEmpty && _selectedCategoryId == null) {
          _selectedCategoryId = _categories.first.id;
          if (kDebugMode) {
            print('✅ Set default category ID: $_selectedCategoryId');
          }
        }
        _isLoadingCategories = false;
      });
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error loading categories: $e');
      }
      setState(() => _isLoadingCategories = false);
    }
  }

  // Load transaction data for editing
  void _loadTransactionForEdit() {
    final txn = widget.transactionToEdit!;
    _amountController.text = (txn['amount'] as num).toString();
    _descriptionController.text = (txn['description'] as String?) ?? '';
    _notesController.text = (txn['notes'] as String?) ?? '';
    _selectedDate = DateTime.fromMillisecondsSinceEpoch(txn['date'] as int);
    _selectedPaymentMode = (txn['paymentMode'] as String?) ?? 'Cash';
    
    // Set category after categories are loaded
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_categories.isNotEmpty) {
        // Prefer categoryId, fall back to name match
        final catId = txn['categoryId'] as String?;
        final categoryName = (txn['category'] as String?) ?? 'Other';
        final category = catId != null
            ? _categories.firstWhere(
                (c) => c.id == catId,
                orElse: () => _categories.firstWhere(
                  (c) => c.name == categoryName,
                  orElse: () => _categories.first,
                ),
              )
            : _categories.firstWhere(
                (c) => c.name == categoryName,
                orElse: () => _categories.first,
              );
        setState(() {
          _selectedCategoryId = category.id;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.transactionToEdit != null ? 'Edit Transaction' : 'Add Transaction'),
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
              decoration: const InputDecoration(
                labelText: 'Amount',
                prefixText: '₹ ',
                hintText: '0.00',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter amount';
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
                hintText: 'What was this for?',
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
            //--------------------------------
            // debugging 
            
            // 🔥 START OF DEBUG CODE - COPY FROM HERE
            
            // Container(
              // padding: const EdgeInsets.all(16),
              // color: Colors.blue.shade50,
              // child: Column(
                // crossAxisAlignment: CrossAxisAlignment.start,
                // children: [
                  // Text('🔍 DEBUG INFO', style: TextStyle(fontWeight: FontWeight.bold)),
                  // Text('_isLoadingCategories: $_isLoadingCategories'),
                  // Text('_categories.length: ${_categories.length}'),
                  // if (_categories.isNotEmpty) ...[
                    // Text('First category: ${_categories.first.name}'),
                    // Text('Selected ID: $_selectedCategoryId'),
                  // ],
                // ],
              // ),
            // ),
            // const SizedBox(height: 16),
            
            // ==========================================
            // 🔥 END OF DEBUG CODE

            // -------------------------------
            
            // 🔥 CATEGORY SELECTOR - Added here between Date and Payment Mode
            
            // ================================================
            // 🔥 FIXED CATEGORY SELECTOR
            // 🔥 COMPLETELY FIXED CATEGORY SELECTOR - NO OVERFLOW
            _isLoadingCategories
                ? const Center(child: CircularProgressIndicator())
                : _categories.isEmpty
                    ? Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.orange.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.warning, color: Colors.orange),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'No categories found. Please restart the app.',
                                style: TextStyle(color: Colors.orange.shade800),
                              ),
                            ),
                          ],
                        ),
                      )
                    : DropdownButtonFormField<String>(
                        value: _selectedCategoryId,
                        decoration: const InputDecoration(
                          labelText: 'Category',
                          prefixIcon: Icon(Icons.category),
                        ),
                        isExpanded: true, // ✅ This makes the dropdown take full width
                        items: _categories.map((category) {
                          return DropdownMenuItem(
                            value: category.id,
                            child: Row(
                              mainAxisSize: MainAxisSize.min, // ✅ Prevents taking too much space
                              children: [
                                // Category Icon with colored background
                                Container(
                                  width: 28,
                                  height: 28,
                                  margin: const EdgeInsets.only(right: 8),
                                  decoration: BoxDecoration(
                                    color: category.color.withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: Text(
                                      category.icon,
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                  ),
                                ),
                                // Category Name with constrained width
                                ConstrainedBox(
                                  constraints: BoxConstraints(
                                    maxWidth: MediaQuery.of(context).size.width * 0.4,
                                  ),
                                  child: Text(
                                    category.name,
                                    style: const TextStyle(fontSize: 14),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                // Usage count badge
                                if (category.usageCount > 0)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.grey[200],
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      '${category.usageCount}',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.grey[700],
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedCategoryId = value;
                          });
                        },
                        validator: (value) {
                          if (value == null) {
                            return 'Please select a category';
                          }
                          return null;
                        },
                      ),
            // ===============================================
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
            
            const SizedBox(height: 16),
            
            // Split Switch
            SwitchListTile(
              title: const Text(
                'Split with others',
                style: TextStyle(fontSize: 16),
              ),
              subtitle: const Text('Add people who owe or paid'),
              value: _willSplit,
              onChanged: (value) {
                setState(() {
                  _willSplit = value;
                });
              },
              activeColor: Theme.of(context).primaryColor,
            ),
            
            const SizedBox(height: 16),
            
            // Attachments Section
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Attachments',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Add screenshots, receipts, or bills',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 16),
                  AttachmentPicker(
                    onImagesPicked: (images) {
                      _selectedImages = images;
                    },
                    transactionId: 'temp', // Will be replaced after save
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Notes Field
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Notes (Optional)',
                hintText: 'Add any additional details...',
              ),
              maxLines: 3,
            ),
            
            const SizedBox(height: 32),
            
            // Save Button
            ElevatedButton(
              onPressed: _saveTransaction,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
              child: Text(widget.transactionToEdit != null ? 'Update Transaction' : 'Save Transaction'),
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

  Future<void> _saveTransaction() async {
    if (_formKey.currentState!.validate()) {
      // Check if category is selected
      if (_selectedCategoryId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select a category'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      
      final amount = double.parse(_amountController.text);
      
      // Find the selected category
      final selectedCategory = _categories.firstWhere(
        (c) => c.id == _selectedCategoryId,
      );
      
      final transaction = {
        'amount': amount,
        'date': _selectedDate.millisecondsSinceEpoch,
        'description': _descriptionController.text,
        'category': selectedCategory.name,
        'categoryId': selectedCategory.id,
        'paymentMode': _selectedPaymentMode,
        'notes': _notesController.text.isEmpty
            ? null
            : _notesController.text,
      };
      
      // Save or update transaction
      String savedTransactionId;
      if (widget.transactionToEdit != null) {
        // Update existing
        transaction['id'] = widget.transactionToEdit!['id'];
        await _db.updateTransaction(transaction);
        savedTransactionId = widget.transactionToEdit!['id'];
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Transaction updated successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        // Insert new and get the generated ID directly
        savedTransactionId = await _db.insertTransaction(transaction);
        
        // Increment category usage count for new transaction
        await _db.incrementCategoryUsage(selectedCategory.id!);
      }

      // Save attachments if any
      if (_selectedImages.isNotEmpty) {
        for (var image in _selectedImages) {
          final savedPath = await _attachmentService.saveImageToAppDirectory(
            image, 
            savedTransactionId,
          );

          if (savedPath != null) {
            await _db.insertAttachment({
              'transactionId': savedTransactionId,
              'filePath': savedPath,
              'type': 'image',
              'caption': 'Screenshot',
            });
          }
        }
      }

      if (_willSplit) {
        // Navigate to split screen
        if (mounted) {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SplitTransactionScreen(
                totalAmount: amount,
                transactionId: savedTransactionId,
                transactionDescription: _descriptionController.text,
              ),
            ),
          );

          if (result == true) {
            Navigator.pop(context, true);
          }
        }
      } else {
        // No split, just return
        if (mounted) {
          Navigator.pop(context, true);
          if (widget.transactionToEdit == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Transaction saved successfully'),
                backgroundColor: Colors.green,
              ),
            );
          }
        }
      }
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    _notesController.dispose();
    super.dispose();
  }
}