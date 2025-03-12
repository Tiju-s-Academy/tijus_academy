import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:tijus_academy/screens/home_screen.dart';
import 'package:tijus_academy/screens/login_screen.dart';
import 'package:tijus_academy/services/auth_service.dart';
import 'package:tijus_academy/services/auth_state_provider.dart';

/// The route configuration for the application.
class AppRouter {
  final AuthService authService;
  late final AuthStateProvider authStateProvider;
  late final AuthStateRefreshStream refreshListenable;

  AppRouter({required this.authService}) {
    authStateProvider = AuthStateProvider(authService: authService);
    refreshListenable = AuthStateRefreshStream(authStateProvider);
  }

  /// The route configuration.
  late final router = GoRouter(
    debugLogDiagnostics: true,
    initialLocation: '/login',
    refreshListenable: refreshListenable,
    routes: [
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/',
        name: 'home',
        builder: (context, state) => const HomeScreen(),
      ),
    ],
    redirect: (BuildContext context, GoRouterState state) {
      // Use the auth state from the provider
      final bool isLoggedIn = authStateProvider.isLoggedIn;
      final bool isLoading = authStateProvider.isLoading;
      final bool isGoingToLogin = state.matchedLocation == '/login';

      // If still loading, don't redirect yet
      if (isLoading) {
        return null;
      }

      // If not logged in and not going to login, redirect to login
      if (!isLoggedIn && !isGoingToLogin) {
        return '/login';
      }

      // If logged in and going to login, redirect to home
      if (isLoggedIn && isGoingToLogin) {
        return '/';
      }

      // No redirect needed
      return null;
    },
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Error: ${state.error}'),
      ),
    ),
  );
}

/// A global variable to access the router throughout the app.
/// This should be initialized in main.dart with the AuthService.
GoRouter? appRouter;

/// Global auth state provider to be used throughout the app
AuthStateProvider? authStateProvider;

/// Initialize the app router with the AuthService.
void initializeAppRouter(AuthService authService) {
  final appRouterInstance = AppRouter(authService: authService);
  appRouter = appRouterInstance.router;
  authStateProvider = appRouterInstance.authStateProvider;
}

