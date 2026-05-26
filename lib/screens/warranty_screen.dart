import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/warranty_service.dart';

class WarrantyScreen extends StatefulWidget {
  const WarrantyScreen({super.key});

  @override
  State<WarrantyScreen> createState() => _WarrantyScreenState();
}

class _WarrantyScreenState extends State<WarrantyScreen> {
  final WarrantyService _service = WarrantyService();
  List<Warranty> _warranties = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final warranties = await _service.getAll();
    setState(() {
      _warranties = warranties;
      _isLoading = false;
    });
  }

  void _showAddDialog() {
    final nameCtrl = TextEditingController();
    final monthsCtrl = TextEditingController(text: '12');
    String? category;
    DateTime purchaseDate = DateTime.now();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Add Warranty'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Product Name',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Purchased: ${DateFormat('MMM d, yyyy').format(purchaseDate)}',
                      ),
                    ),
                    TextButton(
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: ctx,
                          initialDate: purchaseDate,
                          firstDate: DateTime(2000),
                          lastDate: DateTime.now(),
                        );
                        if (picked != null) {
                          setDialogState(() => purchaseDate = picked);
                        }
                      },
                      child: const Text('Change'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: monthsCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Warranty (months)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: category,
                  decoration: const InputDecoration(
                    labelText: 'Category',
                    border: OutlineInputBorder(),
                  ),
                  items: ['Electronics', 'Appliances', 'Furniture', 'Vehicle', 'Other']
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (v) => setDialogState(() => category = v),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameCtrl.text.isNotEmpty) {
                  final warranty = Warranty(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    productName: nameCtrl.text,
                    purchaseDate: purchaseDate,
                    warrantyMonths: int.tryParse(monthsCtrl.text) ?? 12,
                    category: category,
                  );
                  await _service.add(warranty);
                  if (ctx.mounted) Navigator.pop(ctx);
                  _loadData();
                }
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final expiring = _warranties.where((w) => !w.isExpired && w.daysRemaining <= 30).toList();
    final active = _warranties.where((w) => !w.isExpired && w.daysRemaining > 30).toList();
    final expired = _warranties.where((w) => w.isExpired).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Warranties'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDialog,
        backgroundColor: Theme.of(context).primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _warranties.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.shield_outlined, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text('No warranties tracked', style: TextStyle(fontSize: 16, color: Colors.grey[600])),
                    ],
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    if (expiring.isNotEmpty) ...[
                      _sectionHeader('Expiring Soon', Colors.orange),
                      ...expiring.map(_buildCard),
                      const SizedBox(height: 16),
                    ],
                    if (active.isNotEmpty) ...[
                      _sectionHeader('Active', Colors.green),
                      ...active.map(_buildCard),
                      const SizedBox(height: 16),
                    ],
                    if (expired.isNotEmpty) ...[
                      _sectionHeader('Expired', Colors.red),
                      ...expired.map(_buildCard),
                    ],
                  ],
                ),
    );
  }

  Widget _sectionHeader(String title, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(width: 4, height: 16, color: color),
          const SizedBox(width: 8),
          Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: color)),
        ],
      ),
    );
  }

  Widget _buildCard(Warranty w) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: w.isExpired
              ? Colors.red.shade100
              : w.daysRemaining <= 30
                  ? Colors.orange.shade100
                  : Colors.green.shade100,
          child: Icon(
            Icons.shield,
            color: w.isExpired
                ? Colors.red
                : w.daysRemaining <= 30
                    ? Colors.orange
                    : Colors.green,
          ),
        ),
        title: Text(w.productName, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(
          w.isExpired
              ? 'Expired ${DateFormat('MMM d, yyyy').format(w.expiryDate)}'
              : '${w.daysRemaining} days remaining',
          style: TextStyle(
            color: w.isExpired ? Colors.red : Colors.grey[600],
          ),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, color: Colors.red),
          onPressed: () async {
            await _service.delete(w.id);
            _loadData();
          },
        ),
      ),
    );
  }
}
