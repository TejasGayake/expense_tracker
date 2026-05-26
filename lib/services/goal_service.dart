import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class SavingsGoal {
  final String id;
  final String name;
  final double targetAmount;
  double currentAmount;
  final String icon;

  SavingsGoal({required this.id, required this.name, required this.targetAmount, this.currentAmount = 0, this.icon = '🎯'});

  double get progress => targetAmount > 0 ? (currentAmount / targetAmount).clamp(0, 1) : 0;
  bool get isCompleted => currentAmount >= targetAmount;

  Map<String, dynamic> toMap() => {'id': id, 'name': name, 'targetAmount': targetAmount, 'currentAmount': currentAmount, 'icon': icon};
  factory SavingsGoal.fromMap(Map<String, dynamic> m) => SavingsGoal(
    id: m['id'], name: m['name'], targetAmount: (m['targetAmount'] as num).toDouble(),
    currentAmount: (m['currentAmount'] as num?)?.toDouble() ?? 0, icon: m['icon'] ?? '🎯',
  );
}

class GoalService {
  static final GoalService _instance = GoalService._internal();
  factory GoalService() => _instance;
  GoalService._internal();

  static const String _key = 'savings_goals';

  Future<List<SavingsGoal>> getAll() async {
    final prefs = await SharedPreferences.getInstance();
    final s = prefs.getString(_key);
    if (s == null) return [];
    return (json.decode(s) as List).map((e) => SavingsGoal.fromMap(e)).toList();
  }

  Future<void> save(List<SavingsGoal> goals) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, json.encode(goals.map((g) => g.toMap()).toList()));
  }

  Future<void> add(SavingsGoal g) async { final all = await getAll(); all.add(g); await save(all); }
  Future<void> update(SavingsGoal g) async { final all = await getAll(); final i = all.indexWhere((x) => x.id == g.id); if (i >= 0) { all[i] = g; await save(all); } }
  Future<void> delete(String id) async { final all = await getAll(); all.removeWhere((g) => g.id == id); await save(all); }
  Future<void> addToGoal(String id, double amount) async {
    final all = await getAll(); final i = all.indexWhere((g) => g.id == id);
    if (i >= 0) { all[i].currentAmount += amount; await save(all); }
  }
}
