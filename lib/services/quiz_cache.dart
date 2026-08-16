import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/models.dart';

/// Offline cache for the quiz catalog. Stores the fetched quiz list locally so
/// the home screen still works when the network is unavailable. Kept small
/// (JSON string in shared_preferences); swap for hive when the catalog grows.
class QuizCache {
  static const _key = 'cached_quizzes';

  Future<void> save(List<Quiz> quizzes) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key,
      jsonEncode([for (final q in quizzes) q.toMap()]),
    );
  }

  Future<List<Quiz>?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return null;
    try {
      return (jsonDecode(raw) as List)
          .cast<Map<String, dynamic>>()
          .map(Quiz.fromMap)
          .toList();
    } catch (_) {
      return null;
    }
  }
}