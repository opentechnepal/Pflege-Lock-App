import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pflege_lock_app/core/constants/app_constants.dart';
import 'package:pflege_lock_app/core/models/user_stats.dart';
import 'package:pflege_lock_app/core/providers/app_providers.dart';
import 'package:pflege_lock_app/features/dashboard/widgets/weekly_stats_card.dart';

final weeklyStatsProvider = FutureProvider<List<UserStats>>((ref) {
  return ref.watch(statsRepositoryProvider).getWeeklyStats();
});

class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weeklyAsync = ref.watch(weeklyStatsProvider);
    final todayAsync = ref.watch(statsRepositoryProvider).getTodayStats();

    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppConstants.surfaceColor,
        title: const Text('Statistik'),
      ),
      body: weeklyAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Fehler: $e')),
        data: (weekly) {
          return FutureBuilder<UserStats>(
            future: todayAsync,
            builder: (context, snapshot) {
              final today = snapshot.data;
              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Card(
                    color: AppConstants.surfaceColor,
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Heute im Detail',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          if (today != null) ...[
                            Text(
                              'Genauigkeit: ${today.accuracy.round()}%',
                              style: const TextStyle(color: Colors.white),
                            ),
                            Text(
                              'Schwierigste Kategorie: ${today.hardestCategory.isEmpty ? "—" : today.hardestCategory}',
                              style: const TextStyle(color: Colors.white54),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  WeeklyStatsCard(stats: weekly),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
