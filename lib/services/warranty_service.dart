import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class WarrantyEntry {
  final String id;
  final String productName;
  final String category;
  final DateTime purchaseDate;
  final int warrantyMonths;
  final String? receiptPath;

  WarrantyEntry({required this.id, required this.productName, required this.category,
    required this.purchaseDate, required this.warrantyMonths, this.receiptPath});

  DateTime get expiryDate => DateTime(purchaseDate.year, purchaseDate.month + warrantyMonths, purchaseDate.day);
  bool get isExpired => DateTime.now().isAfter(expiryDate);
  int get daysRemaining => expiryDate.difference(DateTime.now()).inDays;

  Map<String, dynamic> toMap() => {
    'id': id, 'productName': productName, 'category': category,
    'purchaseDate': purchaseDate.toIso8601String(), 'warrantyMonths': warrantyMonths, 'receiptPath': receiptPath,
  };

  factory WarrantyEntry.fromMap(Map<String, dynamic> m) => WarrantyEntry(
    id: m['id'], productName: m['productName'], category: m['category'] ?? 'Other',
    purchaseDate: DateTime.parse(m['purchaseDate']), warrantyMonths: m['warrantyMonths'],
    receiptPath: m['receiptPath'],
  );
}

class WarrantyService {
  static final WarrantyService _instance = WarrantyService._internal();
  factory WarrantyService() => _instance;
  WarrantyService._internal();

  static const String _key = 'warranty_entries';

  Future<List<WarrantyEntry>> getAll() async {
    final prefs = await SharedPreferences.getInstance();
    final s = prefs.getString(_key);
    if (s == null) return [];
    return (json.decode(s) as List).map((e) => WarrantyEntry.fromMap(e)).toList();
  }

  Future<void> save(List<WarrantyEntry> entries) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, json.encode(entries.map((e) => e.toMap()).toList()));
  }

  Future<void> add(WarrantyEntry e) async { final all = await getAll(); all.add(e); await save(all); }
  Future<void> delete(String id) async { final all = await getAll(); all.removeWhere((e) => e.id == id); await save(all); }

  List<WarrantyEntry> getExpiringSoon(List<WarrantyEntry> all, {int days = 30}) {
    return all.where((e) => !e.isExpired && e.daysRemaining <= days).toList()..sort((a, b) => a.daysRemaining.compareTo(b.daysRemaining));
  }
}
