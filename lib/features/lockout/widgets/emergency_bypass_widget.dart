import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pflege_lock_app/features/lockout/providers/lockout_provider.dart';

class EmergencyBypassWidget extends ConsumerWidget {
  const EmergencyBypassWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return TextButton(
      onPressed: () async {
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: const Color(0xFF16213E),
            title: const Text('Notfall-Freigabe', style: TextStyle(color: Colors.white)),
            content: const Text(
              'Bypass verwenden? Wird als Umgehung gezählt.',
              style: TextStyle(color: Colors.white70),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Abbrechen'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Bestätigen'),
              ),
            ],
          ),
        );
        if (confirmed == true) {
          await ref.read(lockoutProvider.notifier).emergencyBypass();
        }
      },
      child: const Text(
        'Notfall-Freigabe',
        style: TextStyle(color: Colors.white54, fontSize: 13),
      ),
    );
  }
}
