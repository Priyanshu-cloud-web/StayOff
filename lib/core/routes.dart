import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:focusguard/features/onboarding/screens/onboarding_screen.dart';
import 'package:focusguard/features/auth/screens/register_screen.dart';
import 'package:focusguard/features/pin/screens/pin_unlock_screen.dart';
import 'package:focusguard/features/dashboard/screens/dashboard_screen.dart';
import 'package:focusguard/features/blocklist/screens/blocklist_screen.dart';
import 'package:focusguard/features/appblocker/screens/appblocker_screen.dart';
import 'package:focusguard/features/safeguard/screens/safeguard_screen.dart';
import 'package:focusguard/features/safeguard/screens/safeguard_setup_screen.dart';
import 'package:focusguard/features/lock/screens/lock_screen.dart';
import 'package:focusguard/features/settings/screens/settings_screen.dart';
import 'package:focusguard/shared/widgets/main_shell.dart';
import 'providers/app_state_provider.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final route = ref.watch(appStateProvider);

  String initial;
  switch (route) {
    case AppStartRoute.loading:
    case AppStartRoute.onboarding: initial = '/onboarding'; break;
    case AppStartRoute.register:   initial = '/register';   break;
    case AppStartRoute.pinUnlock:  initial = '/pin-unlock'; break;
    case AppStartRoute.home:       initial = '/dashboard';  break;
  }

  return GoRouter(
    initialLocation: initial,
    routes: [
      GoRoute(path: '/onboarding', builder: (_, __) => const OnboardingScreen()),
      GoRoute(path: '/register',   builder: (_, __) => const RegisterScreen()),
      GoRoute(path: '/pin-unlock', builder: (_, __) => const PinUnlockScreen()),

      ShellRoute(
        builder: (_, __, child) => MainShell(child: child),
        routes: [
          GoRoute(path: '/dashboard',  builder: (_, __) => const DashboardScreen()),
          GoRoute(path: '/blocklist',  builder: (_, __) => const BlocklistScreen()),
          GoRoute(path: '/appblocker', builder: (_, __) => const AppBlockerScreen()),
          GoRoute(path: '/safeguard',  builder: (_, __) => const SafeguardScreen()),
          GoRoute(path: '/lock',       builder: (_, __) => const LockScreen()),
          GoRoute(path: '/settings',   builder: (_, __) => const SettingsScreen()),
        ],
      ),
      GoRoute(path: '/safeguard-setup', builder: (_, __) => const SafeguardSetupScreen()),
    ],
  );
});