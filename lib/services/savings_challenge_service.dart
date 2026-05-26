import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class SavingsChallenge {
  final String id;
  final String name;
  final String type; // '52week', 'noSpend', 'custom'
  final double targetAmount;
  double savedAmount;
  final DateTime startDate;
  int currentWeek;
  List<bool> weeks; // for 52-week challenge

  SavingsChallenge({required this.id, required this.name, required this.type,
    required this.targetAmount, this.savedAmount = 0, required this.startDate,
    this.currentWeek = 0, List<bool>? weeks}) : weeks = weeks ?? List.filled(52, false);

  double get progress => targetAmount > 0 ? (savedAmount / targetAmount).clamp(0, 1) : 0;

  Map<String, dynamic> toMap() => {
    'id': id, 'name': name, 'type': type, 'targetAmount': targetAmount,
    'savedAmount': savedAmount, 'startDate': startDate.toIso8601String(),
    'currentWeek': currentWeek, 'weeks': weeks,
  };

  factory SavingsChallenge.fromMap(Map<String, dynamic> m) => SavingsChallenge(
    id: m['id'], name: m['name'], type: m['type'],
    targetAmount: (m['targetAmount'] as num).toDouble(),
    savedAmount: (m['savedAmount'] as num?)?.toDouble() ?? 0,
    startDate: DateTime.parse(m['startDate']), currentWeek: m['currentWeek'] ?? 0,
    weeks: (m['weeks'] as List?)?.map((e) => e as bool).toList(),
  );
}

class SavingsChallengeService {
  static final SavingsChallengeService _instance = SavingsChallengeService._internal();
  factory SavingsChallengeService() => _instance;
  SavingsChallengeService._internal();

  static const String _key = 'savings_challenges';

  Future<List<SavingsChallenge>> getAll() async {
    final prefs = await SharedPreferences.getInstance();
    final s = prefs.getString(_key);
    if (s == null) return [];
    return (json.decode(s) as List).map((e) => SavingsChallenge.fromMap(e)).toList();
  }

  Future<void> save(List<SavingsChallenge> challenges) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, json.encode(challenges.map((c) => c.toMap()).toList()));
  }

  Future<void> add(SavingsChallenge c) async { final all = await getAll(); all.add(c); await save(all); }
  Future<void> delete(String id) async { final all = await getAll(); all.removeWhere((c) => c.id == id); await save(all); }
  Future<void> update(SavingsChallenge c) async { final all = await getAll(); final i = all.indexWhere((x) => x.id == c.id); if (i >= 0) { all[i] = c; await save(all); } }

  static SavingsChallenge create52WeekChallenge() {
    return SavingsChallenge(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: '52-Week Savings Challenge',
      type: '52week',
      targetAmount: 1378, // sum of 1..52
      startDate: DateTime.now(),
    );
  }
}
