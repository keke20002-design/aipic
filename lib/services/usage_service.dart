import 'package:shared_preferences/shared_preferences.dart';

class UsageService {
  static const _kDateKey = 'usage_date';
  static const _kCountKey = 'usage_count';
  static const int freeLimit = 5;

  static Future<int> getTodayCount() async {
    final prefs = await SharedPreferences.getInstance();
    _resetIfNewDay(prefs);
    return prefs.getInt(_kCountKey) ?? 0;
  }

  // 횟수를 1 증가시키고 증가 후 값을 반환
  static Future<int> increment() async {
    final prefs = await SharedPreferences.getInstance();
    _resetIfNewDay(prefs);
    final count = (prefs.getInt(_kCountKey) ?? 0) + 1;
    await prefs.setInt(_kCountKey, count);
    return count;
  }

  static void _resetIfNewDay(SharedPreferences prefs) {
    final today = DateTime.now().toIso8601String().substring(0, 10);
    if (prefs.getString(_kDateKey) != today) {
      prefs.setString(_kDateKey, today);
      prefs.setInt(_kCountKey, 0);
    }
  }
}
