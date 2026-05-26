class DuplicateDetector {
  /// Checks if a new transaction is a potential duplicate of recent transactions.
  ///
  /// Returns true if a transaction with the same amount and category exists
  /// within the specified time window.
  static bool isDuplicate(
    Map<String, dynamic> newTxn,
    List<Map<String, dynamic>> recentTransactions, {
    Duration window = const Duration(hours: 2),
  }) {
    final now = DateTime.now();
    final amount = (newTxn['amount'] as num?)?.toDouble() ?? 0;
    final category = newTxn['category'] as String? ?? '';

    for (var txn in recentTransactions) {
      final txnDate = DateTime.fromMillisecondsSinceEpoch(txn['date'] as int);
      if (now.difference(txnDate) > window) continue;

      final txnAmount = (txn['amount'] as num?)?.toDouble() ?? 0;
      final txnCategory = txn['category'] as String? ?? '';

      if (txnAmount == amount && txnCategory == category) return true;
    }

    return false;
  }

  /// Returns a list of recent transactions that match the new transaction.
  static List<Map<String, dynamic>> findDuplicates(
    Map<String, dynamic> newTxn,
    List<Map<String, dynamic>> recentTransactions, {
    Duration window = const Duration(hours: 2),
  }) {
    final now = DateTime.now();
    final amount = (newTxn['amount'] as num?)?.toDouble() ?? 0;
    final category = newTxn['category'] as String? ?? '';

    return recentTransactions.where((txn) {
      final txnDate = DateTime.fromMillisecondsSinceEpoch(txn['date'] as int);
      if (now.difference(txnDate) > window) return false;

      final txnAmount = (txn['amount'] as num?)?.toDouble() ?? 0;
      final txnCategory = txn['category'] as String? ?? '';

      return txnAmount == amount && txnCategory == category;
    }).toList();
  }
}
