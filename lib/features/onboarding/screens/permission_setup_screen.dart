import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pflege_lock_app/core/constants/app_constants.dart';
import 'package:pflege_lock_app/core/providers/app_providers.dart';
import 'package:pflege_lock_app/core/services/permission_gate.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PermissionSetupScreen extends ConsumerStatefulWidget {
  const PermissionSetupScreen({super.key});

  @override
  ConsumerState<PermissionSetupScreen> createState() =>
      _PermissionSetupScreenState();
}

class _PermissionSetupScreenState extends ConsumerState<PermissionSetupScreen>
    with WidgetsBindingObserver {
  PermissionStatus? _status;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refresh();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refresh();
    }
  }

  Future<void> _refresh() async {
    setState(() => _loading = true);
    final status = await ref.read(permissionGateProvider).check();
    if (!mounted) return;
    setState(() {
      _status = status;
      _loading = false;
    });
  }

  Future<void> _openPermission(PermissionIssue issue) async {
    await ref.read(permissionGateProvider).openSettingsFor(issue);
    await Future<void>.delayed(const Duration(milliseconds: 500));
    await _refresh();
  }

  Future<void> _finishOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.onboardingKey, true);
    if (mounted) context.go('/onboarding/apps');
  }

  @override
  Widget build(BuildContext context) {
    final status = _status;

    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppConstants.surfaceColor,
        title: const Text('Berechtigungen'),
      ),
      body: _loading || status == null
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _refresh,
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  const Text(
                    'PflegeLock braucht diese Berechtigungen, um Apps zu sperren. '
                    'Alle Daten bleiben nur auf deinem Gerät.',
                    style: TextStyle(color: Colors.white70, height: 1.5),
                  ),
                  const SizedBox(height: 24),
                  _PermissionCard(
                    issue: PermissionIssue.overlay,
                    granted: status.overlay,
                    onTap: () => _openPermission(PermissionIssue.overlay),
                  ),
                  const SizedBox(height: 12),
                  _PermissionCard(
                    issue: PermissionIssue.usageStats,
                    granted: status.usageStats,
                    onTap: () => _openPermission(PermissionIssue.usageStats),
                  ),
                  const SizedBox(height: 12),
                  _PermissionCard(
                    issue: PermissionIssue.battery,
                    granted: status.batteryOptimization,
                    required: false,
                    onTap: () => _openPermission(PermissionIssue.battery),
                  ),
                  const SizedBox(height: 24),
                  if (!status.criticalGranted)
                    const Text(
                      '⚠️ Overlay und Nutzungszugriff sind Pflicht. '
                      'Ohne diese funktioniert der Schutz nicht.',
                      style: TextStyle(color: Colors.orangeAccent, fontSize: 13),
                    ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: status.criticalGranted ? _finishOnboarding : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppConstants.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      disabledBackgroundColor: Colors.white24,
                    ),
                    child: const Text('Weiter zur App-Auswahl'),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: _refresh,
                    child: const Text('Status aktualisieren'),
                  ),
                ],
              ),
            ),
    );
  }
}

class _PermissionCard extends StatelessWidget {
  const _PermissionCard({
    required this.issue,
    required this.granted,
    required this.onTap,
    this.required = true,
  });

  final PermissionIssue issue;
  final bool granted;
  final bool required;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppConstants.surfaceColor,
      child: ListTile(
        leading: Icon(
          granted ? Icons.check_circle : Icons.error_outline,
          color: granted ? AppConstants.correctColor : Colors.orangeAccent,
        ),
        title: Text(
          issue.label,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          granted
              ? 'Aktiv'
              : '${issue.description}${required ? '' : ' (empfohlen)'}',
          style: const TextStyle(color: Colors.white54, fontSize: 12),
        ),
        trailing: granted
            ? null
            : TextButton(onPressed: onTap, child: const Text('Erlauben')),
        onTap: granted ? null : onTap,
      ),
    );
  }
}
