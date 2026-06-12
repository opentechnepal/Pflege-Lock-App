import 'package:pflege_lock_app/core/database/database_helper.dart';
import 'package:pflege_lock_app/core/models/user_stats.dart';

class StatsRepository {
  StatsRepository(this._db);
  final DatabaseHelper _db;

  Future<UserStats> getTodayStats() async {
    final row = await _db.getTodayStats();
    return UserStats(
      date: DateTime.now(),
      totalAttempts: row['total_attempts'] as int? ?? 0,
      correctCount: row['correct_count'] as int? ?? 0,
      bypassCount: row['bypass_count'] as int? ?? 0,
      hardestCategory: row['hardest_category'] as String? ?? '',
    );
  }

  Future<List<UserStats>> getWeeklyStats() async {
    final rows = await _db.getWeeklyStats();
    return rows.map(UserStats.fromMap).toList();
  }

  Future<void> recordAttempt({required bool correct, String? category}) =>
      _db.incrementAttempt(correct: correct, category: category);

  Future<void> recordBypass() => _db.incrementBypass();
}
