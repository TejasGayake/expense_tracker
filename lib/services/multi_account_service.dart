import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class Account {
  final String id;
  final String name;
  final String type; // 'cash', 'bank', 'credit_card', 'upi'
  double balance;

  Account({required this.id, required this.name, required this.type, this.balance = 0});

  Map<String, dynamic> toMap() => {'id': id, 'name': name, 'type': type, 'balance': balance};
  factory Account.fromMap(Map<String, dynamic> m) => Account(
    id: m['id'], name: m['name'], type: m['type'], balance: (m['balance'] as num?)?.toDouble() ?? 0,
  );
}

class MultiAccountService {
  static final MultiAccountService _instance = MultiAccountService._internal();
  factory MultiAccountService() => _instance;
  MultiAccountService._internal();

  static const String _key = 'accounts';

  Future<List<Account>> getAll() async {
    final prefs = await SharedPreferences.getInstance();
    final s = prefs.getString(_key);
    if (s == null) return [Account(id: 'default', name: 'Cash', type: 'cash')];
    return (json.decode(s) as List).map((e) => Account.fromMap(e)).toList();
  }

  Future<void> save(List<Account> accounts) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, json.encode(accounts.map((a) => a.toMap()).toList()));
  }

  Future<void> add(Account a) async { final all = await getAll(); all.add(a); await save(all); }
  Future<void> update(Account a) async { final all = await getAll(); final i = all.indexWhere((x) => x.id == a.id); if (i >= 0) { all[i] = a; await save(all); } }
  Future<void> delete(String id) async { final all = await getAll(); all.removeWhere((a) => a.id == id); await save(all); }
}
