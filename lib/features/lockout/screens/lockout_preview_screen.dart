import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pflege_lock_app/core/constants/app_constants.dart';
import 'package:pflege_lock_app/features/lockout/screens/lockout_overlay_screen.dart';

/// In-app preview of the lockout UI for emulator / when system overlay fails.
class LockoutPreviewScreen extends ConsumerWidget {
  const LockoutPreviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppConstants.surfaceColor,
        title: const Text('Sperrbildschirm (Vorschau)'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
      ),
      body: const LockoutOverlayScreen(
        previewPackageName: 'com.instagram.android',
      ),
    );
  }
}
