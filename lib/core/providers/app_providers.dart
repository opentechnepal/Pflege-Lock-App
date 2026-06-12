import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pflege_lock_app/core/database/database_helper.dart';
import 'package:pflege_lock_app/core/repositories/question_repository.dart';
import 'package:pflege_lock_app/core/repositories/settings_repository.dart';
import 'package:pflege_lock_app/core/repositories/stats_repository.dart';
import 'package:pflege_lock_app/core/services/permission_gate.dart';
import 'package:pflege_lock_app/core/services/permission_service.dart';

final databaseHelperProvider = Provider<DatabaseHelper>((ref) {
  return DatabaseHelper.instance;
});

final questionRepositoryProvider = Provider<QuestionRepository>((ref) {
  return QuestionRepository(ref.watch(databaseHelperProvider));
});

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  return SettingsRepository(ref.watch(databaseHelperProvider));
});

final statsRepositoryProvider = Provider<StatsRepository>((ref) {
  return StatsRepository(ref.watch(databaseHelperProvider));
});

final permissionServiceProvider = Provider<PermissionService>((ref) {
  return PermissionService();
});

final permissionGateProvider = Provider<PermissionGate>((ref) {
  return PermissionGate(ref.watch(permissionServiceProvider));
});

final permissionStatusProvider = FutureProvider<PermissionStatus>((ref) {
  return ref.watch(permissionGateProvider).check();
});
