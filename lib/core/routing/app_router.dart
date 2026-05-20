import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mindfulness/core/routing/go_router_refresh.dart';
import 'package:mindfulness/features/auth/presentation/login_screen.dart';
import 'package:mindfulness/features/auth/presentation/register_screen.dart';
import 'package:mindfulness/features/auth/providers/auth_providers.dart';
import 'package:mindfulness/features/focus_practice/presentation/focus_practice_screen.dart';
import 'package:mindfulness/features/home/presentation/home_screen.dart';
import 'package:mindfulness/features/meditations/presentation/meditation_player_screen.dart';
import 'package:mindfulness/features/meditations/presentation/meditations_screen.dart';
import 'package:mindfulness/features/profile/presentation/profile_screen.dart';
import 'package:mindfulness/widgets/app_shell.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>();

final goRouterRefreshProvider = Provider<GoRouterRefreshStream>((ref) {
  final auth = ref.watch(authServiceProvider);
  final notifier = GoRouterRefreshStream(auth.authStateChanges());
  ref.onDispose(notifier.dispose);
  return notifier;
});

final appRouterProvider = Provider<GoRouter>((ref) {
  final refresh = ref.watch(goRouterRefreshProvider);
  final auth = ref.watch(authServiceProvider);
  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/home',
    refreshListenable: refresh,
    redirect: (context, state) {
      final loggedIn = auth.currentUser != null;
      final path = state.uri.path;
      final onAuth = path == '/login' || path == '/register';
      if (!loggedIn && !onAuth) return '/login';
      if (loggedIn && onAuth) return '/home';
      if (loggedIn) {
        if (path == '/timer' || path == '/breathing') return '/focus';
        if (path == '/progress') return '/profile';
      }
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/meditation/:id',
        builder: (context, state) =>
            MeditationPlayerScreen(meditationId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/account',
        builder: (context, state) => const AccountScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            AppShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/meditations',
                builder: (context, state) => const MeditationsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/focus',
                builder: (context, state) => const FocusPracticeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                builder: (context, state) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});
