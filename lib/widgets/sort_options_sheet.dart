import 'package:flutter/material.dart';

enum SortField {
  date,
  amount,
  category,
}

enum SortOrder {
  ascending,
  descending,
}

class SortOption {
  final SortField field;
  final SortOrder order;
  final String label;

  const SortOption({
    required this.field,
    required this.order,
    required this.label,
  });
}

class SortOptionsSheet extends StatelessWidget {
  final SortField currentField;
  final SortOrder currentOrder;

  static const List<SortOption> options = [
    SortOption(
      field: SortField.date,
      order: SortOrder.descending,
      label: 'Date (Newest first)',
    ),
    SortOption(
      field: SortField.date,
      order: SortOrder.ascending,
      label: 'Date (Oldest first)',
    ),
    SortOption(
      field: SortField.amount,
      order: SortOrder.descending,
      label: 'Amount (High to Low)',
    ),
    SortOption(
      field: SortField.amount,
      order: SortOrder.ascending,
      label: 'Amount (Low to High)',
    ),
    SortOption(
      field: SortField.category,
      order: SortOrder.ascending,
      label: 'Category (A to Z)',
    ),
    SortOption(
      field: SortField.category,
      order: SortOrder.descending,
      label: 'Category (Z to A)',
    ),
  ];

  const SortOptionsSheet({
    super.key,
    required this.currentField,
    required this.currentOrder,
  });

  static Future<SortOption?> show(
    BuildContext context, {
    required SortField currentField,
    required SortOrder currentOrder,
  }) {
    return showModalBottomSheet<SortOption>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SortOptionsSheet(
        currentField: currentField,
        currentOrder: currentOrder,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),

          // Title
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Icon(Icons.sort, size: 20),
                SizedBox(width: 8),
                Text(
                  'Sort By',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Sort options
          ...options.map((option) {
            final isSelected = option.field == currentField &&
                option.order == currentOrder;

            return InkWell(
              onTap: () => Navigator.pop(context, option),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                color: isSelected
                    ? Theme.of(context).primaryColor.withOpacity(0.1)
                    : null,
                child: Row(
                  children: [
                    Icon(
                      _getIconForField(option.field),
                      size: 20,
                      color: isSelected
                          ? Theme.of(context).primaryColor
                          : Colors.grey[600],
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        option.label,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.normal,
                          color: isSelected
                              ? Theme.of(context).primaryColor
                              : null,
                        ),
                      ),
                    ),
                    if (isSelected)
                      Icon(
                        Icons.check,
                        size: 20,
                        color: Theme.of(context).primaryColor,
                      ),
                  ],
                ),
              ),
            );
          }),

          // Bottom padding for safe area
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }

  IconData _getIconForField(SortField field) {
    switch (field) {
      case SortField.date:
        return Icons.calendar_today;
      case SortField.amount:
        return Icons.currency_rupee;
      case SortField.category:
        return Icons.category;
    }
  }
}

/// Utility to sort a list of transactions based on SortOption
List<Map<String, dynamic>> sortTransactions(
  List<Map<String, dynamic>> transactions,
  SortField field,
  SortOrder order,
) {
  final sorted = List<Map<String, dynamic>>.from(transactions);

  sorted.sort((a, b) {
    int comparison;

    switch (field) {
      case SortField.date:
        final dateA = (a['date'] as int?) ?? 0;
        final dateB = (b['date'] as int?) ?? 0;
        comparison = dateA.compareTo(dateB);
        break;

      case SortField.amount:
        final amountA = (a['amount'] as num?)?.toDouble() ?? 0;
        final amountB = (b['amount'] as num?)?.toDouble() ?? 0;
        comparison = amountA.compareTo(amountB);
        break;

      case SortField.category:
        final catA = (a['categoryName'] ?? a['category'] ?? '').toString().toLowerCase();
        final catB = (b['categoryName'] ?? b['category'] ?? '').toString().toLowerCase();
        comparison = catA.compareTo(catB);
        break;
    }

    return order == SortOrder.descending ? -comparison : comparison;
  });

  return sorted;
}
