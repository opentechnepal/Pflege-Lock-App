import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pflege_lock_app/core/constants/app_constants.dart';
import 'package:pflege_lock_app/core/providers/app_providers.dart';
import 'package:pflege_lock_app/core/services/permission_gate.dart';
import 'package:pflege_lock_app/features/dashboard/providers/settings_provider.dart';
import 'package:pflege_lock_app/features/dashboard/widgets/settings_tile.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen>
    with WidgetsBindingObserver {
  PermissionStatus? _permissions;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refreshPermissions();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshPermissions();
    }
  }

  Future<void> _refreshPermissions() async {
    final status = await ref.read(permissionGateProvider).check();
    if (!mounted) return;
    setState(() => _permissions = status);
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final durations = ref.watch(unlockDurationOptionsProvider);
    final categories = ref.watch(categoryOptionsProvider);
    final permissions = _permissions;

    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppConstants.surfaceColor,
        title: const Text('Einstellungen'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Berechtigungen',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          if (permissions == null)
            const Center(child: CircularProgressIndicator())
          else ...[
            _PermissionRow(
              label: PermissionIssue.overlay.label,
              granted: permissions.overlay,
              onFix: () async {
                await ref.read(permissionGateProvider).openSettingsFor(PermissionIssue.overlay);
                await _refreshPermissions();
              },
            ),
            _PermissionRow(
              label: PermissionIssue.usageStats.label,
              granted: permissions.usageStats,
              onFix: () async {
                await ref.read(permissionGateProvider).openSettingsFor(PermissionIssue.usageStats);
                await _refreshPermissions();
              },
            ),
            _PermissionRow(
              label: PermissionIssue.battery.label,
              granted: permissions.batteryOptimization,
              onFix: () async {
                await ref.read(permissionGateProvider).openSettingsFor(PermissionIssue.battery);
                await _refreshPermissions();
              },
            ),
            if (permissions.criticalGranted)
              const Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: Text(
                  '✓ Alle Pflicht-Berechtigungen aktiv',
                  style: TextStyle(color: AppConstants.correctColor, fontSize: 13),
                ),
              ),
          ],
          const SizedBox(height: 16),
          SettingsTile(
            title: 'Streak für Freigabe',
            subtitle: '${settings.streakRequired} richtige Antworten',
            trailing: SizedBox(
              width: 160,
              child: Slider(
                value: settings.streakRequired.toDouble(),
                min: 1,
                max: 5,
                divisions: 4,
                label: '${settings.streakRequired}',
                activeColor: AppConstants.primaryColor,
                onChanged: (v) =>
                    ref.read(settingsProvider.notifier).updateStreak(v.round()),
              ),
            ),
          ),
          const SizedBox(height: 8),
          SettingsTile(
            title: 'Freigabedauer',
            trailing: DropdownButton<int>(
              value: settings.unlockDurationMinutes,
              dropdownColor: AppConstants.surfaceColor,
              style: const TextStyle(color: Colors.white),
              items: durations
                  .map((d) => DropdownMenuItem(value: d, child: Text('$d min')))
                  .toList(),
              onChanged: (v) {
                if (v != null) {
                  ref.read(settingsProvider.notifier).updateUnlockDuration(v);
                }
              },
            ),
          ),
          const SizedBox(height: 8),
          SettingsTile(
            title: 'Sound bei falscher Antwort',
            trailing: Switch(
              value: settings.soundEnabled,
              activeThumbColor: AppConstants.primaryColor,
              onChanged: (v) => ref.read(settingsProvider.notifier).toggleSound(v),
            ),
          ),
          const SizedBox(height: 8),
          SettingsTile(
            title: 'Schutz aktiv',
            trailing: Switch(
              value: settings.serviceEnabled,
              activeThumbColor: AppConstants.primaryColor,
              onChanged: (v) => ref.read(settingsProvider.notifier).toggleService(v),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Kategorien aktivieren',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          ...categories.map((cat) {
            final label = AppConstants.categoryLabels[cat] ?? cat;
            return CheckboxListTile(
              title: Text(label, style: const TextStyle(color: Colors.white)),
              value: settings.activeCategories.contains(cat),
              activeColor: AppConstants.primaryColor,
              checkColor: Colors.white,
              tileColor: AppConstants.surfaceColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              onChanged: (v) {
                if (v != null) {
                  ref.read(settingsProvider.notifier).toggleCategory(cat, v);
                }
              },
            );
          }),
          const SizedBox(height: 24),
          const Text(
            'Datenschutz: Alle Daten (Fragen, Statistik, Einstellungen) werden '
            'nur lokal auf deinem Gerät gespeichert. Keine Internetverbindung.',
            style: TextStyle(color: Colors.white38, fontSize: 12, height: 1.4),
          ),
        ],
      ),
    );
  }
}

class _PermissionRow extends StatelessWidget {
  const _PermissionRow({
    required this.label,
    required this.granted,
    required this.onFix,
  });

  final String label;
  final bool granted;
  final Future<void> Function() onFix;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: SettingsTile(
        title: label,
        subtitle: granted ? 'Aktiv' : 'Nicht aktiv',
        trailing: granted
            ? const Icon(Icons.check, color: AppConstants.correctColor)
            : TextButton(
                onPressed: onFix,
                child: const Text('Erlauben'),
              ),
      ),
    );
  }
}
