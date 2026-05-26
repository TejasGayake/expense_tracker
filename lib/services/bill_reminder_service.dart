import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class BillReminder {
  final String id;
  final String name;
  final double amount;
  final int dueDay; // 1-31
  final String frequency; // 'monthly', 'yearly'
  bool paid;

  BillReminder({
    required this.id,
    required this.name,
    required this.amount,
    required this.dueDay,
    this.frequency = 'monthly',
    this.paid = false,
  });

  Map<String, dynamic> toMap() => {
    'id': id, 'name': name, 'amount': amount, 'dueDay': dueDay,
    'frequency': frequency, 'paid': paid,
  };

  factory BillReminder.fromMap(Map<String, dynamic> m) => BillReminder(
    id: m['id'], name: m['name'], amount: (m['amount'] as num).toDouble(),
    dueDay: m['dueDay'], frequency: m['frequency'] ?? 'monthly', paid: m['paid'] ?? false,
  );
}

class BillReminderService {
  static final BillReminderService _instance = BillReminderService._internal();
  factory BillReminderService() => _instance;
  BillReminderService._internal();

  static const String _key = 'bill_reminders';

  Future<List<BillReminder>> getAll() async {
    final prefs = await SharedPreferences.getInstance();
    final s = prefs.getString(_key);
    if (s == null) return [];
    return (json.decode(s) as List).map((e) => BillReminder.fromMap(e)).toList();
  }

  Future<void> save(List<BillReminder> reminders) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, json.encode(reminders.map((r) => r.toMap()).toList()));
  }

  Future<void> add(BillReminder r) async { final all = await getAll(); all.add(r); await save(all); }
  Future<void> delete(String id) async { final all = await getAll(); all.removeWhere((r) => r.id == id); await save(all); }
  Future<void> markPaid(String id) async {
    final all = await getAll();
    final idx = all.indexWhere((r) => r.id == id);
    if (idx >= 0) { all[idx].paid = true; await save(all); }
  }

  List<BillReminder> getUpcoming(List<BillReminder> all) {
    final now = DateTime.now();
    return all.where((r) => !r.paid && r.dueDay >= now.day).toList()..sort((a, b) => a.dueDay.compareTo(b.dueDay));
  }

  List<BillReminder> getOverdue(List<BillReminder> all) {
    final now = DateTime.now();
    return all.where((r) => !r.paid && r.dueDay < now.day).toList();
  }
}
