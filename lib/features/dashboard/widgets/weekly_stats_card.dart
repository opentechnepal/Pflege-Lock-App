import 'package:flutter/material.dart';
import 'package:pflege_lock_app/core/constants/app_constants.dart';
import 'package:pflege_lock_app/core/models/user_stats.dart';
import 'package:intl/intl.dart';

class WeeklyStatsCard extends StatelessWidget {
  const WeeklyStatsCard({super.key, required this.stats});

  final List<UserStats> stats;

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('EEE', 'de_DE');

    return Card(
      color: AppConstants.surfaceColor,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Wochenübersicht',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            if (stats.isEmpty)
              const Text(
                'Noch keine Daten diese Woche',
                style: TextStyle(color: Colors.white54),
              )
            else
              ...stats.map((s) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 40,
                        child: Text(
                          dateFormat.format(s.date),
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ),
                      Expanded(
                        child: LinearProgressIndicator(
                          value: s.totalAttempts == 0
                              ? 0
                              : s.correctCount / s.totalAttempts,
                          backgroundColor: Colors.white12,
                          color: AppConstants.primaryColor,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${s.correctCount}/${s.totalAttempts}',
                        style: const TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}
