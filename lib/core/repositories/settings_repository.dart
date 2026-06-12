import 'package:pflege_lock_app/core/database/database_helper.dart';
import 'package:pflege_lock_app/core/models/blocked_app.dart';
import 'package:pflege_lock_app/core/models/user_settings.dart';

class SettingsRepository {
  SettingsRepository(this._db);
  final DatabaseHelper _db;

  Future<UserSettings> getSettings() => _db.getSettings();

  Future<void> saveSettings(UserSettings settings) => _db.saveSettings(settings);

  Future<List<BlockedApp>> getActiveBlockedApps() => _db.getActiveBlockedApps();

  Future<List<BlockedApp>> getAllBlockedApps() => _db.getAllBlockedApps();

  Future<BlockedApp?> getBlockedAppByPackage(String packageName) =>
      _db.getBlockedAppByPackage(packageName);

  Future<void> upsertBlockedApp(BlockedApp app) => _db.upsertBlockedApp(app);

  Future<void> setUnlockedUntil(String packageName, DateTime until) =>
      _db.setUnlockedUntil(packageName, until);

  Future<void> deactivateBlockedApp(String packageName) =>
      _db.deactivateBlockedApp(packageName);
}
