import 'package:shared_preferences/shared_preferences.dart';

class StreakService {
  static final StreakService _instance = StreakService._internal();
  factory StreakService() => _instance;
  StreakService._internal();

  static const String _currentKey = 'spending_streak_current';
  static const String _bestKey = 'spending_streak_best';
  static const String _lastLogKey = 'spending_streak_last_log';

  Future<int> getCurrentStreak() async {
    final prefs = await SharedPreferences.getInstance();
    final lastLog = prefs.getString(_lastLogKey);
    if (lastLog == null) return 0;
    final lastDate = DateTime.parse(lastLog);
    final now = DateTime.now();
    final diff = DateTime(now.year, now.month, now.day).difference(DateTime(lastDate.year, lastDate.month, lastDate.day)).inDays;
    if (diff > 1) {
      await prefs.setInt(_currentKey, 0);
      return 0;
    }
    return prefs.getInt(_currentKey) ?? 0;
  }

  Future<int> getBestStreak() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_bestKey) ?? 0;
  }

  Future<void> recordLog() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final lastLog = prefs.getString(_lastLogKey);

    if (lastLog != null) {
      final lastDate = DateTime.parse(lastLog);
      final lastDay = DateTime(lastDate.year, lastDate.month, lastDate.day);
      if (lastDay == today) return; // already logged today
      final diff = today.difference(lastDay).inDays;
      if (diff > 1) {
        await prefs.setInt(_currentKey, 1);
      } else {
        final current = (prefs.getInt(_currentKey) ?? 0) + 1;
        await prefs.setInt(_currentKey, current);
        final best = prefs.getInt(_bestKey) ?? 0;
        if (current > best) await prefs.setInt(_bestKey, current);
      }
    } else {
      await prefs.setInt(_currentKey, 1);
    }
    await prefs.setString(_lastLogKey, today.toIso8601String());
  }
}
