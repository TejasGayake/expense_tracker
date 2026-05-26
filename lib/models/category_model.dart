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