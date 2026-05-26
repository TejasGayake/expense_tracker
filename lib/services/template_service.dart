import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class TransactionTemplate {
  final String id;
  final String name;
  final double amount;
  final String category;
  final String? categoryId;
  final String paymentMode;

  TransactionTemplate({required this.id, required this.name, required this.amount, required this.category, this.categoryId, this.paymentMode = 'Cash'});

  Map<String, dynamic> toMap() => {'id': id, 'name': name, 'amount': amount, 'category': category, 'categoryId': categoryId, 'paymentMode': paymentMode};
  factory TransactionTemplate.fromMap(Map<String, dynamic> m) => TransactionTemplate(
    id: m['id'], name: m['name'], amount: (m['amount'] as num).toDouble(),
    category: m['category'], categoryId: m['categoryId'], paymentMode: m['paymentMode'] ?? 'Cash',
  );
}

class TemplateService {
  static final TemplateService _instance = TemplateService._internal();
  factory TemplateService() => _instance;
  TemplateService._internal();

  static const String _key = 'transaction_templates';

  Future<List<TransactionTemplate>> getAll() async {
    final prefs = await SharedPreferences.getInstance();
    final s = prefs.getString(_key);
    if (s == null) return [];
    return (json.decode(s) as List).map((e) => TransactionTemplate.fromMap(e)).toList();
  }

  Future<void> save(List<TransactionTemplate> templates) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, json.encode(templates.map((t) => t.toMap()).toList()));
  }

  Future<void> add(TransactionTemplate t) async { final all = await getAll(); all.add(t); await save(all); }
  Future<void> delete(String id) async { final all = await getAll(); all.removeWhere((t) => t.id == id); await save(all); }
}
