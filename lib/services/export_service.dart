import 'dart:io';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'database_service.dart';

class ExportService {
  final DatabaseService _db = DatabaseService();

  Future<String> exportTransactionsToCsv() async {
    final transactions = await _db.getTransactions();

    List<List<dynamic>> csvData = [
      ['Date', 'Description', 'Category', 'Amount', 'Payment Mode', 'Notes'],
    ];

    for (var txn in transactions) {
      final date = DateTime.fromMillisecondsSinceEpoch(txn['date'] as int);
      csvData.add([
        '${date.day}/${date.month}/${date.year}',
        txn['description'] ?? '',
        txn['category'] ?? '',
        txn['amount'] ?? 0,
        txn['paymentMode'] ?? '',
        txn['notes'] ?? '',
      ]);
    }

    String csv = const ListToCsvConverter().convert(csvData);

    final directory = await getApplicationDocumentsDirectory();
    final path = '${directory.path}/expense_tracker_export_${DateTime.now().millisecondsSinceEpoch}.csv';
    final file = File(path);
    await file.writeAsString(csv);

    return path;
  }
}
