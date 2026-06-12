import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:pflege_lock_app/core/services/overlay_service.dart';

class PermissionService {
  static const _channel = MethodChannel('pflege_lock/usage_stats');

  Future<bool> hasOverlayPermission() async {
    return await OverlayService.isPermissionGranted() ||
        await Permission.systemAlertWindow.isGranted;
  }

  Future<bool> requestOverlayPermission() async {
    final status = await Permission.systemAlertWindow.request();
    return status.isGranted;
  }

  Future<bool> hasUsageStatsPermission() async {
    try {
      final result = await _channel.invokeMethod<bool>('hasUsageStatsPermission');
      return result ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<void> openUsageAccessSettings() async {
    await _channel.invokeMethod<void>('openUsageAccessSettings');
  }

  Future<void> openOverlaySettings() async {
    await _channel.invokeMethod<void>('openOverlaySettings');
  }

  Future<void> requestBatteryOptimizationExemption() async {
    await Permission.ignoreBatteryOptimizations.request();
  }

  Future<bool> hasBatteryOptimizationExemption() async {
    return Permission.ignoreBatteryOptimizations.isGranted;
  }
}
