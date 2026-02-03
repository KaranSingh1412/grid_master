import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../widgets/screens/start_screen.dart';
import '../widgets/screens/game_screen.dart';
import '../widgets/screens/shop_screen.dart';
import '../widgets/screens/settings_screen.dart';

/// Route Namen als Konstanten
class AppRoutes {
  static const String home = '/';
  static const String game = '/game';
  static const String shop = '/shop';
  static const String settings = '/settings';
  static const String settingsInGame = '/settings-ingame';
}

/// GoRouter Konfiguration
final GoRouter appRouter = GoRouter(
  initialLocation: AppRoutes.home,
  routes: [
    GoRoute(
      path: AppRoutes.home,
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const StartScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    ),
    GoRoute(
      path: AppRoutes.game,
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const GameScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    ),
    GoRoute(
      path: AppRoutes.shop,
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const ShopScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    ),
    GoRoute(
      path: AppRoutes.settings,
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const SettingsScreen(isFromStartScreen: true),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    ),
    GoRoute(
      path: AppRoutes.settingsInGame,
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const SettingsScreen(isFromStartScreen: false),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    ),
  ],
);
