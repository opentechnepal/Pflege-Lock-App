import 'package:path/path.dart';
import 'package:pflege_lock_app/core/constants/app_constants.dart';
import 'package:pflege_lock_app/core/database/seed_data.dart';
import 'package:pflege_lock_app/core/models/blocked_app.dart';
import 'package:pflege_lock_app/core/models/question.dart';
import 'package:pflege_lock_app/core/models/user_settings.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  DatabaseHelper._();
  static final DatabaseHelper instance = DatabaseHelper._();

  Database? _db;

  Future<Database> get database async {
    _db ??= await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, AppConstants.dbName);
    final db = await openDatabase(
      path,
      version: AppConstants.dbVersion,
      onCreate: _onCreate,
    );
    await _seedIfNeeded(db);
    return db;
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE questions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        category TEXT NOT NULL,
        difficulty TEXT NOT NULL DEFAULT 'medium',
        prompt_de TEXT NOT NULL,
        correct_answer TEXT NOT NULL,
        wrong_opt_1 TEXT NOT NULL,
        wrong_opt_2 TEXT NOT NULL,
        wrong_opt_3 TEXT NOT NULL,
        explanation TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE blocked_apps (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        package_name TEXT NOT NULL UNIQUE,
        app_name TEXT NOT NULL,
        is_active INTEGER NOT NULL DEFAULT 1,
        unlocked_until TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE user_stats (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL,
        total_attempts INTEGER NOT NULL DEFAULT 0,
        correct_count INTEGER NOT NULL DEFAULT 0,
        bypass_count INTEGER NOT NULL DEFAULT 0,
        hardest_category TEXT NOT NULL DEFAULT ''
      )
    ''');
    await db.execute('''
      CREATE TABLE user_settings (
        id INTEGER PRIMARY KEY DEFAULT 1,
        streak_required INTEGER NOT NULL DEFAULT 3,
        unlock_duration_minutes INTEGER NOT NULL DEFAULT 30,
        service_enabled INTEGER NOT NULL DEFAULT 1,
        sound_enabled INTEGER NOT NULL DEFAULT 1,
        active_categories TEXT NOT NULL DEFAULT 'fachbegriff,berechnung,pflegeplanung,anatomie'
      )
    ''');
    await db.insert('user_settings', const UserSettings().toMap());
  }

  Future<void> _seedIfNeeded(Database db) async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(AppConstants.seededKey) == true) return;

    for (final q in getSeedQuestions()) {
      await db.insert('questions', q.toMap());
    }
    await prefs.setBool(AppConstants.seededKey, true);
  }

  // --- Questions ---

  Future<Question?> getRandomQuestion(List<String> categories) async {
    if (categories.isEmpty) return null;
    final db = await database;
    final placeholders = List.filled(categories.length, '?').join(',');
    final rows = await db.rawQuery(
      'SELECT * FROM questions WHERE category IN ($placeholders) ORDER BY RANDOM() LIMIT 1',
      categories,
    );
    if (rows.isEmpty) return null;
    return Question.fromMap(rows.first);
  }

  // --- Blocked apps ---

  Future<List<BlockedApp>> getActiveBlockedApps() async {
    final db = await database;
    final rows = await db.query(
      'blocked_apps',
      where: 'is_active = ?',
      whereArgs: [1],
    );
    return rows.map(BlockedApp.fromMap).toList();
  }

  Future<List<BlockedApp>> getAllBlockedApps() async {
    final db = await database;
    final rows = await db.query('blocked_apps');
    return rows.map(BlockedApp.fromMap).toList();
  }

  Future<BlockedApp?> getBlockedAppByPackage(String packageName) async {
    final db = await database;
    final rows = await db.query(
      'blocked_apps',
      where: 'package_name = ?',
      whereArgs: [packageName],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return BlockedApp.fromMap(rows.first);
  }

  Future<void> upsertBlockedApp(BlockedApp app) async {
    final db = await database;
    await db.insert(
      'blocked_apps',
      app.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> setUnlockedUntil(String packageName, DateTime until) async {
    final db = await database;
    await db.update(
      'blocked_apps',
      {'unlocked_until': until.toIso8601String()},
      where: 'package_name = ?',
      whereArgs: [packageName],
    );
  }

  Future<void> deactivateBlockedApp(String packageName) async {
    final db = await database;
    await db.update(
      'blocked_apps',
      {'is_active': 0},
      where: 'package_name = ?',
      whereArgs: [packageName],
    );
  }

  // --- Settings ---

  Future<UserSettings> getSettings() async {
    final db = await database;
    final rows = await db.query('user_settings', where: 'id = ?', whereArgs: [1]);
    if (rows.isEmpty) {
      const defaults = UserSettings();
      await db.insert('user_settings', defaults.toMap());
      return defaults;
    }
    return UserSettings.fromMap(rows.first);
  }

  Future<void> saveSettings(UserSettings settings) async {
    final db = await database;
    await db.update(
      'user_settings',
      settings.toMap(),
      where: 'id = ?',
      whereArgs: [1],
    );
  }

  // --- Stats ---

  Future<Map<String, dynamic>> getTodayStats() async {
    final db = await database;
    final today = DateTime.now().toIso8601String().split('T').first;
    final rows = await db.query(
      'user_stats',
      where: 'date = ?',
      whereArgs: [today],
      limit: 1,
    );
    if (rows.isEmpty) {
      return {
        'total_attempts': 0,
        'correct_count': 0,
        'bypass_count': 0,
      };
    }
    return rows.first;
  }

  Future<List<Map<String, dynamic>>> getWeeklyStats() async {
    final db = await database;
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 6));
    final fromDate = weekAgo.toIso8601String().split('T').first;
    return db.query(
      'user_stats',
      where: 'date >= ?',
      whereArgs: [fromDate],
      orderBy: 'date ASC',
    );
  }

  Future<void> incrementAttempt({required bool correct, String? category}) async {
    final db = await database;
    final today = DateTime.now().toIso8601String().split('T').first;
    final rows = await db.query(
      'user_stats',
      where: 'date = ?',
      whereArgs: [today],
      limit: 1,
    );
    if (rows.isEmpty) {
      await db.insert('user_stats', {
        'date': today,
        'total_attempts': 1,
        'correct_count': correct ? 1 : 0,
        'bypass_count': 0,
        'hardest_category': correct ? '' : (category ?? ''),
      });
    } else {
      final row = rows.first;
      await db.update(
        'user_stats',
        {
          'total_attempts': (row['total_attempts'] as int) + 1,
          'correct_count': (row['correct_count'] as int) + (correct ? 1 : 0),
          if (!correct && category != null) 'hardest_category': category,
        },
        where: 'id = ?',
        whereArgs: [row['id']],
      );
    }
  }

  Future<void> incrementBypass() async {
    final db = await database;
    final today = DateTime.now().toIso8601String().split('T').first;
    final rows = await db.query(
      'user_stats',
      where: 'date = ?',
      whereArgs: [today],
      limit: 1,
    );
    if (rows.isEmpty) {
      await db.insert('user_stats', {
        'date': today,
        'total_attempts': 0,
        'correct_count': 0,
        'bypass_count': 1,
        'hardest_category': '',
      });
    } else {
      final row = rows.first;
      await db.update(
        'user_stats',
        {'bypass_count': (row['bypass_count'] as int) + 1},
        where: 'id = ?',
        whereArgs: [row['id']],
      );
    }
  }
}
