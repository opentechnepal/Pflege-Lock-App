import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pflege_lock_app/core/constants/app_constants.dart';
import 'package:pflege_lock_app/core/database/database_helper.dart';
import 'package:pflege_lock_app/core/services/monitor_service.dart';
import 'package:pflege_lock_app/core/services/permission_gate.dart';
import 'package:pflege_lock_app/core/services/permission_service.dart';
import 'package:pflege_lock_app/router/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('de_DE', null);
  await DatabaseHelper.instance.database;

  final settings = await DatabaseHelper.instance.getSettings();
  await MonitorService.init();
  if (settings.serviceEnabled) {
    final permissionService = PermissionService();
    final gate = PermissionGate(permissionService);
    if (await gate.canRunMonitor()) {
      await MonitorService.start();
    }
  }

  runApp(const ProviderScope(child: PflegeLockApp()));
}

class PflegeLockApp extends ConsumerWidget {
  const PflegeLockApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'PflegeLock',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppConstants.backgroundColor,
        colorScheme: const ColorScheme.dark(
          primary: AppConstants.primaryColor,
          onPrimary: AppConstants.onPrimaryColor,
          surface: AppConstants.surfaceColor,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: AppConstants.surfaceColor,
          foregroundColor: Colors.white,
        ),
      ),
      routerConfig: router,
    );
  }
}
