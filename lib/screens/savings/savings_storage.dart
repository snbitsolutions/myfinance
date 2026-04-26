import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'savings_model.dart';

class SavingsStorage {
  static const _goalsKey = 'user_created_savings_goals_v1';

  static Future<List<Savings>> loadGoals() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_goalsKey) ?? const [];

    return raw
        .map((entry) {
          try {
            final data = jsonDecode(entry) as Map<String, dynamic>;
            return Savings.fromJson(data);
          } catch (_) {
            return null;
          }
        })
        .whereType<Savings>()
        .toList();
  }

  static Future<void> saveGoals(List<Savings> goals) async {
    final prefs = await SharedPreferences.getInstance();
    final payload = goals.map((goal) => jsonEncode(goal.toJson())).toList();
    await prefs.setStringList(_goalsKey, payload);
  }

  static Future<void> addGoal(Savings goal) async {
    final goals = await loadGoals();
    final exists = goals.any((item) => item.id == goal.id);
    if (!exists) {
      goals.insert(0, goal);
      await saveGoals(goals);
    }
  }
}
