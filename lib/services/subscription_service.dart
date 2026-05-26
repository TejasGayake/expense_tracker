import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class Subscription {
  final String id;
  final String name;
  final double amount;
  final String frequency; // 'monthly', 'yearly', 'weekly'
  final int renewalDay; // day of month (1-31) or day of week (1-7)
  final String category;

  Subscription({
    required this.id,
    required this.name,
    required this.amount,
    required this.frequency,
    required this.renewalDay,
    this.category = 'Subscriptions',
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'amount': amount,
    'frequency': frequency,
    'renewalDay': renewalDay,
    'category': category,
  };

  factory Subscription.fromMap(Map<String, dynamic> map) => Subscription(
    id: map['id'],
    name: map['name'],
    amount: (map['amount'] as num).toDouble(),
    frequency: map['frequency'],
    renewalDay: map['renewalDay'],
    category: map['category'] ?? 'Subscriptions',
  );

  double get monthlyCost {
    switch (frequency) {
      case 'yearly': return amount / 12;
      case 'weekly': return amount * 4.33;
      default: return amount;
    }
  }
}

class SubscriptionService {
  static final SubscriptionService _instance = SubscriptionService._internal();
  factory SubscriptionService() => _instance;
  SubscriptionService._internal();

  static const String _subscriptionsKey = 'subscriptions';

  Future<List<Subscription>> getAll() async {
    final prefs = await SharedPreferences.getInstance();
    final json_str = prefs.getString(_subscriptionsKey);
    if (json_str == null) return [];
    final List<dynamic> decoded = json.decode(json_str);
    return decoded.map((e) => Subscription.fromMap(e)).toList();
  }

  Future<void> add(Subscription sub) async {
    final subs = await getAll();
    subs.add(sub);
    await _save(subs);
  }

  Future<void> update(Subscription sub) async {
    final subs = await getAll();
    final index = subs.indexWhere((s) => s.id == sub.id);
    if (index >= 0) {
      subs[index] = sub;
      await _save(subs);
    }
  }

  Future<void> delete(String id) async {
    final subs = await getAll();
    subs.removeWhere((s) => s.id == id);
    await _save(subs);
  }

  Future<double> getTotalMonthlyCost() async {
    final subs = await getAll();
    double total = 0;
    for (var sub in subs) {
      total += sub.monthlyCost;
    }
    return total;
  }

  Future<void> _save(List<Subscription> subs) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_subscriptionsKey, json.encode(subs.map((s) => s.toMap()).toList()));
  }
}
