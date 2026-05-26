import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class InvestmentEntry {
  final String id;
  final String name;
  final String type; // 'sip', 'rd', 'fd', 'mutual_fund', 'other'
  final double amount;
  final double expectedReturn; // percentage
  final DateTime startDate;
  final DateTime? maturityDate;

  InvestmentEntry({required this.id, required this.name, required this.type,
    required this.amount, this.expectedReturn = 0, required this.startDate, this.maturityDate});

  Map<String, dynamic> toMap() => {
    'id': id, 'name': name, 'type': type, 'amount': amount,
    'expectedReturn': expectedReturn, 'startDate': startDate.toIso8601String(),
    'maturityDate': maturityDate?.toIso8601String(),
  };

  factory InvestmentEntry.fromMap(Map<String, dynamic> m) => InvestmentEntry(
    id: m['id'], name: m['name'], type: m['type'],
    amount: (m['amount'] as num).toDouble(),
    expectedReturn: (m['expectedReturn'] as num?)?.toDouble() ?? 0,
    startDate: DateTime.parse(m['startDate']),
    maturityDate: m['maturityDate'] != null ? DateTime.parse(m['maturityDate']) : null,
  );
}

class InvestmentService {
  static final InvestmentService _instance = InvestmentService._internal();
  factory InvestmentService() => _instance;
  InvestmentService._internal();

  static const String _key = 'investments';

  Future<List<InvestmentEntry>> getAll() async {
    final prefs = await SharedPreferences.getInstance();
    final s = prefs.getString(_key);
    if (s == null) return [];
    return (json.decode(s) as List).map((e) => InvestmentEntry.fromMap(e)).toList();
  }

  Future<void> save(List<InvestmentEntry> entries) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, json.encode(entries.map((e) => e.toMap()).toList()));
  }

  Future<void> add(InvestmentEntry e) async { final all = await getAll(); all.add(e); await save(all); }
  Future<void> delete(String id) async { final all = await getAll(); all.removeWhere((e) => e.id == id); await save(all); }
  Future<void> update(InvestmentEntry e) async { final all = await getAll(); final i = all.indexWhere((x) => x.id == e.id); if (i >= 0) { all[i] = e; await save(all); } }

  Future<double> getTotalInvestment() async {
    final all = await getAll();
    double total = 0;
    for (var e in all) { total += e.amount; }
    return total;
  }
}
