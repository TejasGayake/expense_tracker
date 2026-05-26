import 'package:flutter/material.dart';

class CategoryModel {
  String? id;
  String name;
  String icon;
  Color color;
  bool isDefault;
  int usageCount;
  DateTime? createdAt;

  CategoryModel({
    this.id,
    required this.name,
    required this.icon,
    required this.color,
    this.isDefault = false,
    this.usageCount = 0,
    this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'icon': icon,
      'color': color.value,
      'isDefault': isDefault ? 1 : 0,
      'usageCount': usageCount,
      'createdAt': createdAt?.millisecondsSinceEpoch,
    };
  }

  factory CategoryModel.fromMap(Map<String, dynamic> map) {
    return CategoryModel(
      id: map['id'],
      name: map['name'],
      icon: map['icon'],
      color: Color(map['color']),
      isDefault: map['isDefault'] == 1,
      usageCount: map['usageCount'] ?? 0,
      createdAt: map['createdAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['createdAt'])
          : null,
    );
  }
}

// Default category icon/color lookup by name
final Map<String, Map<String, dynamic>> defaultCategoryLookup = {
  'Food & Dining': {'icon': '🍕', 'color': const Color(0xFFFF6B6B)},
  'Transport': {'icon': '🚗', 'color': const Color(0xFF45B7D1)},
  'Shopping': {'icon': '🛍️', 'color': const Color(0xFF96CEB4)},
  'Bills & Utilities': {'icon': '💡', 'color': const Color(0xFFFFEEAD)},
  'Entertainment': {'icon': '🎬', 'color': const Color(0xFF9B59B6)},
  'Health': {'icon': '💊', 'color': const Color(0xFFE74C3C)},
  'Education': {'icon': '📚', 'color': const Color(0xFF3498DB)},
  'Groceries': {'icon': '🛒', 'color': const Color(0xFF2ECC71)},
  'Rent': {'icon': '🏠', 'color': const Color(0xFFE67E22)},
  'Travel': {'icon': '✈️', 'color': const Color(0xFF4ECDC4)},
  'Mobile & Internet': {'icon': '📱', 'color': const Color(0xFFF1C40F)},
  'Clothing': {'icon': '👕', 'color': const Color(0xFFD4A5A5)},
  'Personal Care': {'icon': '💊', 'color': const Color(0xFF9B59B6)},
  'Gifts & Donations': {'icon': '🎁', 'color': const Color(0xFFFF6B6B)},
  'Insurance': {'icon': '🛡️', 'color': const Color(0xFF45B7D1)},
  'Investments': {'icon': '📈', 'color': const Color(0xFF2ECC71)},
  'Taxes': {'icon': '📋', 'color': const Color(0xFFE74C3C)},
  'Savings': {'icon': '🏦', 'color': const Color(0xFF3498DB)},
  'Income': {'icon': '💰', 'color': const Color(0xFF2ECC71)},
  'Business': {'icon': '💼', 'color': const Color(0xFFE67E22)},
  'Pets': {'icon': '🐕', 'color': const Color(0xFFD4A5A5)},
  'Kids': {'icon': '👶', 'color': const Color(0xFFFFEEAD)},
  'Subscriptions': {'icon': '📺', 'color': const Color(0xFF9B59B6)},
  'Repairs': {'icon': '🔧', 'color': const Color(0xFF45B7D1)},
  'Fuel': {'icon': '⛽', 'color': const Color(0xFFFF6B6B)},
  'Other': {'icon': '📦', 'color': const Color(0xFF95A5A6)},
};

String getCategoryIcon(String? categoryName) {
  if (categoryName == null) return '📦';
  return defaultCategoryLookup[categoryName]?['icon'] as String? ?? '📦';
}

Color getCategoryColor(String? categoryName) {
  if (categoryName == null) return const Color(0xFF95A5A6);
  return defaultCategoryLookup[categoryName]?['color'] as Color? ?? const Color(0xFF95A5A6);
}

// Available icons for categories
const List<String> categoryIcons = [
  '🍕', '🍔', '🍜', '☕', '🚗', '🚌', '🚇', '✈️',
  '🛍️', '👕', '👟', '💻', '🏥', '💊', '📚', '🎓',
  '🎬', '🎮', '🎵', '⚽', '💡', '🔌', '💧', '🔥',
  '🏠', '🏢', '📦', '🔧', '💼', '📱', '💳', '💰'
];

// Predefined colors for categories
const List<Color> categoryColors = [
  Color(0xFFFF6B6B), // Red
  Color(0xFF4ECDC4), // Teal
  Color(0xFF45B7D1), // Blue
  Color(0xFF96CEB4), // Green
  Color(0xFFFFEEAD), // Yellow
  Color(0xFFD4A5A5), // Pink
  Color(0xFF9B59B6), // Purple
  Color(0xFF3498DB), // Light Blue
  Color(0xFFE67E22), // Orange
  Color(0xFF2ECC71), // Emerald
  Color(0xFFF1C40F), // Sunflower
  Color(0xFFE74C3C), // Alizarin
];