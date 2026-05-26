import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class DebtEntry {
  final String id;
  final String personName;
  final double amount;
  final double interestRate;
  final String type; // 'given', 'received'
  final DateTime startDate;
  final DateTime? dueDate;
  final String notes;

  DebtEntry({required this.id, required this.personName, required this.amount, this.interestRate = 0,
    required this.type, required this.startDate, this.dueDate, this.notes = ''});

  double get monthlyInterest => amount * (interestRate / 100) / 12;

  Map<String, dynamic> toMap() => {
    'id': id, 'personName': personName, 'amount': amount, 'interestRate': interestRate,
    'type': type, 'startDate': startDate.toIso8601String(),
    'dueDate': dueDate?.toIso8601String(), 'notes': notes,
  };

  factory DebtEntry.fromMap(Map<String, dynamic> m) => DebtEntry(
    id: m['id'], personName: m['personName'], amount: (m['amount'] as num).toDouble(),
    interestRate: (m['interestRate'] as num?)?.toDouble() ?? 0, type: m['type'],
    startDate: DateTime.parse(m['startDate']),
    dueDate: m['dueDate'] != null ? DateTime.parse(m['dueDate']) : null, notes: m['notes'] ?? '',
  );
}

class DebtService {
  static final DebtService _instance = DebtService._internal();
  factory DebtService() => _instance;
  DebtService._internal();

  static const String _key = 'debt_entries';

  Future<List<DebtEntry>> getAll() async {
    final prefs = await SharedPreferences.getInstance();
    final s = prefs.getString(_key);
    if (s == null) return [];
    return (json.decode(s) as List).map((e) => DebtEntry.fromMap(e)).toList();
  }

  Future<void> save(List<DebtEntry> debts) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, json.encode(debts.map((d) => d.toMap()).toList()));
  }

  Future<void> add(DebtEntry d) async { final all = await getAll(); all.add(d); await save(all); }
  Future<void> delete(String id) async { final all = await getAll(); all.removeWhere((d) => d.id == id); await save(all); }
  Future<void> update(DebtEntry d) async { final all = await getAll(); final i = all.indexWhere((x) => x.id == d.id); if (i >= 0) { all[i] = d; await save(all); } }
}
