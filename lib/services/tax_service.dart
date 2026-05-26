import 'database_service.dart';

class TaxService {
  static final TaxService _instance = TaxService._internal();
  factory TaxService() => _instance;
  TaxService._internal();

  final DatabaseService _db = DatabaseService();

  static const List<String> deductibleCategories = [
    'Medical', 'Education', 'Insurance', 'Donations', 'Business', 'Taxes',
  ];

  Future<List<Map<String, dynamic>>> getDeductibleTransactions({int? year}) async {
    final transactions = await _db.getTransactions();
    final fy = year ?? _getCurrentFinancialYear();
    final start = DateTime(fy, 4, 1);
    final end = DateTime(fy + 1, 3, 31);

    return transactions.where((txn) {
      final date = DateTime.fromMillisecondsSinceEpoch(txn['date'] as int);
      final category = txn['category'] as String? ?? '';
      final isDeductible = deductibleCategories.any((c) => category.toLowerCase().contains(c.toLowerCase()));
      return isDeductible && date.isAfter(start) && date.isBefore(end);
    }).toList();
  }

  Future<double> getTotalDeductible({int? year}) async {
    final txns = await getDeductibleTransactions(year: year);
    double total = 0;
    for (var txn in txns) { total += (txn['amount'] as num).toDouble(); }
    return total;
  }

  int _getCurrentFinancialYear() {
    final now = DateTime.now();
    return now.month >= 4 ? now.year : now.year - 1;
  }
}
