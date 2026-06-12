import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pflege_lock_app/core/constants/app_constants.dart';
import 'package:pflege_lock_app/core/models/user_settings.dart';
import 'package:pflege_lock_app/core/providers/app_providers.dart';
import 'package:pflege_lock_app/core/services/monitor_service.dart';

class SettingsNotifier extends StateNotifier<UserSettings> {
  SettingsNotifier(this._ref) : super(const UserSettings()) {
    _load();
  }

  final Ref _ref;

  Future<void> _load() async {
    state = await _ref.read(settingsRepositoryProvider).getSettings();
  }

  Future<void> updateStreak(int value) async {
    state = state.copyWith(streakRequired: value);
    await _save();
  }

  Future<void> updateUnlockDuration(int minutes) async {
    state = state.copyWith(unlockDurationMinutes: minutes);
    await _save();
  }

  Future<void> toggleSound(bool enabled) async {
    state = state.copyWith(soundEnabled: enabled);
    await _save();
  }

  Future<void> toggleService(bool enabled) async {
    state = state.copyWith(serviceEnabled: enabled);
    await _save();
    if (enabled) {
      final gate = _ref.read(permissionGateProvider);
      if (await gate.canRunMonitor()) {
        await MonitorService.start();
      }
    } else {
      await MonitorService.stop();
    }
  }

  Future<void> toggleCategory(String category, bool enabled) async {
    final categories = List<String>.from(state.activeCategories);
    if (enabled && !categories.contains(category)) {
      categories.add(category);
    } else if (!enabled) {
      categories.remove(category);
    }
    if (categories.isEmpty) return;
    state = state.copyWith(activeCategories: categories);
    await _save();
  }

  Future<void> _save() async {
    await _ref.read(settingsRepositoryProvider).saveSettings(state);
  }
}

final settingsProvider = StateNotifierProvider<SettingsNotifier, UserSettings>(
  (ref) => SettingsNotifier(ref),
);

final unlockDurationOptionsProvider = Provider<List<int>>((ref) {
  return [15, 30, 60, 120];
});

final categoryOptionsProvider = Provider<List<String>>((ref) {
  return AppConstants.allCategories;
});
