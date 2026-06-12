import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pflege_lock_app/core/constants/app_constants.dart';
import 'package:pflege_lock_app/core/providers/app_providers.dart';
import 'package:pflege_lock_app/core/services/overlay_service.dart';
import 'package:pflege_lock_app/core/services/permission_gate.dart';
import 'package:pflege_lock_app/features/dashboard/providers/dashboard_provider.dart';
import 'package:pflege_lock_app/features/dashboard/widgets/blocked_apps_card.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with WidgetsBindingObserver {
  PermissionStatus? _permissions;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadPermissions();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadPermissions();
      ref.read(dashboardProvider.notifier).refresh();
    }
  }

  Future<void> _loadPermissions() async {
    final status = await ref.read(permissionGateProvider).check();
    if (!mounted) return;
    setState(() => _permissions = status);
  }

  Future<void> _toggleService(bool enabled) async {
    if (enabled) {
      final gate = ref.read(permissionGateProvider);
      if (!await gate.canRunMonitor()) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Berechtigungen fehlen. Gehe zu Einstellungen → Berechtigungen.',
            ),
          ),
        );
        context.push('/home/settings');
        return;
      }
    }
    await ref.read(dashboardProvider.notifier).toggleService(enabled);
  }

  Future<void> _testOverlay(BuildContext context) async {
    final gate = ref.read(permissionGateProvider);
    if (!await gate.check().then((s) => s.overlay)) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Overlay-Berechtigung fehlt noch.')),
      );
      context.push('/home/settings');
      return;
    }

    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(
      const SnackBar(
        content: Text('Overlay wird gestartet…'),
        duration: Duration(seconds: 2),
      ),
    );

    final result = await OverlayService.showOverlay('com.instagram.android');
    if (!context.mounted) return;

    switch (result) {
      case OverlayShowResult.shown:
        messenger.showSnackBar(
          const SnackBar(content: Text('Overlay gestartet')),
        );
      case OverlayShowResult.permissionDenied:
        _showOverlayFallbackDialog(
          context,
          'Berechtigung fehlt',
          '„Über anderen Apps einblenden" ist nicht aktiv.\n\n'
          'Gehe zu Einstellungen → Berechtigungen und erlaube den Zugriff.',
        );
      case OverlayShowResult.failed:
      case OverlayShowResult.timedOut:
        _showOverlayFallbackDialog(
          context,
          'Overlay nicht gestartet',
          'Das Overlay konnte nicht geöffnet werden.\n\n'
          'Prüfe die Berechtigung und starte die App neu. '
          'Alternativ: In-App-Vorschau.',
        );
    }
  }

  void _showOverlayFallbackDialog(
    BuildContext context,
    String title,
    String message,
  ) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppConstants.surfaceColor,
        title: Text(title, style: const TextStyle(color: Colors.white)),
        content: Text(message, style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Abbrechen'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.push('/home/lockout-preview');
            },
            child: const Text('Vorschau öffnen'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(dashboardProvider);
    final stats = state.todayStats;
    final accuracy = stats?.accuracy.round() ?? 0;
    final permissions = _permissions;

    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppConstants.surfaceColor,
        title: const Text('PflegeLock'),
        centerTitle: true,
      ),
      body: state.loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () async {
                await ref.read(dashboardProvider.notifier).refresh();
                await _loadPermissions();
              },
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (permissions != null && !permissions.criticalGranted)
                    Card(
                      color: Colors.orange.withValues(alpha: 0.15),
                      child: ListTile(
                        leading: const Icon(Icons.warning_amber, color: Colors.orangeAccent),
                        title: const Text(
                          'Berechtigungen unvollständig',
                          style: TextStyle(color: Colors.white),
                        ),
                        subtitle: Text(
                          permissions.issues.map((i) => i.label).join(', '),
                          style: const TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                        trailing: const Icon(Icons.chevron_right, color: Colors.white54),
                        onTap: () => context.push('/home/settings'),
                      ),
                    ),
                  if (permissions != null && !permissions.criticalGranted)
                    const SizedBox(height: 12),
                  Card(
                    color: AppConstants.surfaceColor,
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                state.serviceRunning &&
                                        state.settings.serviceEnabled &&
                                        (permissions?.criticalGranted ?? false)
                                    ? '🟢 Schutz aktiv'
                                    : '🔴 Schutz deaktiviert',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Switch(
                                value: state.settings.serviceEnabled,
                                activeThumbColor: AppConstants.primaryColor,
                                onChanged: _toggleService,
                              ),
                            ],
                          ),
                          Text(
                            '${state.activeBlockedCount} Apps gesperrt',
                            style: const TextStyle(color: Colors.white54),
                          ),
                          if (state.activeBlockedCount == 0) ...[
                            const SizedBox(height: 8),
                            const Text(
                              '⚠️ Wähle Apps zum Sperren unter „Bearbeiten"',
                              style: TextStyle(color: Colors.orangeAccent, fontSize: 13),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    color: AppConstants.surfaceColor,
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Heute',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _StatItem(
                                label: 'Versuche',
                                value: '${stats?.totalAttempts ?? 0}',
                              ),
                              _StatItem(
                                label: 'Richtig',
                                value: '${stats?.correctCount ?? 0}',
                              ),
                              _StatItem(
                                label: 'Bypass',
                                value: '${stats?.bypassCount ?? 0}',
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            '$accuracy% Genauigkeit heute',
                            style: const TextStyle(color: AppConstants.primaryColor),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  BlockedAppsCard(
                    apps: state.blockedApps,
                    onEdit: () => context.push('/home/apps'),
                  ),
                  if (kDebugMode) ...[
                    const SizedBox(height: 24),
                    OutlinedButton(
                      onPressed: () => _testOverlay(context),
                      child: const Text('🧪 Overlay testen'),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () => context.push('/home/lockout-preview'),
                      child: const Text(
                        'Sperrbildschirm-Vorschau',
                        style: TextStyle(color: Colors.white54, fontSize: 13),
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 12)),
      ],
    );
  }
}
