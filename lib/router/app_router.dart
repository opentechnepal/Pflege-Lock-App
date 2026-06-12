import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pflege_lock_app/core/constants/app_constants.dart';
import 'package:pflege_lock_app/features/app_picker/screens/app_picker_screen.dart';
import 'package:pflege_lock_app/features/dashboard/screens/home_screen.dart';
import 'package:pflege_lock_app/features/dashboard/screens/settings_screen.dart';
import 'package:pflege_lock_app/features/dashboard/screens/stats_screen.dart';
import 'package:pflege_lock_app/features/onboarding/screens/permission_setup_screen.dart';
import 'package:pflege_lock_app/features/onboarding/screens/welcome_screen.dart';
import 'package:pflege_lock_app/features/lockout/screens/lockout_preview_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/home',
    redirect: (context, state) async {
      final prefs = await SharedPreferences.getInstance();
      final onboardingDone = prefs.getBool(AppConstants.onboardingKey) ?? false;
      final loc = state.matchedLocation;

      if (!onboardingDone && !loc.startsWith('/onboarding')) {
        return '/onboarding';
      }
      if (onboardingDone && loc.startsWith('/onboarding')) {
        return '/home';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/onboarding',
        builder: (_, __) => const WelcomeScreen(),
        routes: [
          GoRoute(
            path: 'permissions',
            builder: (_, __) => const PermissionSetupScreen(),
          ),
          GoRoute(
            path: 'apps',
            builder: (_, __) => const AppPickerScreen(isOnboarding: true),
          ),
        ],
      ),
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) => DashboardShell(child: child),
        routes: [
          GoRoute(
            path: '/home',
            builder: (_, __) => const HomeScreen(),
          ),
          GoRoute(
            path: '/home/stats',
            builder: (_, __) => const StatsScreen(),
          ),
          GoRoute(
            path: '/home/settings',
            builder: (_, __) => const SettingsScreen(),
          ),
          GoRoute(
            path: '/home/apps',
            builder: (_, __) => const AppPickerScreen(),
          ),
          GoRoute(
            path: '/home/lockout-preview',
            builder: (_, __) => const LockoutPreviewScreen(),
          ),
        ],
      ),
    ],
  );
});

class DashboardShell extends StatelessWidget {
  const DashboardShell({super.key, required this.child});

  final Widget child;

  int _indexFromLocation(String location) {
    if (location.startsWith('/home/settings')) return 2;
    if (location.startsWith('/home/stats')) return 1;
    return 0;
  }

  bool _showBottomNav(String location) {
    return !location.startsWith('/home/apps') &&
        !location.startsWith('/home/lockout-preview');
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    final index = _indexFromLocation(location);
    final showNav = _showBottomNav(location);

    return Scaffold(
      body: child,
      bottomNavigationBar: showNav
          ? NavigationBar(
              backgroundColor: AppConstants.surfaceColor,
              indicatorColor: AppConstants.primaryColor,
              selectedIndex: index,
              onDestinationSelected: (i) {
                switch (i) {
                  case 0:
                    context.go('/home');
                  case 1:
                    context.go('/home/stats');
                  case 2:
                    context.go('/home/settings');
                }
              },
              destinations: const [
                NavigationDestination(icon: Icon(Icons.home), label: 'Home'),
                NavigationDestination(
                  icon: Icon(Icons.bar_chart),
                  label: 'Statistik',
                ),
                NavigationDestination(
                  icon: Icon(Icons.settings),
                  label: 'Einstellungen',
                ),
              ],
            )
          : null,
    );
  }
}
