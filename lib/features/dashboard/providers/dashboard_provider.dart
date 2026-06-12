import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pflege_lock_app/core/models/blocked_app.dart';
import 'package:pflege_lock_app/core/models/user_settings.dart';
import 'package:pflege_lock_app/core/models/user_stats.dart';
import 'package:pflege_lock_app/core/providers/app_providers.dart';
import 'package:pflege_lock_app/core/services/monitor_service.dart';

class DashboardState {
  const DashboardState({
    this.settings = const UserSettings(),
    this.todayStats,
    this.blockedApps = const [],
    this.serviceRunning = false,
    this.loading = true,
  });

  final UserSettings settings;
  final UserStats? todayStats;
  final List<BlockedApp> blockedApps;
  final bool serviceRunning;
  final bool loading;

  int get activeBlockedCount => blockedApps.where((a) => a.isActive).length;

  DashboardState copyWith({
    UserSettings? settings,
    UserStats? todayStats,
    List<BlockedApp>? blockedApps,
    bool? serviceRunning,
    bool? loading,
  }) {
    return DashboardState(
      settings: settings ?? this.settings,
      todayStats: todayStats ?? this.todayStats,
      blockedApps: blockedApps ?? this.blockedApps,
      serviceRunning: serviceRunning ?? this.serviceRunning,
      loading: loading ?? this.loading,
    );
  }
}

class DashboardNotifier extends StateNotifier<DashboardState> {
  DashboardNotifier(this._ref) : super(const DashboardState()) {
    refresh();
  }

  final Ref _ref;

  Future<void> refresh() async {
    state = state.copyWith(loading: true);
    final settings = await _ref.read(settingsRepositoryProvider).getSettings();
    final stats = await _ref.read(statsRepositoryProvider).getTodayStats();
    final apps = await _ref.read(settingsRepositoryProvider).getAllBlockedApps();
    final running = await MonitorService.isRunning();

    state = state.copyWith(
      settings: settings,
      todayStats: stats,
      blockedApps: apps.where((a) => a.isActive).toList(),
      serviceRunning: running,
      loading: false,
    );
  }

  Future<void> toggleService(bool enabled) async {
    if (enabled) {
      final gate = _ref.read(permissionGateProvider);
      if (!await gate.canRunMonitor()) return;
      await MonitorService.start();
    } else {
      await MonitorService.stop();
    }
    final settings = state.settings.copyWith(serviceEnabled: enabled);
    await _ref.read(settingsRepositoryProvider).saveSettings(settings);
    state = state.copyWith(
      settings: settings,
      serviceRunning: enabled,
    );
  }
}

final dashboardProvider = StateNotifierProvider<DashboardNotifier, DashboardState>(
  (ref) => DashboardNotifier(ref),
);
