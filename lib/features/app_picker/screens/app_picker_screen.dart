import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:installed_apps/app_info.dart';
import 'package:installed_apps/installed_apps.dart';
import 'package:pflege_lock_app/core/constants/app_constants.dart';
import 'package:pflege_lock_app/core/models/blocked_app.dart';
import 'package:pflege_lock_app/core/services/security_service.dart';
import 'package:pflege_lock_app/core/providers/app_providers.dart';

class AppPickerScreen extends ConsumerStatefulWidget {
  const AppPickerScreen({super.key, this.isOnboarding = false});

  final bool isOnboarding;

  @override
  ConsumerState<AppPickerScreen> createState() => _AppPickerScreenState();
}

class _AppPickerScreenState extends ConsumerState<AppPickerScreen> {
  List<AppInfo> _apps = [];
  final Set<String> _selected = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadApps();
  }

  Future<void> _loadApps() async {
    final apps = await InstalledApps.getInstalledApps(true, false);
    apps.sort((a, b) => a.name.compareTo(b.name));

    final repo = ref.read(settingsRepositoryProvider);
    final blocked = await repo.getAllBlockedApps();
    final selected = blocked.where((a) => a.isActive).map((a) => a.packageName).toSet();

    if (selected.isEmpty) {
      for (final def in AppConstants.defaultBlockedPackages) {
        if (apps.any((a) => a.packageName == def['package'])) {
          selected.add(def['package']!);
        }
      }
    }

    setState(() {
      _apps = apps;
      _selected.addAll(selected);
      _loading = false;
    });
  }

  Future<void> _save() async {
    final repo = ref.read(settingsRepositoryProvider);
    final existing = await repo.getAllBlockedApps();
    final existingPackages = existing.map((a) => a.packageName).toSet();

    for (final app in _apps) {
      if (!SecurityService.isValidPackageName(app.packageName)) continue;
      if (_selected.contains(app.packageName)) {
        await repo.upsertBlockedApp(
          BlockedApp(
            packageName: app.packageName,
            appName: app.name,
            isActive: true,
          ),
        );
      } else if (existingPackages.contains(app.packageName)) {
        await repo.deactivateBlockedApp(app.packageName);
      }
    }

    if (mounted) {
      context.go(widget.isOnboarding ? '/home' : '/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppConstants.surfaceColor,
        title: Text(widget.isOnboarding ? 'Apps auswählen' : 'Gesperrte Apps'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _apps.length,
              itemBuilder: (_, i) {
                final app = _apps[i];
                return CheckboxListTile(
                  title: Text(app.name, style: const TextStyle(color: Colors.white)),
                  subtitle: Text(
                    app.packageName,
                    style: const TextStyle(color: Colors.white38, fontSize: 11),
                  ),
                  value: _selected.contains(app.packageName),
                  activeColor: AppConstants.primaryColor,
                  checkColor: Colors.white,
                  onChanged: (v) {
                    setState(() {
                      if (v == true) {
                        _selected.add(app.packageName);
                      } else {
                        _selected.remove(app.packageName);
                      }
                    });
                  },
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _save,
        backgroundColor: AppConstants.primaryColor,
        label: const Text('Speichern'),
        icon: const Icon(Icons.save),
      ),
    );
  }
}
