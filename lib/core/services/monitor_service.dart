import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:pflege_lock_app/core/constants/app_constants.dart';
import 'package:pflege_lock_app/core/database/database_helper.dart';
import 'package:pflege_lock_app/core/services/overlay_service.dart';
import 'package:pflege_lock_app/core/services/security_service.dart';

class MonitorService {
  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized) return;
    FlutterForegroundTask.initCommunicationPort();
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: AppConstants.notificationChannelId,
        channelName: AppConstants.notificationChannelName,
        channelDescription: 'Hintergrunddienst für App-Überwachung',
        channelImportance: NotificationChannelImportance.LOW,
        priority: NotificationPriority.LOW,
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: false,
        playSound: false,
      ),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.repeat(
          AppConstants.monitorIntervalSeconds * 1000,
        ),
        autoRunOnBoot: true,
        allowWakeLock: true,
        allowWifiLock: false,
      ),
    );
    _initialized = true;
  }

  static Future<bool> start() async {
    await init();
    if (await FlutterForegroundTask.isRunningService) return true;
    final result = await FlutterForegroundTask.startService(
      notificationTitle: AppConstants.notificationTitle,
      notificationText: AppConstants.notificationBody,
      callback: startCallback,
    );
    return result is ServiceRequestSuccess;
  }

  static Future<bool> stop() async {
    final result = await FlutterForegroundTask.stopService();
    return result is ServiceRequestSuccess;
  }

  static Future<bool> isRunning() {
    return FlutterForegroundTask.isRunningService;
  }
}

@pragma('vm:entry-point')
void startCallback() {
  FlutterForegroundTask.setTaskHandler(MonitorTaskHandler());
}

class MonitorTaskHandler extends TaskHandler {
  static const _channel = MethodChannel('pflege_lock/usage_stats');
  String? _lastOverlayPackage;

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {}

  @override
  void onRepeatEvent(DateTime timestamp) {
    unawaited(_checkForegroundApp());
  }

  @override
  Future<void> onDestroy(DateTime timestamp) async {}

  @override
  void onNotificationButtonPressed(String id) {}

  @override
  void onNotificationPressed() {}

  @override
  void onNotificationDismissed() {}

  Future<void> _checkForegroundApp() async {
    try {
      final hasUsage = await _channel.invokeMethod<bool>('hasUsageStatsPermission');
      if (hasUsage != true) return;

      final rawPackage = await _channel.invokeMethod<String>('getForegroundApp');
      if (SecurityService.shouldIgnoreForegroundPackage(rawPackage)) return;

      final foregroundPackage = SecurityService.sanitizePackageName(rawPackage)!;
      final db = DatabaseHelper.instance;
      final blockedApps = await db.getActiveBlockedApps();
      final settings = await db.getSettings();
      if (!settings.serviceEnabled) return;

      final blocked = blockedApps.where((a) => a.packageName == foregroundPackage);
      if (blocked.isEmpty) {
        _lastOverlayPackage = null;
        return;
      }

      final app = blocked.first;
      if (!app.isLocked) {
        _lastOverlayPackage = null;
        return;
      }

      if (_lastOverlayPackage == foregroundPackage && OverlayService.isShowing) {
        return;
      }

      _lastOverlayPackage = foregroundPackage;
      final result = await OverlayService.showOverlay(foregroundPackage);
      if (result != OverlayShowResult.shown) {
        _lastOverlayPackage = null;
      }
    } catch (_) {
      // Background isolate — errors are non-fatal
    }
  }
}
