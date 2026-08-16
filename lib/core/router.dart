import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/models.dart';
import '../providers/auth_providers.dart';
import '../screens/auth_screen.dart';
import '../screens/forgot_password_screen.dart';
import '../screens/history_screen.dart';
import '../screens/home_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/quiz_screen.dart';
import '../screens/review_screen.dart';

/// Rebuilds the router whenever the auth stream emits, so redirect guards
/// react to sign-in / sign-out immediately.
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    _subscription = stream.listen((_) => notifyListeners());
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  final authRepository = ref.watch(authRepositoryProvider);
  final refreshStream = GoRouterRefreshStream(authRepository.onAuthStateChange);
  ref.onDispose(refreshStream.dispose);

  return GoRouter(
    initialLocation: '/',
    refreshListenable: refreshStream,
    redirect: (_, state) {
      final loggedIn = authRepository.currentSession != null;
      final location = state.matchedLocation;
      // Public screens (auth, forgot password) are reachable while signed out.
      final isPublic = location == '/auth' || location == '/forgot-password';

      if (!loggedIn && !isPublic) return '/auth';
      if (loggedIn && location == '/auth') return '/';
      return null;
    },
    routes: [
      GoRoute(path: '/', builder: (_, _) => const HomeScreen()),
      GoRoute(path: '/auth', builder: (_, _) => const AuthScreen()),
      GoRoute(
        path: '/forgot-password',
        builder: (_, _) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/quiz',
        builder: (_, state) => QuizScreen(quiz: state.extra! as Quiz),
      ),
      GoRoute(
        path: '/review',
        builder: (_, state) {
          final args = state.extra! as ReviewArgs;
          return ReviewScreen(quiz: args.quiz, result: args.result);
        },
      ),
      GoRoute(path: '/history', builder: (_, _) => const HistoryScreen()),
      GoRoute(path: '/profile', builder: (_, _) => const ProfileScreen()),
    ],
  );
});