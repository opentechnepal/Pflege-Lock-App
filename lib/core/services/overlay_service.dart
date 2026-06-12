import 'dart:async';

import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:permission_handler/permission_handler.dart';

enum OverlayShowResult {
  shown,
  permissionDenied,
  failed,
  timedOut,
}

class OverlayService {
  static bool _isShowing = false;

  static bool get isShowing => _isShowing;

  static Future<bool> isOverlayPermissionGranted() async {
    final overlayWindow = await FlutterOverlayWindow.isPermissionGranted();
    final systemAlert = await Permission.systemAlertWindow.isGranted;
    return overlayWindow || systemAlert;
  }

  static Future<bool> isPermissionGranted() => isOverlayPermissionGranted();

  static Future<bool> requestPermission() async {
    final result = await FlutterOverlayWindow.requestPermission();
    return result ?? false;
  }

  static Future<OverlayShowResult> showOverlay(String blockedPackage) async {
    if (_isShowing) return OverlayShowResult.shown;

    try {
      final granted = await isPermissionGranted();
      if (!granted) {
        await requestPermission();
        if (!await isPermissionGranted()) {
          return OverlayShowResult.permissionDenied;
        }
      }

      await FlutterOverlayWindow.showOverlay(
        enableDrag: false,
        overlayTitle: 'PflegeLock',
        overlayContent: 'Lernschutz aktiv',
        flag: OverlayFlag.defaultFlag,
        alignment: OverlayAlignment.center,
        visibility: NotificationVisibility.visibilityPublic,
        positionGravity: PositionGravity.auto,
        width: WindowSize.matchParent,
        height: WindowSize.matchParent,
      ).timeout(const Duration(seconds: 10));

      await FlutterOverlayWindow.shareData(blockedPackage)
          .timeout(const Duration(seconds: 3));

      _isShowing = true;
      return OverlayShowResult.shown;
    } on Exception catch (e) {
      _isShowing = false;
      if (e is TimeoutException) return OverlayShowResult.timedOut;
      return OverlayShowResult.failed;
    }
  }

  static Future<void> hideOverlay() async {
    if (!_isShowing) return;
    try {
      await FlutterOverlayWindow.closeOverlay().timeout(const Duration(seconds: 3));
    } catch (_) {
      // Ignore close errors on emulator.
    }
    _isShowing = false;
  }

  static Stream<dynamic> overlayListener() {
    return FlutterOverlayWindow.overlayListener;
  }
}
