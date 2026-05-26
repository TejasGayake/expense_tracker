import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import '../services/database_service.dart';
import '../services/attachment_service.dart';
import 'add_transaction_screen.dart';

class TransactionDetailScreen extends StatefulWidget {
  final Map<String, dynamic> transaction;

  const TransactionDetailScreen({
    super.key,
    required this.transaction,
  });

  @override
  State<TransactionDetailScreen> createState() => _TransactionDetailScreenState();
}

class _TransactionDetailScreenState extends State<TransactionDetailScreen> {
  final DatabaseService _db = DatabaseService();
  final AttachmentService _attachmentService = AttachmentService();
  
  List<Map<String, dynamic>> _attachments = [];
  List<Map<String, dynamic>> _people = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final attachments = await _db.getAttachmentsForTransaction(widget.transaction['id']);
    final people = await _db.getPeopleForTransaction(widget.transaction['id']);
    
    // Get person names
    List<Map<String, dynamic>> peopleWithNames = [];
    for (var person in people) {
      final personData = await _db.getPersonById(person['personId']);
      peopleWithNames.add({
        ...person,
        'personName': personData?['name'] ?? 'Unknown',
      });
    }
    
    setState(() {
      _attachments = attachments;
      _people = peopleWithNames;
    });
  }

  Future<void> _confirmDelete() async {
    // Show confirmation dialog
    final bool? confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Transaction'),
        content: const Text(
          'Are you sure you want to delete this transaction? This action cannot be undone.'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    
    if (confirm == true) {
      _deleteTransaction();
    }
  }

  Future<void> _deleteTransaction() async {
    try {
      // Delete attachments first (files)
      for (var attachment in _attachments) {
        await _attachmentService.deleteImageFile(attachment['filePath']);
      }
      
      // Delete from database (cascading will remove attachments and people entries)
      await _db.deleteTransaction(widget.transaction['id']);
      
      if (mounted) {
        Navigator.pop(context, true); // Return true to indicate deletion
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Transaction deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting transaction: $e');
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting transaction: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _navigateToEdit() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddTransactionScreen(
          transactionToEdit: widget.transaction,
        ),
      ),
    );
    
    if (result == true && mounted) {
      Navigator.pop(context, true); // Return to refresh home
    }
  }

  @override
  Widget build(BuildContext context) {
    final date = DateTime.fromMillisecondsSinceEpoch(widget.transaction['date'] as int);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transaction Details'),
        actions: [
          // Edit button
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _navigateToEdit,
          ),
          // Delete button with confirmation
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _confirmDelete,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Amount Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text(
                    '₹${(widget.transaction['amount'] as num).toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    DateFormat('MMM dd, yyyy - hh:mm a').format(date),
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Details Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDetailRow(
                    icon: Icons.description,
                    label: 'Description',
                    value: (widget.transaction['description'] as String?) ?? 'No description',
                  ),
                  const Divider(),
                  _buildDetailRow(
                    icon: Icons.category,
                    label: 'Category',
                    value: (widget.transaction['category'] as String?) ?? 'Other',
                  ),
                  const Divider(),
                  _buildDetailRow(
                    icon: Icons.payment,
                    label: 'Payment Mode',
                    value: (widget.transaction['paymentMode'] as String?) ?? 'Cash',
                  ),
                  if (widget.transaction['notes'] != null) ...[
                    const Divider(),
                    _buildDetailRow(
                      icon: Icons.note,
                      label: 'Notes',
                      value: widget.transaction['notes'] as String,
                    ),
                  ],
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // People Section
          if (_people.isNotEmpty) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'People Involved',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ..._people.map((person) => ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                        child: Text(
                          (person['personName'] as String)[0].toUpperCase(),
                          style: TextStyle(
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                      ),
                      title: Text(person['personName'] as String),
                      subtitle: Text(person['direction'] == 'owes' ? 'Owes you' : 'You owe them'),
                      trailing: Text(
                        '₹${(person['amount'] as num).toStringAsFixed(2)}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: person['direction'] == 'owes' ? Colors.orange : Colors.red,
                        ),
                      ),
                    )),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
          
          // Attachments Section
          if (_attachments.isNotEmpty) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Attachments',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                      ),
                      itemCount: _attachments.length,
                      itemBuilder: (context, index) {
                        final attachment = _attachments[index];
                        return GestureDetector(
                          onTap: () {
                            _showImageDialog(attachment['filePath'] as String);
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              image: DecorationImage(
                                image: FileImage(File(attachment['filePath'] as String)),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showImageDialog(String imagePath) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          padding: const EdgeInsets.all(8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.file(File(imagePath)),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}