import 'package:pflege_lock_app/core/services/overlay_service.dart';
import 'package:pflege_lock_app/core/services/permission_service.dart';

class PermissionStatus {
  const PermissionStatus({
    required this.overlay,
    required this.usageStats,
    required this.batteryOptimization,
  });

  final bool overlay;
  final bool usageStats;
  final bool batteryOptimization;

  bool get criticalGranted => overlay && usageStats;

  bool get allGranted => overlay && usageStats && batteryOptimization;

  List<PermissionIssue> get issues {
    final list = <PermissionIssue>[];
    if (!overlay) {
      list.add(PermissionIssue.overlay);
    }
    if (!usageStats) {
      list.add(PermissionIssue.usageStats);
    }
    if (!batteryOptimization) {
      list.add(PermissionIssue.battery);
    }
    return list;
  }
}

enum PermissionIssue {
  overlay,
  usageStats,
  battery,
}

extension PermissionIssueX on PermissionIssue {
  String get label => switch (this) {
        PermissionIssue.overlay => 'Über anderen Apps einblenden',
        PermissionIssue.usageStats => 'Nutzungszugriff',
        PermissionIssue.battery => 'Akku-Optimierung deaktiviert',
      };

  String get description => switch (this) {
        PermissionIssue.overlay =>
          'PflegeLock braucht diese Berechtigung, um den Sperrbildschirm über andere Apps zu legen.',
        PermissionIssue.usageStats =>
          'PflegeLock braucht diese Berechtigung, um zu erkennen, welche App gerade geöffnet ist.',
        PermissionIssue.battery =>
          'Empfohlen, damit der Schutz im Hintergrund zuverlässig läuft.',
      };
}

class PermissionGate {
  PermissionGate(this._permissionService);

  final PermissionService _permissionService;

  Future<PermissionStatus> check() async {
    final overlay = await OverlayService.isPermissionGranted();
    final usage = await _permissionService.hasUsageStatsPermission();
    final battery = await _permissionService.hasBatteryOptimizationExemption();
    return PermissionStatus(
      overlay: overlay,
      usageStats: usage,
      batteryOptimization: battery,
    );
  }

  Future<bool> canRunMonitor() async {
    final status = await check();
    return status.criticalGranted;
  }

  Future<void> openSettingsFor(PermissionIssue issue) async {
    switch (issue) {
      case PermissionIssue.overlay:
        await _permissionService.openOverlaySettings();
      case PermissionIssue.usageStats:
        await _permissionService.openUsageAccessSettings();
      case PermissionIssue.battery:
        await _permissionService.requestBatteryOptimizationExemption();
    }
  }

  Future<void> requestOverlay() async {
    await OverlayService.requestPermission();
    if (!await OverlayService.isPermissionGranted()) {
      await _permissionService.openOverlaySettings();
    }
  }
}
