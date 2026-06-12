import 'package:flutter/material.dart';
import 'package:pflege_lock_app/core/constants/app_constants.dart';
import 'package:pflege_lock_app/core/models/blocked_app.dart';

class BlockedAppsCard extends StatelessWidget {
  const BlockedAppsCard({
    super.key,
    required this.apps,
    required this.onEdit,
  });

  final List<BlockedApp> apps;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppConstants.surfaceColor,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Gesperrte Apps',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(onPressed: onEdit, child: const Text('Bearbeiten')),
              ],
            ),
            const SizedBox(height: 8),
            if (apps.isEmpty)
              const Text(
                'Noch keine Apps gesperrt',
                style: TextStyle(color: Colors.white54),
              )
            else
              SizedBox(
                height: 48,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: apps.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (_, i) {
                    return Chip(
                      label: Text(
                        apps[i].appName,
                        style: const TextStyle(fontSize: 12),
                      ),
                      backgroundColor: AppConstants.primaryColor,
                      labelStyle: const TextStyle(color: Colors.white),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
