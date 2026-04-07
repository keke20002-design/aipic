import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/analysis_result.dart';

class HistoryService {
  static const _key = 'analysis_history';
  static const _maxItems = 20;

  static Future<List<AnalysisResult>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? [];
    final results = <AnalysisResult>[];
    for (final item in raw) {
      try {
        final decoded = jsonDecode(item) as Map<String, dynamic>;
        results.add(AnalysisResult.fromJson(decoded));
      } catch (_) {}
    }
    return results;
  }

  static Future<void> save(AnalysisResult result) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? [];
    raw.insert(0, jsonEncode(result.toJson()));
    if (raw.length > _maxItems) raw.removeLast();
    await prefs.setStringList(_key, raw);
  }

  static Future<void> delete(int index) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? [];
    if (index >= 0 && index < raw.length) {
      raw.removeAt(index);
      await prefs.setStringList(_key, raw);
    }
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
