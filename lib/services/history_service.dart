import 'package:shared_preferences/shared_preferences.dart';
import '../models/calculation_item.dart';

class HistoryService {
  static const String _keyHistory = 'premium_calc_history';
  static const String _keyTheme = 'premium_calc_theme';

  // Singleton pattern
  static final HistoryService instance = HistoryService._internal();
  HistoryService._internal();

  Future<List<CalculationItem>> getHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList(_keyHistory) ?? [];
      return list
          .map((itemStr) => CalculationItem.fromJson(itemStr))
          .toList()
        ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    } catch (_) {
      return [];
    }
  }

  Future<void> addCalculation({
    required String expression,
    required String result,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final current = await getHistory();

      // Avoid consecutive duplicate entries
      if (current.isNotEmpty &&
          current.first.expression == expression &&
          current.first.result == result) {
        return;
      }

      final newItem = CalculationItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        expression: expression,
        result: result,
        timestamp: DateTime.now(),
      );

      final updated = [newItem, ...current];
      // Keep up to 100 recent calculations
      final trimmed = updated.take(100).toList();
      final stringList = trimmed.map((item) => item.toJson()).toList();
      await prefs.setStringList(_keyHistory, stringList);
    } catch (_) {}
  }

  Future<void> clearHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyHistory);
    } catch (_) {}
  }

  Future<void> deleteItem(String id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final current = await getHistory();
      final filtered = current.where((item) => item.id != id).toList();
      final stringList = filtered.map((item) => item.toJson()).toList();
      await prefs.setStringList(_keyHistory, stringList);
    } catch (_) {}
  }

  // Save selected theme
  Future<void> saveThemeIndex(int index) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_keyTheme, index);
    } catch (_) {}
  }

  // Load selected theme
  Future<int> loadThemeIndex() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt(_keyTheme) ?? 0;
    } catch (_) {
      return 0;
    }
  }
}
